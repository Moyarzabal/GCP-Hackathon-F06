import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class ImagenService {
  static const String _projectId = 'gcp-f06-barcode';
  static const String _location = 'asia-northeast1';
  static const String _apiEndpoint = 'https://asia-northeast1-aiplatform.googleapis.com';

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> generateCharacterImage({
    required String productName,
    required String emotionState,
    required String category,
  }) async {
    try {
      // Get access token (in production, use proper authentication)
      final accessToken = await _getAccessToken();

      // Create prompt based on emotion state
      final prompt = _createPrompt(productName, emotionState, category);

      // Call Vertex AI Imagen API
      final response = await http.post(
        Uri.parse('$_apiEndpoint/v1/projects/$_projectId/locations/$_location/publishers/google/models/imagen-3.0-generate-001:predict'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'instances': [
            {
              'prompt': prompt,
              'parameters': {
                'sampleCount': 1,
                'aspectRatio': '1:1',
                'addWatermark': false,
                'safetyFilterLevel': 'block_none',
                'personGeneration': 'dont_allow',
              }
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          final imageBase64 = data['predictions'][0]['bytesBase64Encoded'];

          // Upload to Firebase Storage
          final imageUrl = await _uploadToStorage(imageBase64, productName, emotionState);
          return imageUrl;
        }
      }

      print('⚠️ Vertex AI API呼び出し失敗: ${response.statusCode}');
      return _getFallbackImage(emotionState);
    } catch (e) {
      print('❌ キャラクター画像生成エラー: $e');
      // 認証エラーの場合はフォールバック画像を返す
      if (e.toString().contains('Authentication') || e.toString().contains('access token')) {
        print('🔑 認証エラーのため、フォールバック画像を使用します');
      }
      return _getFallbackImage(emotionState);
    }
  }

  String _createPrompt(String productName, String emotionState, String category) {
    final basePrompt = 'Cute kawaii Japanese mascot character representing $productName ($category food item), ';

    switch (emotionState) {
      case '😊':
        return basePrompt + 'happy and fresh, bright colors, smiling face, sparkles around, chibi style, simple design';
      case '😐':
        return basePrompt + 'neutral expression, slightly concerned, pastel colors, chibi style, simple design';
      case '😟':
        return basePrompt + 'worried expression, sweat drops, muted colors, looking anxious, chibi style, simple design';
      case '😰':
        return basePrompt + 'very worried and panicking, dark shadows, urgent expression, chibi style, simple design';
      case '💀':
        return basePrompt + 'zombie-like appearance, expired and spooky, dark colors, ghost-like, chibi style, simple design';
      default:
        return basePrompt + 'neutral kawaii expression, chibi style, simple design';
    }
  }

  Future<String> _uploadToStorage(String base64Image, String productName, String emotionState) async {
    try {
      final bytes = base64Decode(base64Image);
      final fileName = '${productName}_${emotionState}_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = _storage.ref().child('character_images/$fileName');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image to storage: $e');
      throw e;
    }
  }

  Future<String> _getAccessToken() async {
    try {
      // Application Default Credentialsを使用してアクセストークンを取得
      // 本番環境では、Google Cloud認証が設定されている必要があります

      // まず、環境変数からサービスアカウントキーを確認
      final serviceAccountKey = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
      if (serviceAccountKey != null) {
        print('🔑 サービスアカウントキーが見つかりました: $serviceAccountKey');
        // 実際の実装では、サービスアカウントキーを使用してトークンを取得
        // ここでは簡易的な実装として、エラーを投げてフォールバックに移行
        throw Exception('Service account authentication not implemented');
      }

      // 開発環境では、gcloud auth application-default login で設定された認証を使用
      // 実際の実装では、Google Auth Libraryを使用してトークンを取得
      print('⚠️ 認証が設定されていません。フォールバック画像を使用します。');
      throw Exception('Authentication not configured');
    } catch (e) {
      print('❌ 認証エラー: $e');
      // 認証に失敗した場合は例外を投げて、呼び出し元でフォールバック処理を実行
      throw Exception('Failed to get access token: $e');
    }
  }

  String _getFallbackImage(String emotionState) {
    // Return default emoji as fallback
    switch (emotionState) {
      case '😊':
        return 'assets/images/happy_food.png';
      case '😐':
        return 'assets/images/neutral_food.png';
      case '😟':
        return 'assets/images/worried_food.png';
      case '😰':
        return 'assets/images/panicking_food.png';
      case '💀':
        return 'assets/images/expired_food.png';
      default:
        return 'assets/images/default_food.png';
    }
  }

  // Cache management for generated images
  static final Map<String, String> _imageCache = {};

  Future<String?> getCachedOrGenerateImage({
    required String productName,
    required String emotionState,
    required String category,
  }) async {
    final cacheKey = '${productName}_$emotionState';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    final imageUrl = await generateCharacterImage(
      productName: productName,
      emotionState: emotionState,
      category: category,
    );

    if (imageUrl != null) {
      _imageCache[cacheKey] = imageUrl;
    }

    return imageUrl;
  }

  void clearCache() {
    _imageCache.clear();
  }
}