import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A',
    authDomain: 'gcp-f06-barcode.firebaseapp.com',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.firebasestorage.app',
    messagingSenderId: '787989873030',
    appId: '1:787989873030:web:09603db34685565f29ac07',
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: kIsWeb ? webOptions : null,
    );
  }
}