import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/errors/global_error_handler.dart';
import 'shared/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handler
  final errorHandler = GlobalErrorHandler.instance;
  errorHandler.initialize();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase with DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set initial breadcrumb
  errorHandler.addBreadcrumb('アプリケーション開始', category: 'lifecycle');
  
  runApp(
    RootErrorBoundary(
      onError: (error, stackTrace) {
        errorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Root level error',
          fatal: true,
        );
      },
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}