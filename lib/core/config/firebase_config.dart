import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A',
    authDomain: 'gcp-f06-barcode.firebaseapp.com',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.firebasestorage.app',
    messagingSenderId: '787989873030',
    appId: '1:787989873030:web:09603db34685565f29ac07',
  );

  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: 'AIzaSyAQhEjO9xX_MU5Fpy5ii9GoFUcm_kDnDlE',
    appId: '1:787989873030:ios:0f768aa144b5823329ac07',
    messagingSenderId: '787989873030',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.firebasestorage.app',
    iosBundleId: 'com.f06team.fridgemanager',
  );

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A',
    appId: '1:787989873030:android:d9495bc8845cdfa629ac07',
    messagingSenderId: '787989873030',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.firebasestorage.app',
  );

  static Future<void> initialize() async {
    FirebaseOptions? options;
    
    if (kIsWeb) {
      options = webOptions;
    } else if (Platform.isIOS) {
      options = iosOptions;
    } else if (Platform.isAndroid) {
      options = androidOptions;
    }

    await Firebase.initializeApp(options: options);
  }
}