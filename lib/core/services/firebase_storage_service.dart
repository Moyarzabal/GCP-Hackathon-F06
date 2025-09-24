import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Firebase Storageを使用した画像アップロードサービス
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _imagesPath = 'product_images';
  static const Uuid _uuid = Uuid();

  /// Base64データをFirebase StorageにアップロードしてURLを取得
  static Future<String?> uploadBase64Image({
    required String base64Data,
    required String productId,
    required String stage,
  }) async {
    try {
      print(
          '📤 Firebase Storageに画像をアップロード開始: productId=$productId, stage=$stage');

      // Base64データをデコード
      final base64String =
          base64Data.split(',').last; // data:image/png;base64, の部分を除去
      final bytes = base64Decode(base64String);

      // ファイル名を生成（安全な文字のみ使用）
      final safeProductId =
          productId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '${safeProductId}_${stage}_${_uuid.v4()}.png';

      // Firebase Storageの参照を作成
      final ref = _storage.ref('$_imagesPath/$fileName');

      print('🔍 アップロードパス: $_imagesPath/$fileName');

      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'productId': productId,
          'stage': stage,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // アップロード実行
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;

      // ダウンロードURLを取得
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Firebase Storageアップロード完了: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storageアップロードエラー: $e');
      print('🔍 エラー詳細: ${e.toString()}');
      return null;
    }
  }

  /// 複数のBase64画像を一括アップロード
  static Future<Map<String, String>> uploadMultipleBase64Images({
    required Map<String, String> base64Images, // stage -> base64Data
    required String productId,
  }) async {
    final Map<String, String> uploadedUrls = {};

    for (final entry in base64Images.entries) {
      final stage = entry.key;
      final base64Data = entry.value;

      final url = await uploadBase64Image(
        base64Data: base64Data,
        productId: productId,
        stage: stage,
      );

      if (url != null) {
        uploadedUrls[stage] = url;
      }
    }

    return uploadedUrls;
  }

  /// 画像を削除
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Firebase Storage画像削除完了: $imageUrl');
    } catch (e) {
      print('❌ Firebase Storage画像削除エラー: $e');
    }
  }

  /// 商品に関連する全ての画像を削除
  static Future<void> deleteProductImages(String productId) async {
    try {
      final ref = _storage.ref().child(_imagesPath);
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        if (item.name.startsWith(productId)) {
          await item.delete();
          print('✅ 商品画像削除完了: ${item.name}');
        }
      }
    } catch (e) {
      print('❌ 商品画像一括削除エラー: $e');
    }
  }
}
