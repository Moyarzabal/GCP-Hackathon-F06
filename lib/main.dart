import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/config/firebase_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}