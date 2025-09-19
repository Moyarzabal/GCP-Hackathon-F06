import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'adk_api_client.dart';

/// 画像生成サービス
class ImageGenerationService {
  static const String _baseUrl = 'https://api.openai.com/v1/images/generations';

  /// 料理の画像を生成する（ADKApiClientを使用）
  Future<String?> generateDishImage({
    required String dishName,
    required String description,
    String style = 'photorealistic',
    int maxRetries = 3,
  }) async {
    final startTime = DateTime.now();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🖼️ ImageGenerationService: 画像生成開始 (試行 $attempt/$maxRetries)');
        print('   開始時刻: ${startTime.toIso8601String()}');
        print('   料理名: $dishName');
        print('   説明: $description');
        print('   スタイル: $style');

        // ADKApiClientを使用して画像生成
        final adkClient = ADKApiClient.forSimpleImageApi();
        final result = await adkClient.generateImage(
          prompt: '$dishName: $description',
          style: style,
          size: '1024x1024',
          maxRetries: 1, // ADKApiClient内でリトライするため、ここでは1回のみ
        );

        if (result != null && result['image_url'] != null) {
          final imageUrl = result['image_url'] as String;
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);
          print('✅ ImageGenerationService: 画像生成成功');
          print('   終了時刻: ${endTime.toIso8601String()}');
          print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');
          print('   画像URL: $imageUrl');
          return imageUrl;
        } else {
          print('❌ ImageGenerationService: 画像生成失敗 - 結果がnull (試行 $attempt/$maxRetries)');

          // リトライ可能な場合、リトライ
          if (attempt < maxRetries) {
            print('🔄 ImageGenerationService: リトライします... (${attempt + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 3 * attempt)); // 指数バックオフ
            continue;
          }
          return null;
        }
      } catch (e) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        print('❌ ImageGenerationService: 画像生成エラー (試行 $attempt/$maxRetries): $e');
        print('   終了時刻: ${endTime.toIso8601String()}');
        print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');

        // リトライ可能なエラーの場合、リトライ
        if (attempt < maxRetries) {
          print('🔄 ImageGenerationService: エラーのためリトライします... (${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 3 * attempt));
          continue;
        }
        return null;
      }
    }

    return null;
  }

  /// 画像生成用のプロンプトを構築
  String _buildImagePrompt(String dishName, String description, String style) {
    // より具体的で魅力的なプロンプトを生成
    String specificPrompt = '';

    if (dishName.contains('主菜') || dishName.contains('炒め物') || dishName.contains('肉')) {
      specificPrompt = 'Show a delicious main dish with meat and vegetables, beautifully plated with garnishes';
    } else if (dishName.contains('副菜') || dishName.contains('サラダ') || dishName.contains('野菜')) {
      specificPrompt = 'Show a fresh, colorful side dish or salad, presented on a small elegant plate';
    } else if (dishName.contains('汁物') || dishName.contains('スープ') || dishName.contains('味噌汁')) {
      specificPrompt = 'Show a steaming hot soup in an attractive bowl, with steam rising and perfect presentation';
    } else if (dishName.contains('ご飯') || dishName.contains('白米') || dishName.contains('米')) {
      specificPrompt = 'Show perfectly cooked white rice in a traditional Japanese rice bowl, with individual grains visible';
    } else {
      specificPrompt = 'Show a delicious Japanese home-cooked meal, beautifully presented';
    }

    return '''
$dishName: $description

$specificPrompt

Visual Requirements:
- Professional food photography with perfect lighting
- Clean, modern presentation on white or wooden table
- Square aspect ratio (1:1) for social media
- High resolution with incredible detail
- Appetizing and mouth-watering appearance
- Japanese home cooking aesthetic
- Fresh, vibrant colors and natural textures
- Soft shadows and professional depth of field
- Minimal, elegant background
- Photorealistic quality that looks delicious

Style: $style
''';
  }

  /// 複数の料理画像を一括生成
  Future<Map<String, String?>> generateMealPlanImages({
    required String mainDish,
    required String sideDish,
    required String soup,
    required String rice,
  }) async {
    final startTime = DateTime.now();
    print('🍽️ ImageGenerationService: 献立画像一括生成開始');
    print('   開始時刻: ${startTime.toIso8601String()}');
    print('   メイン料理: $mainDish');
    print('   副菜: $sideDish');
    print('   汁物: $soup');
    print('   主食: $rice');

    final results = <String, String?>{};

    // 並列で画像生成を実行（各料理に対して個別にリトライ機能を適用）
    final futures = [
      generateDishImage(dishName: mainDish, description: 'Main dish', maxRetries: 3),
      generateDishImage(dishName: sideDish, description: 'Side dish', maxRetries: 3),
      generateDishImage(dishName: soup, description: 'Soup', maxRetries: 3),
      generateDishImage(dishName: rice, description: 'Rice or staple food', maxRetries: 3),
    ];

    final imageUrls = await Future.wait(futures);

    results['mainDish'] = imageUrls[0];
    results['sideDish'] = imageUrls[1];
    results['soup'] = imageUrls[2];
    results['rice'] = imageUrls[3];

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    final successCount = imageUrls.where((url) => url != null).length;

    print('🍽️ ImageGenerationService: 献立画像一括生成完了');
    print('   終了時刻: ${endTime.toIso8601String()}');
    print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');
    print('   成功数: $successCount/4');
    print('   メイン料理: ${results['mainDish'] != null ? '✅' : '❌'}');
    print('   副菜: ${results['sideDish'] != null ? '✅' : '❌'}');
    print('   汁物: ${results['soup'] != null ? '✅' : '❌'}');
    print('   主食: ${results['rice'] != null ? '✅' : '❌'}');

    return results;
  }

  /// 商品の多段階画像を生成（nano banana使用）
  Future<Map<String, String?>> generateMultiStageProductIcons({
    required String productName,
    required String category,
    String? productId,
  }) async {
    try {
      print('🎨 nano banana商品画像生成開始: $productName ($category)');

      // 各感情状態に対応する画像を生成
      final imageUrls = <String, String?>{};

      // 並列で画像生成を実行（nano bananaを使用）
      final futures = [
        _generateProductImageWithNanoBanana(productName, category, 'fresh', '😊'),
        _generateProductImageWithNanoBanana(productName, category, 'warning', '😐'),
        _generateProductImageWithNanoBanana(productName, category, 'urgent', '😟'),
        _generateProductImageWithNanoBanana(productName, category, 'veryFresh', '😊'),
        _generateProductImageWithNanoBanana(productName, category, 'expired', '💀'),
      ];

      final results = await Future.wait(futures);

      imageUrls['fresh'] = results[0];
      imageUrls['warning'] = results[1];
      imageUrls['urgent'] = results[2];
      imageUrls['veryFresh'] = results[3];
      imageUrls['expired'] = results[4];

      print('✅ nano banana商品画像生成完了: ${imageUrls.values.where((url) => url != null).length}/5 成功');
      return imageUrls;
    } catch (e) {
      print('❌ nano banana商品画像生成エラー: $e');
      // エラー時はフォールバック画像を返す
      return {
        'urgent': _getFallbackImageUrl('urgent'),
        'fresh': _getFallbackImageUrl('fresh'),
        'expired': _getFallbackImageUrl('expired'),
        'veryFresh': _getFallbackImageUrl('veryFresh'),
        'warning': _getFallbackImageUrl('warning'),
      };
    }
  }

  /// nano bananaを使用して個別の商品画像を生成
  Future<String?> _generateProductImageWithNanoBanana(
    String productName,
    String category,
    String emotionType,
    String emoji,
  ) async {
    try {
      final prompt = _buildNanoBananaPrompt(productName, category, emotionType, emoji);

      // nano banana（ADKApiClient）を使用して画像生成
      final adkClient = ADKApiClient.forSimpleImageApi();
      final result = await adkClient.generateImage(
        prompt: prompt,
        style: 'kawaii',
        size: '512x512',
      );

      if (result != null && result['image_url'] != null) {
        print('✅ nano banana画像生成成功 ($emotionType): ${result['image_url']}');
        return result['image_url'] as String;
      }

      print('⚠️ nano banana画像生成失敗 ($emotionType): 結果がnull');
      return _getFallbackImageUrl(emotionType);
    } catch (e) {
      print('❌ nano banana個別画像生成エラー ($emotionType): $e');
      return _getFallbackImageUrl(emotionType);
    }
  }

  /// 個別の商品画像を生成（旧メソッド - 互換性のため保持）
  Future<String?> _generateProductImage(
    String productName,
    String category,
    String emotionType,
    String emoji,
  ) async {
    try {
      final prompt = _buildProductImagePrompt(productName, category, emotionType, emoji);

      // ADKApiClientを使用して画像生成
      final adkClient = ADKApiClient.forSimpleImageApi();
      final result = await adkClient.generateImage(
        prompt: prompt,
        style: 'kawaii',
        size: '512x512',
      );

      if (result != null && result['image_url'] != null) {
        return result['image_url'] as String;
      }

      return _getFallbackImageUrl(emotionType);
    } catch (e) {
      print('❌ 個別画像生成エラー ($emotionType): $e');
      return _getFallbackImageUrl(emotionType);
    }
  }

  /// nano banana用の商品画像プロンプトを構築
  String _buildNanoBananaPrompt(
    String productName,
    String category,
    String emotionType,
    String emoji,
  ) {
    final emotionDescriptions = {
      'fresh': 'happy and fresh, bright colors, smiling face, sparkles around',
      'warning': 'neutral expression, slightly concerned, pastel colors',
      'urgent': 'worried expression, sweat drops, muted colors, looking anxious',
      'veryFresh': 'very happy and energetic, bright vibrant colors, excited expression',
      'expired': 'zombie-like appearance, expired and spooky, dark colors, ghost-like',
    };

    final emotionDesc = emotionDescriptions[emotionType] ?? 'neutral kawaii expression';

    // nano banana用のシンプルなプロンプト
    return '$productName: $emotionDesc $emoji kawaii character, $category food item, chibi style, simple design, white background, 512x512';
  }

  /// 商品画像用のプロンプトを構築（旧メソッド - 互換性のため保持）
  String _buildProductImagePrompt(
    String productName,
    String category,
    String emotionType,
    String emoji,
  ) {
    final emotionDescriptions = {
      'fresh': 'happy and fresh, bright colors, smiling face, sparkles around',
      'warning': 'neutral expression, slightly concerned, pastel colors',
      'urgent': 'worried expression, sweat drops, muted colors, looking anxious',
      'veryFresh': 'very happy and energetic, bright vibrant colors, excited expression',
      'expired': 'zombie-like appearance, expired and spooky, dark colors, ghost-like',
    };

    final emotionDesc = emotionDescriptions[emotionType] ?? 'neutral kawaii expression';

    return '''
Create a cute kawaii Japanese mascot character representing $productName ($category food item), $emotionDesc, chibi style, simple design, $emoji expression, white background, sticker-like appearance, high quality, 512x512 pixels
''';
  }

  /// フォールバック画像URLを取得
  String? _getFallbackImageUrl(String emotionType) {
    // 実際のアセット画像が存在する場合はそのパスを返す
    // 現在はプレースホルダーとしてnullを返す
    return null;
  }
}