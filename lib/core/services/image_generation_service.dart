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
  }) async {
    try {
      print('🖼️ ImageGenerationService: 画像生成開始');
      print('   料理名: $dishName');
      print('   説明: $description');
      print('   スタイル: $style');

      // ADKApiClientを使用して画像生成
      final adkClient = ADKApiClient();
      final result = await adkClient.generateImage(
        prompt: '$dishName: $description',
        style: style,
        size: '1024x1024',
      );
      if (result != null && result['image_url'] != null) {
        final imageUrl = result['image_url'] as String;
        print('✅ ImageGenerationService: 画像生成成功');
        print('   画像URL: $imageUrl');
        return imageUrl;
      } else {
        print('❌ ImageGenerationService: 画像生成失敗 - 結果がnull');
        return null;
      }
    } catch (e) {
      print('❌ ImageGenerationService: 画像生成エラー: $e');
      return null;
    }
  }

  /// 画像生成用のプロンプトを構築
  String _buildImagePrompt(String dishName, String description, String style) {
    return '''
Create a high-quality, appetizing food photograph of $dishName.

Description: $description

Requirements:
- Professional food photography style
- Clean, modern presentation
- Good lighting and composition
- Square aspect ratio (1:1)
- High resolution and detail
- Appetizing and visually appealing
- Japanese cuisine aesthetic
- Minimal background or simple table setting
- Focus on the main dish

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
    final results = <String, String?>{};

    // 並列で画像生成を実行
    final futures = [
      generateDishImage(dishName: mainDish, description: 'Main dish'),
      generateDishImage(dishName: sideDish, description: 'Side dish'),
      generateDishImage(dishName: soup, description: 'Soup'),
      generateDishImage(dishName: rice, description: 'Rice or staple food'),
    ];

    final imageUrls = await Future.wait(futures);

    results['mainDish'] = imageUrls[0];
    results['sideDish'] = imageUrls[1];
    results['soup'] = imageUrls[2];
    results['rice'] = imageUrls[3];

    return results;
  }

  /// 商品の多段階画像を生成（既存の機能との互換性のため）
  Future<Map<String, String?>> generateMultiStageProductIcons({
    required String productName,
    required String category,
    String? productId,
  }) async {
    // 現在は画像生成を無効化（OpenAI APIキーが必要）
    // 代わりにプレースホルダー画像を使用
    await Future.delayed(const Duration(seconds: 1));

    return {
      'urgent': null,
      'fresh': null,
      'expired': null,
      'veryFresh': null,
      'warning': null,
    };
  }
}