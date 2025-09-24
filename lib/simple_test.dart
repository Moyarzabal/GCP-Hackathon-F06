import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _status = 'Not signed in';
  String? _userEmail;

  Future<void> _handleSignIn() async {
    setState(() {
      _status = 'Signing in...';
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        setState(() {
          _status = 'Signed in successfully!';
          _userEmail = account.email;
        });
      } else {
        setState(() {
          _status = 'Sign in cancelled';
        });
      }
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
      print('Sign in error: $error');
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
      setState(() {
        _status = 'Signed out';
        _userEmail = null;
      });
    } catch (error) {
      setState(() {
        _status = 'Sign out error: $error';
      });
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
                'Status: $_status',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              if (_userEmail != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Email: $_userEmail',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _userEmail == null ? _handleSignIn : null,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _userEmail != null ? _handleSignOut : null,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
