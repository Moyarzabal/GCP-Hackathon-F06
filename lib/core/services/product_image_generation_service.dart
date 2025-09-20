import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/models/product.dart';

/// 商品追加専用の画像生成サービス
class ProductImageGenerationService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _modelId = 'gemini-2.5-flash-image-preview';
  static const String _generateContentApi = 'streamGenerateContent';

  /// 商品用の複数段階キャラクター画像を一括生成（背景透過）
  static Future<Map<ImageStage, String>?> generateMultiStageProductIcons({
    required String productName,
    required String category,
    String? productId, // 商品更新用のID
    WidgetRef? ref, // refを渡す場合
  }) async {
    try {
      print('🎨 複数段階キャラクター画像生成開始: $productName');

      final Map<ImageStage, String> imageUrls = {};

      // 各段階の画像を順次生成
      for (final stage in ImageStage.values) {
        print('🖼️ ${stage.name}段階の画像生成中...');

        final imageUrl = await _generateSingleStageImage(
          productName: productName,
          category: category,
          stage: stage,
        );

        if (imageUrl != null) {
          imageUrls[stage] = imageUrl;
          print('✅ ${stage.name}段階の画像生成完了');
        } else {
          print('⚠️ ${stage.name}段階の画像生成失敗');
        }
      }

      if (imageUrls.isNotEmpty) {
        print('🎉 複数段階画像生成完了: ${imageUrls.length}個の画像');

        // 商品IDが提供されている場合、商品を更新
        if (productId != null) {
          _updateProductWithMultiStageImages(productId, imageUrls, ref);
        }

        return imageUrls;
      } else {
        print('❌ 全ての段階で画像生成に失敗');
        return null;
      }
    } catch (e) {
      print('❌ 複数段階画像生成エラー: $e');
      return null;
    }
  }

  /// 単一段階の画像を生成
  static Future<String?> _generateSingleStageImage({
    required String productName,
    required String category,
    required ImageStage stage,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ GEMINI_API_KEY not found');
        return null;
      }

      // 段階に応じたスタイル設定
      String stylePrompt = _getStageStylePrompt(stage);
      String emotionPrompt = _getStageEmotionPrompt(stage);

      // キャラクタープロンプトを構築
      final prompt = '''
Create a cute, kawaii-style character representing "$productName" (category: $category) for a mobile app. The character should be designed to live in a refrigerator.

Character design requirements:
- Cute, kawaii anime/manga style character
- The character should embody the essence of "$productName"
- Give the character a friendly, approachable personality
- Character should have expressive eyes and a cute face
- Soft, pastel colors with gentle gradients
- Rounded, friendly design
- Size: 512x512 pixels, square format
- High quality, detailed illustration

Character personality and mood:
$emotionPrompt

Visual elements:
- The character should be clearly recognizable as representing "$productName"
- Add small decorative elements like sparkles, hearts, or cute expressions
- Use soft shadows and highlights for depth
- Character should be designed to fit in a refrigerator setting
- Make the character look like it belongs in a cold environment

$stylePrompt

Background requirements:
- TRANSPARENT BACKGROUND (PNG format)
- No background elements, just the character
- Character should be centered and well-composed
- Make it look like a professional character design for a food management app

The character should look like it's living happily in a refrigerator, representing the food item with personality and charm.
''';

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['IMAGE', 'TEXT'],
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_modelId:$_generateContentApi?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return await _parseImageFromResponse(response.body, productName, category, stage);
      } else {
        print('❌ Gemini API error for ${stage.name}: ${response.statusCode} - ${response.body}');
        return _getCharacterFallbackImageUrl(productName, category);
      }
    } catch (e) {
      print('❌ Error generating ${stage.name} image: $e');
      return _getCharacterFallbackImageUrl(productName, category);
    }
  }

  /// 商品用のキャラクター画像を生成（背景透過）- 後方互換性のため残す
  static Future<String?> generateProductIcon({
    required String productName,
    required int daysUntilExpiry,
    required String category,
    String? productId, // 商品更新用のID
    WidgetRef? ref, // refを渡す場合
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ GEMINI_API_KEY not found');
        return null;
      }

      // 賞味期限からImageStageを計算
      ImageStage stage;
      if (daysUntilExpiry > 7) {
        stage = ImageStage.veryFresh;
      } else if (daysUntilExpiry > 3) {
        stage = ImageStage.fresh;
      } else if (daysUntilExpiry > 1) {
        stage = ImageStage.warning;
      } else if (daysUntilExpiry >= 1) {
        stage = ImageStage.urgent;
      } else {
        stage = ImageStage.expired;
      }

      // 賞味期限の状態に基づくスタイル設定
      String stylePrompt = _getStylePrompt(daysUntilExpiry);
      String emotionPrompt = _getEmotionPrompt(daysUntilExpiry);

      // キャラクタープロンプトを構築
      final prompt = '''
Create a cute, kawaii-style character representing "$productName" (category: $category) for a mobile app. The character should be designed to live in a refrigerator.

Character design requirements:
- Cute, kawaii anime/manga style character
- The character should embody the essence of "$productName"
- Give the character a friendly, approachable personality
- Character should have expressive eyes and a cute face
- Soft, pastel colors with gentle gradients
- Rounded, friendly design
- Size: 512x512 pixels, square format
- High quality, detailed illustration

Character personality and mood:
$emotionPrompt

Visual elements:
- The character should be clearly recognizable as representing "$productName"
- Add small decorative elements like sparkles, hearts, or cute expressions
- Use soft shadows and highlights for depth
- Character should be designed to fit in a refrigerator setting
- Make the character look like it belongs in a cold environment

$stylePrompt

Background requirements:
- TRANSPARENT BACKGROUND (PNG format)
- No background elements, just the character
- Character should be centered and well-composed
- Make it look like a professional character design for a food management app

The character should look like it's living happily in a refrigerator, representing the food item with personality and charm.
''';

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt
              }
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['IMAGE', 'TEXT'],
        }
      };

      print('🚀 Gemini API呼び出し開始...');
      print('📝 プロンプト: ${prompt.substring(0, 100)}...');

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_modelId:$_generateContentApi?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Gemini API応答: ${response.statusCode}');
      print('📄 応答ボディ: ${response.body}');

      if (response.statusCode == 200) {
        // ストリーミング応答の場合は、複数のJSONオブジェクトが配列形式で返される
        final responseBody = response.body.trim();
        print('📄 生の応答ボディ: $responseBody');

        try {
          // 配列形式のJSONを解析
          final data = jsonDecode(responseBody);
          print('📊 応答データ構造: ${data.runtimeType}');

          if (data is List) {
            print('📦 配列の長さ: ${data.length}');

            // 各チャンクから画像データを探す
            for (int i = 0; i < data.length; i++) {
              final chunk = data[i];
              print('📄 チャンク $i: ${chunk.keys}');

              if (chunk['candidates'] != null &&
                  chunk['candidates'] is List &&
                  chunk['candidates'].isNotEmpty) {

                final candidates = chunk['candidates'] as List;
                for (int j = 0; j < candidates.length; j++) {
                  final candidate = candidates[j];
                  print('📄 候補 $j: ${candidate.keys}');

                  if (candidate['content'] != null &&
                      candidate['content']['parts'] != null) {

                    final parts = candidate['content']['parts'] as List;
                    print('📦 パーツ数: ${parts.length}');

                    for (int k = 0; k < parts.length; k++) {
                      final part = parts[k];
                      print('📄 パーツ $k: ${part.keys}');

                      // 画像データを探す
                      if (part['inlineData'] != null) {
                        final inlineData = part['inlineData'];
                        if (inlineData['mimeType'] != null && inlineData['data'] != null) {
                          print('🖼️ 画像データ発見: ${inlineData['mimeType']}');

                          // Base64データをFirebase Storageにアップロード
                          final base64Data = inlineData['data'] as String;
                          final mimeType = inlineData['mimeType'] as String;

                          // Firebase StorageにアップロードしてURLを取得
                          final imageUrl = await _uploadBase64ToFirebaseStorage(
                            base64Data,
                            mimeType,
                            productName,
                            stage
                          );

                          if (imageUrl != null) {
                            print('✅ Firebase Storageアップロード完了: $imageUrl');
                            return imageUrl;
                          } else {
                            print('❌ Firebase Storageアップロード失敗');
                            return null;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          } else if (data is Map<String, dynamic>) {
            // 単一のJSONオブジェクトの場合
            print('📦 単一オブジェクト形式');

            if (data['candidates'] != null &&
                data['candidates'] is List &&
                data['candidates'].isNotEmpty) {

              final candidates = data['candidates'] as List;
              for (int j = 0; j < candidates.length; j++) {
                final candidate = candidates[j];
                print('📄 候補 $j: ${candidate.keys}');

                if (candidate['content'] != null &&
                    candidate['content']['parts'] != null) {

                  final parts = candidate['content']['parts'] as List;
                  print('📦 パーツ数: ${parts.length}');

                  for (int k = 0; k < parts.length; k++) {
                    final part = parts[k];
                    print('📄 パーツ $k: ${part.keys}');

                    // 画像データを探す
                    if (part['inlineData'] != null) {
                      final inlineData = part['inlineData'];
                      if (inlineData['mimeType'] != null && inlineData['data'] != null) {
                        print('🖼️ 画像データ発見: ${inlineData['mimeType']}');

                        // Base64データをFirebase Storageにアップロード
                        final base64Data = inlineData['data'] as String;
                        final mimeType = inlineData['mimeType'] as String;

                        // Firebase StorageにアップロードしてURLを取得
                        final imageUrl = await _uploadBase64ToFirebaseStorage(
                          base64Data,
                          mimeType,
                          productName,
                          stage
                        );

                        if (imageUrl != null) {
                          // 商品IDが提供されている場合、商品を更新
                          if (productId != null) {
                            if (ref != null) {
                              _updateProductWithImageRef(ref, productId, imageUrl);
                            } else {
                              _updateProductWithImage(productId, imageUrl);
                            }
                          }

                          return imageUrl;
                        } else {
                          print('❌ Firebase Storageアップロード失敗');
                          return _getCharacterFallbackImageUrl(productName, category);
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          print('❌ 画像データが見つかりませんでした');
          return _getCharacterFallbackImageUrl(productName, category);
        } catch (e) {
          print('❌ JSON解析エラー: $e');
          return _getCharacterFallbackImageUrl(productName, category);
        }
      } else {
        print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
        return _getCharacterFallbackImageUrl(productName, category);
      }
    } catch (e) {
      print('❌ Error generating product icon: $e');
      return _getCharacterFallbackImageUrl(productName, category);
    }
  }

  /// レスポンスから画像を解析
  static Future<String?> _parseImageFromResponse(String responseBody, String productName, String category, ImageStage stage) async {
    try {
      final data = jsonDecode(responseBody);

      if (data is List) {
        // 配列形式のJSONを解析
        for (final chunk in data) {
          if (chunk['candidates'] != null &&
              chunk['candidates'] is List &&
              chunk['candidates'].isNotEmpty) {

            final candidates = chunk['candidates'] as List;
            for (final candidate in candidates) {
              if (candidate['content'] != null &&
                  candidate['content']['parts'] != null) {

                final parts = candidate['content']['parts'] as List;
                for (final part in parts) {
                  if (part['inlineData'] != null) {
                    final inlineData = part['inlineData'];
                    if (inlineData['mimeType'] != null && inlineData['data'] != null) {
                      print('🖼️ 画像データ発見: ${inlineData['mimeType']}');

                      // Base64データをFirebase Storageにアップロード
                      final base64Data = inlineData['data'] as String;
                      final mimeType = inlineData['mimeType'] as String;

                      // Firebase StorageにアップロードしてURLを取得
                      final imageUrl = await _uploadBase64ToFirebaseStorage(
                        base64Data,
                        mimeType,
                        productName,
                        stage
                      );

                      if (imageUrl != null) {
                        print('✅ Firebase Storageアップロード完了: $imageUrl');
                        return imageUrl;
                      } else {
                        print('❌ Firebase Storageアップロード失敗');
                        return null;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } else if (data is Map<String, dynamic>) {
        // 単一のJSONオブジェクトの場合
        if (data['candidates'] != null &&
            data['candidates'] is List &&
            data['candidates'].isNotEmpty) {

          final candidates = data['candidates'] as List;
          for (final candidate in candidates) {
            if (candidate['content'] != null &&
                candidate['content']['parts'] != null) {

              final parts = candidate['content']['parts'] as List;
              for (final part in parts) {
                if (part['inlineData'] != null) {
                  final inlineData = part['inlineData'];
                  if (inlineData['mimeType'] != null && inlineData['data'] != null) {
                    print('🖼️ 画像データ発見: ${inlineData['mimeType']}');

                    // Base64データをFirebase Storageにアップロード
                    final base64Data = inlineData['data'] as String;
                    final mimeType = inlineData['mimeType'] as String;

                    // Firebase StorageにアップロードしてURLを取得
                    final imageUrl = await _uploadBase64ToFirebaseStorage(
                      base64Data,
                      mimeType,
                      productName,
                      stage
                    );

                    if (imageUrl != null) {
                      print('✅ Firebase Storageアップロード完了: $imageUrl');
                      return imageUrl;
                    } else {
                      print('❌ Firebase Storageアップロード失敗');
                      return null;
                    }
                  }
                }
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ JSON解析エラー: $e');
      return null;
    }
  }

  /// 段階に応じたスタイルプロンプトを取得
  static String _getStageStylePrompt(ImageStage stage) {
    switch (stage) {
      case ImageStage.veryFresh:
        return '''
Style: Very fresh and energetic
- Bright, vibrant colors (bright greens, yellows, blues)
- Sparkling effects and shine
- Happy, excited expression
- Fresh, crisp appearance
- Energetic pose with arms raised or jumping
- Bright lighting with highlights
''';
      case ImageStage.fresh:
        return '''
Style: Fresh and healthy
- Clean, bright colors (light greens, whites, soft blues)
- Clean, polished appearance
- Confident, happy expression
- Healthy, well-maintained look
- Relaxed, comfortable pose
- Good lighting with soft shadows
''';
      case ImageStage.warning:
        return '''
Style: Warning state
- Muted, pastel colors (soft yellows, oranges, light browns)
- Slightly concerned expression
- Cautious, alert appearance
- Worried but not panicked
- Defensive or cautious pose
- Dimmer lighting with some shadows
''';
      case ImageStage.urgent:
        return '''
Style: Urgent state
- Darker, more intense colors (deep oranges, reds, dark yellows)
- Worried, anxious expression
- Stressed, urgent appearance
- Panicked or very concerned
- Frantic or defensive pose
- Dramatic lighting with strong shadows
''';
      case ImageStage.expired:
        return '''
Style: Expired state
- Dark, muted colors (grays, browns, dark purples)
- Sad, defeated expression
- Wilted, tired appearance
- Exhausted, lifeless
- Slumped or collapsed pose
- Very dim lighting with heavy shadows
''';
    }
  }

  /// 段階に応じた感情プロンプトを取得
  static String _getStageEmotionPrompt(ImageStage stage) {
    switch (stage) {
      case ImageStage.veryFresh:
        return '''
Emotion: Very excited and energetic
- Big, bright smile
- Sparkling, enthusiastic eyes
- Bouncing or jumping pose
- Arms raised in celebration
- Very happy and proud
''';
      case ImageStage.fresh:
        return '''
Emotion: Happy and confident
- Warm, friendly smile
- Bright, cheerful eyes
- Relaxed, comfortable pose
- Arms at sides or one hand on hip
- Content and satisfied
''';
      case ImageStage.warning:
        return '''
Emotion: Slightly concerned
- Small, worried smile
- Alert, watchful eyes
- Cautious, defensive pose
- One hand raised in caution
- Concerned but not panicked
''';
      case ImageStage.urgent:
        return '''
Emotion: Worried and anxious
- Frown or worried expression
- Wide, anxious eyes
- Frantic, defensive pose
- Both hands raised in alarm
- Very stressed and worried
''';
      case ImageStage.expired:
        return '''
Emotion: Sad and defeated
- Downcast expression
- Tired, droopy eyes
- Slumped, exhausted pose
- Arms hanging limply
- Very sad and defeated
''';
    }
  }

  /// 賞味期限に基づくスタイルプロンプトを取得
  static String _getStylePrompt(int daysUntilExpiry) {
    if (daysUntilExpiry > 7) {
      return '''
Style: Very fresh and energetic
- Bright, vibrant colors (bright greens, yellows, blues)
- Sparkling effects and shine
- Happy, excited expression
- Fresh, crisp appearance
- Energetic pose with arms raised or jumping
- Bright lighting with highlights
''';
    } else if (daysUntilExpiry > 3) {
      return '''
Style: Fresh and healthy
- Clean, bright colors (light greens, whites, soft blues)
- Clean, polished appearance
- Confident, happy expression
- Healthy, well-maintained look
- Relaxed, comfortable pose
- Good lighting with soft shadows
''';
    } else if (daysUntilExpiry > 1) {
      return '''
Style: Warning state
- Muted, pastel colors (soft yellows, oranges, light browns)
- Slightly concerned expression
- Cautious, alert appearance
- Worried but not panicked
- Defensive or cautious pose
- Dimmer lighting with some shadows
''';
    } else if (daysUntilExpiry >= 0) {
      return '''
Style: Urgent state
- Darker, more intense colors (deep oranges, reds, dark yellows)
- Worried, anxious expression
- Stressed, urgent appearance
- Panicked or very concerned
- Frantic or defensive pose
- Dramatic lighting with strong shadows
''';
    } else {
      return '''
Style: Expired state
- Dark, muted colors (grays, browns, dark purples)
- Sad, defeated expression
- Wilted, tired appearance
- Exhausted, lifeless
- Slumped or collapsed pose
- Very dim lighting with heavy shadows
''';
    }
  }

  /// 賞味期限に基づく感情プロンプトを取得
  static String _getEmotionPrompt(int daysUntilExpiry) {
    if (daysUntilExpiry > 7) {
      return '''
Emotion: Very excited and energetic
- Big, bright smile
- Sparkling, enthusiastic eyes
- Bouncing or jumping pose
- Arms raised in celebration
- Very happy and proud
''';
    } else if (daysUntilExpiry > 3) {
      return '''
Emotion: Happy and confident
- Warm, friendly smile
- Bright, cheerful eyes
- Relaxed, comfortable pose
- Arms at sides or one hand on hip
- Content and satisfied
''';
    } else if (daysUntilExpiry > 1) {
      return '''
Emotion: Slightly concerned
- Small, worried smile
- Alert, watchful eyes
- Cautious, defensive pose
- One hand raised in caution
- Concerned but not panicked
''';
    } else if (daysUntilExpiry >= 0) {
      return '''
Emotion: Worried and anxious
- Frown or worried expression
- Wide, anxious eyes
- Frantic, defensive pose
- Both hands raised in alarm
- Very stressed and worried
''';
    } else {
      return '''
Emotion: Sad and defeated
- Downcast expression
- Tired, droopy eyes
- Slumped, exhausted pose
- Arms hanging limply
- Very sad and defeated
''';
    }
  }

  /// キャラクター用のフォールバック画像URLを取得
  static String _getCharacterFallbackImageUrl(String productName, String category) {
    // 実際のアセット画像が存在する場合はそのパスを返す
    // 現在はプレースホルダーとしてnullを返す
    return 'assets/images/default_character.png';
  }

  /// 商品を複数段階画像で更新（ref使用）
  static void _updateProductWithMultiStageImages(String productId, Map<ImageStage, String> imageUrls, WidgetRef? ref) {
    if (ref != null) {
      try {
        // ローカル状態を更新
        ref.read(appStateProvider.notifier).updateProductImages(productId, imageUrls);

        // 現在の商品情報を取得してFirebaseに保存
        final appState = ref.read(appStateProvider);
        final product = appState.products.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Product not found: $productId'),
        );

        // Firebaseに保存
        ref.read(appStateProvider.notifier).updateProductInFirebase(product);

        print('✅ 商品画像更新完了 (ref使用): $productId');
      } catch (e) {
        print('❌ 商品画像更新エラー (ref使用): $e');
      }
    } else {
      print('⚠️ refがnullのため、商品画像更新をスキップ: $productId');
      print('📝 生成された画像URLs: ${imageUrls.length}個');
      for (final entry in imageUrls.entries) {
        print('  ${entry.key.name}: ${entry.value}');
      }

      // refがnullでもFirebaseに直接保存を試行
      _updateProductImagesDirectly(productId, imageUrls);
    }
  }

  /// Firebaseに直接商品画像を更新（refなし）
  static void _updateProductImagesDirectly(String productId, Map<ImageStage, String> imageUrls) {
    try {
      print('🔥 Firebaseに直接商品画像を更新中: $productId');

      // Firebase Firestoreに直接更新
      final firestore = FirebaseFirestore.instance;
      final productRef = firestore.collection('products').doc(productId);

      // imageUrlsをFirestore用の形式に変換
      final imageUrlsData = <String, String>{};
      for (final entry in imageUrls.entries) {
        imageUrlsData[entry.key.name] = entry.value;
      }

      productRef.update({
        'imageUrls': imageUrlsData,
        'updatedAt': FieldValue.serverTimestamp(),
      }).then((_) {
        print('✅ Firebase直接更新完了: $productId');
      }).catchError((error) {
        print('❌ Firebase直接更新エラー: $error');
      });

    } catch (e) {
      print('❌ Firebase直接更新エラー: $e');
    }
  }

  /// 商品を画像で更新（ref使用）
  static void _updateProductWithImageRef(WidgetRef ref, String productId, String imageUrl) {
    try {
      ref.read(appStateProvider.notifier).updateProductImage(productId, imageUrl);
      print('✅ 商品画像更新完了 (ref使用): $productId');
    } catch (e) {
      print('❌ 商品画像更新エラー (ref使用): $e');
    }
  }

  /// 商品を画像で更新（ref不使用）
  static void _updateProductWithImage(String productId, String imageUrl) {
    try {
      // refがない場合は、直接Firestoreを更新
      // この実装は必要に応じて追加
      print('✅ 商品画像更新完了 (ref不使用): $productId');
    } catch (e) {
      print('❌ 商品画像更新エラー (ref不使用): $e');
    }
  }

  /// Base64データをFirebase Storageにアップロード
  static Future<String?> _uploadBase64ToFirebaseStorage(
    String base64Data,
    String mimeType,
    String productName,
    ImageStage stage,
  ) async {
    try {
      print('🔥 Firebase Storageにアップロード開始...');

      // Base64データをバイト配列に変換
      final bytes = base64Decode(base64Data);

      // ファイル名を生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${productName}_${stage.name}_$timestamp.png';

      // Firebase Storageの参照を作成
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'productName': productName,
          'stage': stage.name,
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      // アップロード実行
      final uploadTask = storageRef.putData(
        Uint8List.fromList(bytes),
        metadata,
      );

      // アップロード完了を待機
      final snapshot = await uploadTask;

      // ダウンロードURLを取得
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Firebase Storageアップロード完了: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      print('❌ Firebase Storageアップロードエラー: $e');
      return null;
    }
  }
}

// ImageStageはProductモデルで定義されているものを使用
