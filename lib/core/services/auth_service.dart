import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AuthService() {
    // プラットフォーム別の設定
    if (!kIsWeb && Platform.isIOS) {
      // iOS用の設定を追加
      // 環境変数からClient IDを取得
      final iosClientId = dotenv.env['GOOGLE_SIGNIN_IOS_CLIENT_ID'];
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // iOS Simulatorでの動作を改善するためにclientIdを指定
        clientId: iosClientId,
      );
    } else if (kIsWeb) {
      // Web用の設定 - clientIdを指定しない（HTMLメタタグから取得）
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    } else {
      // Androidの場合は通常の設定
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserDocument(credential.user);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user?.updateDisplayName(displayName);
      await _createUserDocument(credential.user);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web環境では Firebase Auth の signInWithPopup を直接使用
        print('Web: Using Firebase Auth signInWithPopup for Google Sign-In');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        try {
          final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
          await _createUserDocument(userCredential.user);
          print('Successfully signed in with Google: ${userCredential.user?.email}');
          return userCredential.user;
        } catch (e) {
          print('Error with signInWithPopup: $e');
          // フォールバック: signInWithRedirect を試す
          await _auth.signInWithRedirect(googleProvider);
          return null; // リダイレクト後に処理される
        }
      } else {
        // モバイル環境では従来の GoogleSignIn を使用
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('Google Sign In cancelled by user');
          return null;
        }

        print('Google user signed in: ${googleUser.email}');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (googleAuth.idToken == null) {
          throw 'Failed to get Google ID token';
        }
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Signing in to Firebase with Google credential...');
        final userCredential = await _auth.signInWithCredential(credential);
        await _createUserDocument(userCredential.user);
        print('Successfully signed in: ${userCredential.user?.email}');
        return userCredential.user;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('Google sign in error: $e');
      throw 'Google sign in failed: $e';
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        await userCredential.user?.updateDisplayName(displayName);
      }
      
      await _createUserDocument(userCredential.user);
      return userCredential.user;
    } catch (e) {
      throw 'Apple sign in failed: $e';
    }
  }

  Future<void> _createUserDocument(User? user) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'householdId': null,
        'role': 'member',
      });
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}