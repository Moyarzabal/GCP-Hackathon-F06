import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/models/product.dart';
import 'firebase_storage_service.dart';

class ImageGenerationService {
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
        return _parseImageFromResponse(response.body, productName, category);
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
                          
                          // Base64データを画像URLとして使用
                          final base64Data = inlineData['data'] as String;
                          final imageUrl = 'data:${inlineData['mimeType']};base64,$base64Data';
                          
                          // 商品IDが提供されている場合、商品を更新
                          if (productId != null && imageUrl != null) {
                            if (ref != null) {
                              _updateProductWithImageRef(ref, productId, imageUrl);
                            } else {
                              _updateProductWithImage(productId, imageUrl);
                            }
                          }
                          
                          return imageUrl;
                        }
                      }
                      
                      // テキスト応答も確認
                      if (part['text'] != null) {
                        final text = part['text'] as String;
                        print('📝 テキスト応答: $text');
                      }
                    }
                  }
                }
              }
            }
          } else {
            print('⚠️ 期待される配列形式ではありません: ${data.runtimeType}');
          }
        } catch (e) {
          print('⚠️ JSON解析エラー: $e');
        }
        
        print('❌ 画像データが見つかりませんでした');
        final imageUrl = _getCharacterFallbackImageUrl(productName, category);
        if (productId != null && imageUrl != null) {
          if (ref != null) {
            _updateProductWithImageRef(ref, productId, imageUrl);
          } else {
            _updateProductWithImage(productId, imageUrl);
          }
        }
        return imageUrl;
      } else {
        print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
        final imageUrl = _getCharacterFallbackImageUrl(productName, category);
        if (productId != null && imageUrl != null) {
          if (ref != null) {
            _updateProductWithImageRef(ref, productId, imageUrl);
          } else {
            _updateProductWithImage(productId, imageUrl);
          }
        }
        return imageUrl;
      }
    } catch (e) {
      print('❌ Error generating image: $e');
      final imageUrl = _getCharacterFallbackImageUrl(productName, category);
      if (productId != null && imageUrl != null) {
        _updateProductWithImage(productId, imageUrl);
      }
      return imageUrl;
    }
  }

  /// 段階に応じたスタイルプロンプトを生成
  static String _getStageStylePrompt(ImageStage stage) {
    switch (stage) {
      case ImageStage.veryFresh:
        return '''
Character style: Bright, vibrant colors (green, blue, pink)
Character mood: Very fresh, energetic, and enthusiastic
Character expression: Very happy, excited, and full of life
Character accessories: Sparkles, stars, or freshness symbols as cute accessories
Character pose: Dynamic and energetic, showing vitality
''';
      case ImageStage.fresh:
        return '''
Character style: Fresh green and light blue tones
Character mood: Fresh, healthy, and energetic
Character expression: Happy, content, and confident
Character accessories: Small leaves or freshness indicators as cute accessories
Character pose: Upright and proud, showing freshness
''';
      case ImageStage.warning:
        return '''
Character style: Soft yellow and amber tones
Character mood: Cautious but optimistic and hopeful
Character expression: Neutral or slightly concerned, but still charming
Character accessories: Small calendar or time indicator as a cute accessory
Character pose: Balanced stance with a gentle expression
''';
      case ImageStage.urgent:
        return '''
Character style: Warm orange and yellow tones
Character mood: Urgent but still friendly and approachable
Character expression: Slightly worried or alert, but cute
Character accessories: Small clock or warning symbol as a cute accessory
Character pose: Standing tall but with a concerned expression
''';
      case ImageStage.expired:
        return '''
Character style: Muted, grayish tones with subtle red accents
Character mood: Slightly sad but still cute and lovable
Character expression: Gentle frown or concerned look, but still endearing
Character accessories: Small "expired" indicator badge or clock accessory
Character pose: Slightly slumped but still trying to be cheerful
''';
    }
  }

  /// 段階に応じた感情プロンプトを生成
  static String _getStageEmotionPrompt(ImageStage stage) {
    switch (stage) {
      case ImageStage.veryFresh:
        return 'The character should look very fresh and energetic with a bright, enthusiastic appearance. The character should be full of life and vitality.';
      case ImageStage.fresh:
        return 'The character should look fresh and healthy with a pleasant, cheerful appearance. The character should be happy and content.';
      case ImageStage.warning:
        return 'The character should look fresh but with a sense of urgency, while maintaining a charming and cute personality.';
      case ImageStage.urgent:
        return 'The character should look urgent or in need of immediate attention, but still friendly and approachable. The character should be cute even when worried.';
      case ImageStage.expired:
        return 'The character should look slightly sad or expired, but still maintain a cute and lovable appearance. The character should be endearing even in this state.';
    }
  }

  /// 賞味期限の状態に基づくキャラクタースタイルプロンプトを生成（後方互換性のため残す）
  static String _getStylePrompt(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return '''
Character style: Muted, grayish tones with subtle red accents
Character mood: Slightly sad but still cute and lovable
Character expression: Gentle frown or concerned look, but still endearing
Character accessories: Small "expired" indicator badge or clock accessory
Character pose: Slightly slumped but still trying to be cheerful
''';
    } else if (daysUntilExpiry <= 1) {
      return '''
Character style: Warm orange and yellow tones
Character mood: Urgent but still friendly and approachable
Character expression: Slightly worried or alert, but cute
Character accessories: Small clock or warning symbol as a cute accessory
Character pose: Standing tall but with a concerned expression
''';
    } else if (daysUntilExpiry <= 3) {
      return '''
Character style: Soft yellow and amber tones
Character mood: Cautious but optimistic and hopeful
Character expression: Neutral or slightly concerned, but still charming
Character accessories: Small calendar or time indicator as a cute accessory
Character pose: Balanced stance with a gentle expression
''';
    } else if (daysUntilExpiry <= 7) {
      return '''
Character style: Fresh green and light blue tones
Character mood: Fresh, healthy, and energetic
Character expression: Happy, content, and confident
Character accessories: Small leaves or freshness indicators as cute accessories
Character pose: Upright and proud, showing freshness
''';
    } else {
      return '''
Character style: Bright, vibrant colors (green, blue, pink)
Character mood: Very fresh, energetic, and enthusiastic
Character expression: Very happy, excited, and full of life
Character accessories: Sparkles, stars, or freshness symbols as cute accessories
Character pose: Dynamic and energetic, showing vitality
''';
    }
  }

  /// 賞味期限の状態に基づくキャラクター感情プロンプトを生成
  static String _getEmotionPrompt(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return 'The character should look slightly sad or expired, but still maintain a cute and lovable appearance. The character should be endearing even in this state.';
    } else if (daysUntilExpiry <= 1) {
      return 'The character should look urgent or in need of immediate attention, but still friendly and approachable. The character should be cute even when worried.';
    } else if (daysUntilExpiry <= 3) {
      return 'The character should look fresh but with a sense of urgency, while maintaining a charming and cute personality.';
    } else if (daysUntilExpiry <= 7) {
      return 'The character should look fresh and healthy with a pleasant, cheerful appearance. The character should be happy and content.';
    } else {
      return 'The character should look very fresh, vibrant, and full of life. The character should be energetic, enthusiastic, and bursting with vitality.';
    }
  }

  /// キャラクター風フォールバック用の画像URLを生成
  static String _getCharacterFallbackImageUrl(String productName, String category) {
    // カテゴリに基づいてキャラクター風の画像を選択
    final categoryImages = {
      '飲料': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png',
      '食品': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png',
      '調味料': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png',
      '冷凍食品': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png',
      'その他': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png',
    };
    
    return categoryImages[category] ?? 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=512&h=512&fit=crop&crop=center&auto=format&q=80&fm=png';
  }

  /// フォールバック用の画像URLを生成（実際に存在する画像を使用）
  static String _getFallbackImageUrl(String productName, String category) {
    // カテゴリに基づいて適切な画像を選択（実際に存在する画像URL）
    final categoryImages = {
      '飲料': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=512&h=512&fit=crop&crop=center&auto=format&q=80',
      '食品': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=512&h=512&fit=crop&crop=center&auto=format&q=80',
      '調味料': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=512&h=512&fit=crop&crop=center&auto=format&q=80',
      '冷凍食品': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=512&h=512&fit=crop&crop=center&auto=format&q=80',
      'その他': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=512&h=512&fit=crop&crop=center&auto=format&q=80',
    };
    
    return categoryImages[category] ?? 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=512&h=512&fit=crop&crop=center&auto=format&q=80';
  }

  /// 画像をダウンロードしてローカルに保存
  static Future<String?> downloadAndSaveImage(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // 実際の実装では、適切なディレクトリに画像を保存
        // ここでは一時的にURLを返す
        return imageUrl;
      }
      return null;
    } catch (e) {
      print('❌ Error downloading image: $e');
      return null;
    }
  }

  /// グローバルコンテナを使用して商品を更新
  static void _updateProductWithImage(String productId, String imageUrl) {
    try {
      // 現在の商品リストを確認
      final currentState = globalContainer.read(appStateProvider);
      print('🔍 現在の商品リスト状態:');
      print('   商品数: ${currentState.products.length}');
      for (var product in currentState.products) {
        print('   商品ID: ${product.id}, 名前: ${product.name}');
      }
      
      // 商品が見つからない場合は少し待ってから再試行
      if (currentState.products.isEmpty) {
        print('⏳ 商品リストが空のため、1秒待機してから再試行...');
        Future.delayed(const Duration(seconds: 1), () {
          _updateProductWithImage(productId, imageUrl);
        });
        return;
      }
      
      // グローバルコンテナを使用して商品を更新
      globalContainer.read(appStateProvider.notifier).updateProductImage(productId, imageUrl);
      print('✅ 商品画像更新完了: $productId');
      print('🖼️ 画像URL: $imageUrl');
    } catch (e) {
      print('⚠️ 商品画像更新エラー: $e');
    }
  }

  /// refを使用して商品を更新（新しいメソッド）
  static void _updateProductWithImageRef(WidgetRef ref, String productId, String imageUrl) {
    try {
      // 現在の商品リストを確認
      final currentState = ref.read(appStateProvider);
      print('🔍 現在の商品リスト状態:');
      print('   商品数: ${currentState.products.length}');
      for (var product in currentState.products) {
        print('   商品ID: ${product.id}, 名前: ${product.name}');
      }
      
      // 商品が見つからない場合は少し待ってから再試行
      if (currentState.products.isEmpty) {
        print('⏳ 商品リストが空のため、1秒待機してから再試行...');
        Future.delayed(const Duration(seconds: 1), () {
          _updateProductWithImageRef(ref, productId, imageUrl);
        });
        return;
      }
      
      // refを使用して商品を更新
      ref.read(appStateProvider.notifier).updateProductImage(productId, imageUrl);
      print('✅ 商品画像更新完了: $productId');
      print('🖼️ 画像URL: $imageUrl');
    } catch (e) {
      print('⚠️ 商品画像更新エラー: $e');
    }
  }

  /// 商品の複数段階画像を更新
  static void _updateProductWithMultiStageImages(
    dynamic productId,
    Map<ImageStage, String> imageUrls,
    WidgetRef? ref
  ) {
    try {
      print('🔄 updateProductMultiStageImages called: productId=$productId (${productId.runtimeType})');
      final productIdString = productId.toString();
      
      // まず、ローカル状態を更新（即座に表示）
      if (ref != null) {
        _updateProductWithMultiStageImagesRef(ref, productIdString, imageUrls);
      } else {
        _updateProductWithMultiStageImagesGlobal(productIdString, imageUrls);
      }
      
      // Firebaseに画像を永続化（非同期で実行）
      _saveImagesToFirebase(productIdString, imageUrls).then((_) {
        print('✅ Firebase画像保存完了: $productIdString');
        // Firebase保存完了後、再度ローカル状態を更新（Firebase StorageのURLで）
        _refreshProductImagesFromFirebase(productIdString, ref);
      }).catchError((error) {
        print('❌ Firebase画像保存でエラーが発生: $error');
      });
    } catch (e) {
      print('❌ 複数段階画像更新エラー: $e');
    }
  }

  /// 商品の複数段階画像を更新（refあり）
  static void _updateProductWithMultiStageImagesRef(
    WidgetRef ref,
    String productId,
    Map<ImageStage, String> imageUrls
  ) {
    try {
      // 現在の商品リストを確認
      final currentState = ref.read(appStateProvider);
      print('🔍 複数段階画像更新 - 現在の商品リスト状態:');
      print('   商品数: ${currentState.products.length}');

      // 商品が見つからない場合は少し待ってから再試行
      if (currentState.products.isEmpty) {
        print('⏳ 商品リストが空のため、1秒待機してから再試行...');
        Future.delayed(const Duration(seconds: 1), () {
          _updateProductWithMultiStageImagesRef(ref, productId, imageUrls);
        });
        return;
      }

      // refを使用して商品を更新
      ref.read(appStateProvider.notifier).updateProductMultiStageImages(productId, imageUrls);
      print('✅ 複数段階画像更新完了: $productId');
      print('🖼️ 生成された画像数: ${imageUrls.length}');
    } catch (e) {
      print('⚠️ 複数段階画像更新エラー: $e');
    }
  }

  /// 商品の複数段階画像を更新（refなし）
  static void _updateProductWithMultiStageImagesGlobal(
    String productId,
    Map<ImageStage, String> imageUrls
  ) {
    try {
      // 現在の商品リストを確認
      final currentState = globalContainer.read(appStateProvider);
      print('🔍 複数段階画像更新 - 現在の商品リスト状態:');
      print('   商品数: ${currentState.products.length}');

      // 商品が見つからない場合は少し待ってから再試行
      if (currentState.products.isEmpty) {
        print('⏳ 商品リストが空のため、1秒待機してから再試行...');
        Future.delayed(const Duration(seconds: 1), () {
          _updateProductWithMultiStageImagesGlobal(productId, imageUrls);
        });
        return;
      }

      // グローバルコンテナを使用して商品を更新
      globalContainer.read(appStateProvider.notifier).updateProductMultiStageImages(productId, imageUrls);
      print('✅ 複数段階画像更新完了: $productId');
      print('🖼️ 生成された画像数: ${imageUrls.length}');
    } catch (e) {
      print('⚠️ 複数段階画像更新エラー: $e');
    }
  }

  /// レスポンスから画像データを解析
  static String? _parseImageFromResponse(String responseBody, String productName, String category) {
    try {
      // ストリーミング応答の場合は、複数のJSONオブジェクトが配列形式で返される
      final responseData = responseBody.trim();
      print('📄 生の応答ボディ: $responseData');
      
      try {
        // 配列形式のJSONを解析
        final data = jsonDecode(responseData);
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
                        
                        // Base64データを画像URLとして使用
                        final base64Data = inlineData['data'] as String;
                        final imageUrl = 'data:${inlineData['mimeType']};base64,$base64Data';
                        
                        return imageUrl;
                      }
                    }
                    
                    // テキスト応答も確認
                    if (part['text'] != null) {
                      final text = part['text'] as String;
                      print('📝 テキスト応答: $text');
                    }
                  }
                }
              }
            }
          }
        } else {
          print('⚠️ 期待される配列形式ではありません: ${data.runtimeType}');
        }
      } catch (e) {
        print('⚠️ JSON解析エラー: $e');
      }
      
      print('❌ 画像データが見つかりませんでした');
      return _getCharacterFallbackImageUrl(productName, category);
    } catch (e) {
      print('❌ 画像解析エラー: $e');
      return _getCharacterFallbackImageUrl(productName, category);
    }
  }

  /// Firebaseに画像を永続化
  static Future<void> _saveImagesToFirebase(
    String productId,
    Map<ImageStage, String> imageUrls,
  ) async {
    try {
      print('💾 Firebaseに画像を保存開始: productId=$productId');
      
      final firestore = FirebaseFirestore.instance;
      final productRef = firestore.collection('products').doc(productId);
      
      // まず、ドキュメントが存在するか確認
      final docSnapshot = await productRef.get();
      if (!docSnapshot.exists) {
        print('❌ 商品ドキュメントが存在しません: $productId');
        return;
      }
      
      // Firebase Storageにアップロード
      final Map<String, String> base64Images = {};
      for (final entry in imageUrls.entries) {
        base64Images[entry.key.name] = entry.value;
      }
      
      print('📤 Firebase Storageにアップロード開始: ${base64Images.length}個の画像');
      final uploadedUrls = await FirebaseStorageService.uploadMultipleBase64Images(
        base64Images: base64Images,
        productId: productId,
      );
      
      if (uploadedUrls.isEmpty) {
        print('❌ Firebase Storageアップロードに失敗しました');
        return;
      }
      
      print('✅ Firebase Storageアップロード完了: ${uploadedUrls.length}個の画像');
      print('🔍 アップロードされたURLs: $uploadedUrls');
      
      // 商品ドキュメントを更新
      await productRef.update({
        'imageUrls': uploadedUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Firebase画像保存完了: ${uploadedUrls.length}個の画像');
    } catch (e) {
      print('❌ Firebase画像保存エラー: $e');
      print('🔍 エラー詳細: ${e.toString()}');
    }
  }

  /// Firebaseから商品の画像情報を再読み込みしてローカル状態を更新
  static void _refreshProductImagesFromFirebase(String productId, WidgetRef? ref) {
    try {
      print('🔄 Firebaseから商品画像を再読み込み: $productId');
      
      final firestore = FirebaseFirestore.instance;
      final productRef = firestore.collection('products').doc(productId);
      
      productRef.get().then((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          final imageUrlsData = data['imageUrls'] as Map<String, dynamic>?;
          
          if (imageUrlsData != null) {
            // FirestoreのデータをImageStageのMapに変換
            final Map<ImageStage, String> imageUrls = {};
            for (final entry in imageUrlsData.entries) {
              final stage = ImageStage.values.firstWhere(
                (e) => e.name == entry.key,
                orElse: () => ImageStage.veryFresh,
              );
              imageUrls[stage] = entry.value as String;
            }
            
            print('🔄 Firebaseから読み込んだ画像URLs: $imageUrls');
            
            // ローカル状態を更新
            if (ref != null) {
              _updateProductWithMultiStageImagesRef(ref, productId, imageUrls);
            } else {
              _updateProductWithMultiStageImagesGlobal(productId, imageUrls);
            }
          }
        }
      }).catchError((error) {
        print('❌ Firebase画像再読み込みエラー: $error');
      });
    } catch (e) {
      print('❌ Firebase画像再読み込みエラー: $e');
    }
  }
}
