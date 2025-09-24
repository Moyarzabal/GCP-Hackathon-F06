import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
// CI/CDテスト: developmentブランチでのdeploy-branch.yml動作確認
import 'firebase_options.dart';
import 'app.dart';
import 'core/errors/global_error_handler.dart';
import 'shared/widgets/error_boundary.dart';

// グローバルなProviderContainerを作成（後で初期化）
late ProviderContainer globalContainer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handler
  final errorHandler = GlobalErrorHandler.instance;
  errorHandler.initialize();

  // Load environment variables (optional for development)
  try {
    print('Attempting to load .env file...');
    await dotenv.load(fileName: ".env");
    print('.env file loaded successfully');
    print('GEMINI_API_KEY found: ${dotenv.env['GEMINI_API_KEY'] != null}');
    print('JANCODE_LOOKUP_API_KEY found: ${dotenv.env['JANCODE_LOOKUP_API_KEY'] != null}');
  } catch (e) {
    // .env file not found, continue without it for development
    print('Warning: .env file not found, using default values');
    print('Error details: $e');
  }

  // Initialize Firebase with DefaultFirebaseOptions
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for development
  }

  // Initialize Japanese locale for date formatting
  try {
    await initializeDateFormatting('ja_JP', null);
    print('Japanese locale initialized successfully');
  } catch (e) {
    print('Japanese locale initialization failed: $e');
    // Continue without Japanese locale
  }

  // Set initial breadcrumb
  errorHandler.addBreadcrumb('アプリケーション開始', category: 'lifecycle');

  // ProviderContainerを作成してglobalContainerに設定
  globalContainer = ProviderContainer();

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
      child: ProviderScope(
        parent: globalContainer,
        child: const MyApp(),
      ),
    ),
  );
}