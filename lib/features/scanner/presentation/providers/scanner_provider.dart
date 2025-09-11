import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../core/services/open_food_facts_service.dart';
import '../../../../core/services/gemini_service.dart';

/// スキャナーの状態を表すクラス
class ScannerState {
  final bool isScanning;
  final bool isCameraActive;
  final String? lastScannedCode;
  final DateTime? lastScannedTime;
  final bool hasPermission;
  final String? error;
  final Product? scannedProduct;

  const ScannerState({
    this.isScanning = false,
    this.isCameraActive = false,
    this.lastScannedCode,
    this.lastScannedTime,
    this.hasPermission = false,
    this.error,
    this.scannedProduct,
  });

  ScannerState copyWith({
    bool? isScanning,
    bool? isCameraActive,
    String? lastScannedCode,
    DateTime? lastScannedTime,
    bool? hasPermission,
    String? error,
    Product? scannedProduct,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
      lastScannedTime: lastScannedTime ?? this.lastScannedTime,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
      scannedProduct: scannedProduct ?? this.scannedProduct,
    );
  }
}

/// スキャナー状態を管理するStateNotifier
class ScannerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  MobileScannerController? _controller;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final GeminiService _geminiService = GeminiService();

  ScannerNotifier(this._ref) : super(const ScannerState()) {
    try {
      // 初期化処理
      print('ScannerNotifier initialized successfully');
    } catch (e) {
      print('Error in ScannerNotifier constructor: $e');
      // エラー時も状態は初期化済みなので継続
    }
  }

  /// カメラ初期化
  Future<Result<void>> initializeCamera() async {
    try {
      state = state.copyWith(isScanning: true, error: null);
      
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );

      state = state.copyWith(
        isCameraActive: true,
        hasPermission: true,
        isScanning: false,
      );

      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = ScannerException(
        'カメラの初期化に失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );
      
      state = state.copyWith(
        error: exception.message,
        isScanning: false,
        isCameraActive: false,
      );

      return Result.failure(exception);
    }
  }

  /// バーコードスキャン処理
  Future<Result<Product>> onBarcodeScanned(BarcodeCapture capture) async {
    try {
      final barcode = capture.barcodes.first;
      final code = barcode.rawValue;
      
      if (code == null || code.isEmpty) {
        throw const ScannerException('バーコードが読み取れませんでした');
      }

      // 重複スキャンを防ぐ（3秒以内の同じバーコードは無視）
      final now = DateTime.now();
      if (state.lastScannedCode == code && 
          state.lastScannedTime != null && 
          now.difference(state.lastScannedTime!).inSeconds < 3) {
        return Result.failure(const ScannerException('同じバーコードが検出されました'));
      }

      state = state.copyWith(
        lastScannedCode: code,
        lastScannedTime: now,
        isScanning: true,
        error: null,
      );

      // Open Food Facts APIから商品情報を取得
      final productInfo = await _openFoodFactsService.getProductWithFallback(code);
      
      if (productInfo == null) {
        throw const ScannerException('商品情報が見つかりませんでした');
      }

      // 賞味期限を予測（Gemini AI使用）
      final expiryDate = await _predictExpiryDate(
        productInfo['productName'] as String,
        productInfo['category'] as String?,
      );

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        janCode: code,
        name: productInfo['productName'] as String,
        category: productInfo['category'] as String? ?? 'その他',
        scannedAt: DateTime.now(),
        addedDate: DateTime.now(),
        expiryDate: expiryDate,
        manufacturer: productInfo['manufacturer'] as String?,
        imageUrl: productInfo['imageUrl'] as String?,
      );

      // アプリケーション状態に商品を追加
      _ref.read(appStateProvider.notifier).addProduct(product);

      state = state.copyWith(
        scannedProduct: product,
        isScanning: false,
      );

      return Result.success(product);
    } catch (e, stackTrace) {
      final exception = e is ScannerException 
          ? e 
          : ScannerException(
              'バーコードスキャンに失敗しました',
              details: e.toString(),
              stackTrace: stackTrace,
            );

      state = state.copyWith(
        error: exception.message,
        isScanning: false,
      );

      return Result.failure(exception);
    }
  }

  /// 賞味期限を予測する（Gemini AI使用）
  Future<DateTime?> _predictExpiryDate(String productName, String? category) async {
    try {
      // APIキーが設定されていない場合はデフォルト値を返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getDefaultExpiryDate(category);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using default expiry date: $e');
        return _getDefaultExpiryDate(category);
      }

      final prompt = '''
商品名: $productName
カテゴリ: ${category ?? '不明'}

この商品の一般的な賞味期限を日数で教えてください。
冷蔵保存を前提として、以下の形式で回答してください：

{"expiryDays": 数字}

例：
- 牛乳: 7日
- 野菜: 3-5日
- 肉類: 2-3日
- 加工食品: 30-90日
''';

      final response = await _geminiService.generateContent(prompt);
      
      if (response.text != null) {
        // JSONを抽出して解析
        final jsonStr = _extractJson(response.text!);
        if (jsonStr != null) {
          final json = _parseJson(jsonStr);
          if (json is Map && json['expiryDays'] != null) {
            final daysValue = json['expiryDays'];
            int days;
            if (daysValue is int) {
              days = daysValue;
            } else if (daysValue is String) {
              // "3-5"のような文字列の場合は最初の数字を取得
              final match = RegExp(r'(\d+)').firstMatch(daysValue);
              days = match != null ? int.parse(match.group(1)!) : 7;
            } else {
              days = 7; // デフォルト値
            }
            return DateTime.now().add(Duration(days: days));
          }
        }
      }
    } catch (e) {
      print('Error predicting expiry date: $e');
    }
    
    // デフォルト値
    return _getDefaultExpiryDate(category);
  }

  /// カテゴリに基づくデフォルト賞味期限を取得
  DateTime _getDefaultExpiryDate(String? category) {
    switch (category?.toLowerCase()) {
      case '飲料':
        return DateTime.now().add(const Duration(days: 30));
      case '乳製品':
        return DateTime.now().add(const Duration(days: 7));
      case '肉類':
      case '魚類':
        return DateTime.now().add(const Duration(days: 3));
      case '野菜':
      case '果物':
        return DateTime.now().add(const Duration(days: 5));
      case '加工食品':
      case '即席麺':
        return DateTime.now().add(const Duration(days: 60));
      default:
        return DateTime.now().add(const Duration(days: 7));
    }
  }

  String? _extractJson(String text) {
    final jsonStart = text.indexOf('{');
    if (jsonStart == -1) return null;
    
    final jsonEnd = text.lastIndexOf('}');
    if (jsonEnd == -1) return null;
    
    return text.substring(jsonStart, jsonEnd + 1);
  }

  dynamic _parseJson(String jsonStr) {
    try {
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
      return json.decode(jsonStr);
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }

  /// カメラの停止
  void stopCamera() {
    _controller?.dispose();
    _controller = null;
    state = state.copyWith(
      isCameraActive: false,
      isScanning: false,
    );
  }

  /// スキャンの停止
  void stopScanning() {
    state = state.copyWith(
      isScanning: false,
    );
  }

  /// スキャンの開始
  void startScanning() {
    state = state.copyWith(
      isScanning: true,
    );
  }

  /// エラーのクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 最後にスキャンしたコードをクリア
  void clearLastScannedCode() {
    state = state.copyWith(
      lastScannedCode: null,
      lastScannedTime: null,
    );
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  /// カメラコントローラーを取得
  MobileScannerController? get controller => _controller;
}

/// スキャナープロバイダー
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  try {
    return ScannerNotifier(ref);
  } catch (e) {
    print('Error initializing ScannerNotifier: $e');
    // エラー時はデフォルトの状態で初期化
    return ScannerNotifier(ref);
  }
});

/// カメラが有効かどうかのプロバイダー
final isCameraActiveProvider = Provider<bool>((ref) {
  return ref.watch(scannerProvider).isCameraActive;
});

/// スキャン中かどうかのプロバイダー
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(scannerProvider).isScanning;
});