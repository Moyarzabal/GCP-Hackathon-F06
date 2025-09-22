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
    // 商品名に基づくキャラクター生成（文字表示は防ぐ）
    final categoryTraits = _getCategoryTraits(category);
    final basePrompt = 'Cute kawaii Japanese mascot character representing $productName ($category food item) with $categoryTraits characteristics, ';
    
    // テキスト表示防止の明示的な指示
    final textPreventionDirective = 'NO text, letters, words, or product names visible in the image, focus purely on character design and visual representation, ';

    switch (emotionState) {
      case '😊':
        return basePrompt + textPreventionDirective +
               'happy and fresh, bright vibrant colors, big smiling face, energetic pose, '
               'clear bright atmosphere with no fog, sparkling clean air around character, '
               'chibi style, simple design, wholesome healthy appearance';
      case '😐':
        return basePrompt + textPreventionDirective +
               'neutral expression with slight concern, gentle pastel colors, thoughtful pose, '
               'light misty atmosphere, subtle fog around character, gentle worry in eyes, '
               'chibi style, simple design, slightly cloudy background';
      case '😟':
        return basePrompt + textPreventionDirective +
               'worried anxious expression, muted colors, nervous gestures, sweat drops, '
               'moderate fog surrounding character, cloudy atmosphere, visible concern, '
               'chibi style, simple design, foggy environment';
      case '😰':
        return basePrompt + textPreventionDirective +
               'very worried panicking expression, darker colors, frantic movements, urgent expression, '
               'thick dense fog enveloping character, heavy fog atmosphere, intense worry, '
               'chibi style, simple design, ominous misty surroundings';
      case '💀':
        return basePrompt + textPreventionDirective +
               'zombie-like expired appearance, dark spooky colors, ghost-like transparency, deteriorated look, '
               'extremely thick ominous fog, supernatural fog, eerie mist completely surrounding character, '
               'chibi style, simple design, haunting atmospheric effects';
      default:
        return basePrompt + textPreventionDirective +
               'neutral kawaii expression, gentle colors, light atmosphere, '
               'chibi style, simple design, clear background';
    }
  }

  String _getCategoryTraits(String category) {
    // カテゴリに基づく視覚的特徴マッピング（商品名と組み合わせて使用）
    switch (category.toLowerCase()) {
      case 'dairy':
      case 'milk':
      case 'cheese':
        return 'creamy white appearance, soft rounded features, gentle curves';
      case 'meat':
      case 'beef':
      case 'pork':
      case 'chicken':
        return 'rich reddish-brown coloring, hearty robust features, sturdy build';
      case 'vegetable':
      case 'vegetables':
        return 'fresh green tones, leafy or rounded natural features, organic shapes';
      case 'fruit':
      case 'fruits':
        return 'bright vibrant colors, sweet cheerful features, round appealing form';
      case 'grain':
      case 'bread':
      case 'rice':
        return 'warm golden-brown tones, wholesome sturdy features, comforting appearance';
      case 'seafood':
      case 'fish':
        return 'silvery-blue tones, sleek streamlined features, aquatic essence';
      case 'snack':
      case 'sweets':
        return 'colorful playful appearance, fun cheerful features, delightful charm';
      case 'beverage':
      case 'drink':
        return 'refreshing translucent qualities, flowing smooth features, liquid-like grace';
      default:
        return 'generic food characteristics, balanced proportions, appealing design';
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