import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Test',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  String _status = 'Not signed in';
  
  Future<void> _handleSignIn() async {
    setState(() => _status = 'Signing in...');
    
    try {
      // Step 1: Google Sign In
      print('Step 1: Starting Google Sign In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _status = 'Sign in cancelled');
        return;
      }
      
      print('Step 2: Google user: ${googleUser.email}');
      setState(() => _status = 'Getting auth...');
      
      // Step 2: Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Step 3: Got auth tokens');
      
      // Step 3: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      print('Step 4: Signing in to Firebase...');
      setState(() => _status = 'Signing in to Firebase...');
      
      // Step 4: Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      print('Step 5: Success! User: ${userCredential.user?.email}');
      setState(() => _status = 'Signed in as: ${userCredential.user?.email}');
      
    } catch (e, stack) {
      print('Error during sign in: $e');
      print('Stack trace: $stack');
      setState(() => _status = 'Error: $e');
    }
  }
  
  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      setState(() => _status = 'Signed out');
    } catch (e) {
      print('Sign out error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _handleSignIn,
                child: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}