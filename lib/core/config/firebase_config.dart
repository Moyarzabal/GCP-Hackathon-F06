import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyDiPsRVzN_jrj_rVWKz0qJ4xWP5kGNJz5k',
    authDomain: 'gcp-f06-barcode.firebaseapp.com',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.appspot.com',
    messagingSenderId: '762195307431',
    appId: '1:762195307431:web:4e3f2bc4a7f1dc5d9c7f4e',
    measurementId: 'G-8XVQZ0NQNR',
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: kIsWeb ? webOptions : null,
    );
  }
}