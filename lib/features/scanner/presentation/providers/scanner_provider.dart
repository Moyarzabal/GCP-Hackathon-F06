import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';

/// スキャナーの状態を表すクラス
class ScannerState {
  final bool isScanning;
  final bool isCameraActive;
  final String? lastScannedCode;
  final bool hasPermission;
  final String? error;
  final Product? scannedProduct;

  const ScannerState({
    this.isScanning = false,
    this.isCameraActive = false,
    this.lastScannedCode,
    this.hasPermission = false,
    this.error,
    this.scannedProduct,
  });

  ScannerState copyWith({
    bool? isScanning,
    bool? isCameraActive,
    String? lastScannedCode,
    bool? hasPermission,
    String? error,
    Product? scannedProduct,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
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

  ScannerNotifier(this._ref) : super(const ScannerState());

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

      // 重複スキャンを防ぐ
      if (state.lastScannedCode == code) {
        return Result.failure(const ScannerException('同じバーコードが検出されました'));
      }

      state = state.copyWith(
        lastScannedCode: code,
        isScanning: true,
        error: null,
      );

      // TODO: バーコードからプロダクト情報を取得する実装
      // 現在はダミーデータを返す
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        janCode: code,
        name: 'スキャンされた商品 ($code)',
        category: 'その他',
        scannedAt: DateTime.now(),
        addedDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 7)),
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

  /// カメラの停止
  void stopCamera() {
    _controller?.dispose();
    _controller = null;
    state = state.copyWith(
      isCameraActive: false,
      isScanning: false,
    );
  }

  /// エラーのクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 最後にスキャンしたコードをクリア
  void clearLastScannedCode() {
    state = state.copyWith(lastScannedCode: null);
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
  return ScannerNotifier(ref);
});

/// カメラが有効かどうかのプロバイダー
final isCameraActiveProvider = Provider<bool>((ref) {
  return ref.watch(scannerProvider).isCameraActive;
});

/// スキャン中かどうかのプロバイダー
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(scannerProvider).isScanning;
});