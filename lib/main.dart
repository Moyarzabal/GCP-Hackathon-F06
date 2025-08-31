import 'test_google_signin.dart' as test;

void main() => test.main();

// Original main (temporarily disabled for testing)
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'firebase_options.dart';
// import 'app.dart';
// import 'core/services/notification_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Load environment variables
//   await dotenv.load(fileName: ".env");
  
//   // Initialize Firebase with DefaultFirebaseOptions
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
  
//   // Initialize notifications
//   await NotificationService().initialize();
  
//   runApp(
//     const ProviderScope(
//       child: MyApp(),
//     ),
//   );
// }