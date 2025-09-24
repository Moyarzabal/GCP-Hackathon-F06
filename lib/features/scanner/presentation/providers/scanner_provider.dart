import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/product.dart';
import '../../../../core/services/jan_code_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../shared/utils/category_location_mapper.dart';

// 共通のカテゴリリスト
const List<String> _defaultCategories = [
  '飲料',
  '食品',
  '調味料',
  '野菜',
  '冷凍食品',
  'その他'
];

/// スキャナーの状態を表すクラス
class ScannerState {
  final bool isScanning;
  final bool isCameraActive;
  final String? lastScannedCode;
  final DateTime? lastScannedTime;
  final bool hasPermission;
  final String? error;
  final Product? scannedProduct;
  final bool isProcessingProduct;

  const ScannerState({
    this.isScanning = false,
    this.isCameraActive = false,
    this.lastScannedCode,
    this.lastScannedTime,
    this.hasPermission = false,
    this.error,
    this.scannedProduct,
    this.isProcessingProduct = false,
  });

  ScannerState copyWith({
    bool? isScanning,
    bool? isCameraActive,
    String? lastScannedCode,
    DateTime? lastScannedTime,
    bool? hasPermission,
    String? error,
    Product? scannedProduct,
    bool? isProcessingProduct,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
      lastScannedTime: lastScannedTime ?? this.lastScannedTime,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
      scannedProduct: scannedProduct ?? this.scannedProduct,
      isProcessingProduct: isProcessingProduct ?? this.isProcessingProduct,
    );
  }
}

/// スキャナー状態を管理するStateNotifier
class ScannerNotifier extends StateNotifier<ScannerState> {
  final Ref _ref;
  MobileScannerController? _controller;
  final JanCodeService _janCodeService = JanCodeService();
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

      print('🔍 バーコード検出: $code');
      print('📊 状態更新: isScanning=false, isProcessingProduct=true');

      state = state.copyWith(
        lastScannedCode: code,
        lastScannedTime: now,
        isScanning: false, // バーコード認識後はスキャンを停止
        isProcessingProduct: true, // 商品情報処理中
        error: null,
      );

      print('✅ 状態更新完了: ${state.isScanning}, ${state.isProcessingProduct}');

      // JAN Code APIから商品情報を取得
      print('🔍 商品情報取得開始...');
      final productInfo = await _janCodeService.getProductWithFallback(code);
      print('📦 商品情報取得完了: ${productInfo != null ? '成功' : '失敗'}');

      if (productInfo == null) {
        throw const ScannerException('商品情報が見つかりませんでした');
      }

      // 統合版Geminiでカテゴリと賞味期限を同時に分析
      print('🤖 Gemini分析開始...');
      final analysis = await _geminiService.analyzeProduct(
        productName: productInfo['productName'] as String,
        manufacturer: productInfo['manufacturer'] as String?,
        brandName: productInfo['manufacturer'] as String?,
        categoryOptions: _defaultCategories,
      );
      print('✅ Gemini分析完了: ${analysis.category}, ${analysis.expiryDays}日');

      // 分析結果から賞味期限を取得
      final expiryDate = analysis.expiryDate;

      // カテゴリに基づいて適切な配置場所を決定
      final location = CategoryLocationMapper.getDefaultLocationForCategory(analysis.category);

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        janCode: code,
        name: productInfo['productName'] as String,
        category: analysis.category,
        scannedAt: DateTime.now(),
        addedDate: DateTime.now(),
        expiryDate: expiryDate,
        manufacturer: productInfo['manufacturer'] as String?,
        imageUrl: productInfo['imageUrl'] as String?,
        location: location,
      );

      print('🎉 商品処理完了: ${product.name}');
      state = state.copyWith(
        scannedProduct: product,
        isScanning: false,
        isProcessingProduct: false,
      );
      print(
          '✅ 最終状態: isScanning=${state.isScanning}, isProcessingProduct=${state.isProcessingProduct}');

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
        isProcessingProduct: false,
      );

      return Result.failure(exception);
    }
  }

  /// 賞味期限を予測する（統合版Gemini使用）
  Future<DateTime?> _predictExpiryDate(
      String productName, String? category) async {
    try {
      // 統合版Geminiで分析
      final analysis = await _geminiService.analyzeProduct(
        productName: productName,
        manufacturer: null,
        brandName: null,
        categoryOptions: _defaultCategories,
      );
      return analysis.expiryDate;
    } catch (e) {
      print('Error predicting expiry date: $e');
      return _getDefaultExpiryDate(category);
    }
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

  void resetProcessingState() {
    state = state.copyWith(
      isScanning: false,
      isProcessingProduct: false,
      scannedProduct: null,
    );
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
final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
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
