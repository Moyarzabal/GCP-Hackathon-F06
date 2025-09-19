import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

class JanCodeService {
  static const String _baseUrl = 'https://api.jancodelookup.com/v1';
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();

  String? get _apiKey {
    try {
      final apiKey = dotenv.env['JANCODE_LOOKUP_API_KEY'];
      print('JANCODE_LOOKUP_API_KEY found: ${apiKey != null}');
      if (apiKey != null) {
        print('API Key length: ${apiKey.length}');
      }
      return apiKey;
    } catch (e) {
      print('Error getting JANCODE_LOOKUP_API_KEY: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProductByJAN(String janCode) async {
    try {
      print('=== JAN Code Search Started ===');
      print('Searching for JAN code: $janCode');

      // Clear cache first to force API call
      await _firestoreService.clearProductCache(janCode);
      print('Cache cleared for JAN code: $janCode');

      // Check cache in Firestore (should be empty now)
      final cachedProduct = await _firestoreService.getProductByJAN(janCode);
      if (cachedProduct != null) {
        print('Product found in cache: $janCode');
        print('Cached product data: $cachedProduct');
        return cachedProduct;
      }

      print('Fetching product from JAN Code API: $janCode');

      // Check if API key is available
      final apiKey = _apiKey;
      if (apiKey == null) {
        print('JANCODE_LOOKUP_API_KEY not found, falling back to local database');
        return _getFromLocalDatabase(janCode);
      }

      // Try JANCODE LOOKUP API
      final query = Uri.encodeComponent(janCode);
      final uri = Uri.parse('$_baseUrl/search?appId=$apiKey&query=$query&type=code&hits=1&page=1');

      print('API URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FridgeManager/1.0 (iOS)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('JAN Code API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API response data: $data');

        // Check if product array exists and has items
        if (data['product'] != null && data['product'] is List && (data['product'] as List).isNotEmpty) {
          final products = data['product'] as List;
          final product = products.first; // Get first result

          final productInfo = {
            'janCode': janCode,
            'productName': _getProductNameFromAPI(product),
            'manufacturer': _getManufacturerFromAPI(product),
            'category': await _getCategoryFromAPI(product),
            'imageUrl': _getImageUrlFromAPI(product),
            'nutritionInfo': _getNutritionInfoFromAPI(product),
            'allergens': _getAllergensFromAPI(product),
          };

          print('Product found via API: ${productInfo['productName']}');

          // Cache the product info
          try {
            await _firestoreService.cacheProductInfo(
              janCode: janCode,
              productName: productInfo['productName'] as String,
              manufacturer: productInfo['manufacturer'] as String?,
              category: productInfo['category'] as String?,
              imageUrl: productInfo['imageUrl'] as String?,
              nutritionInfo: productInfo['nutritionInfo'] as Map<String, dynamic>?,
              allergens: productInfo['allergens'] as List<String>?,
            );
          } catch (cacheError) {
            print('Error caching product: $cacheError');
            // Continue even if caching fails
          }

          return productInfo;
        } else {
          print('Product not found in JAN Code API');
        }
      } else {
        print('JAN Code API error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      // Fallback to local database
      return _getFromLocalDatabase(janCode);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  /// ローカルデータベースから商品情報を取得
  Future<Map<String, dynamic>?> _getFromLocalDatabase(String janCode) async {
    if (japaneseProducts.containsKey(janCode)) {
      print('Product found in local database: $janCode');
      final rawData = japaneseProducts[janCode]!;
      print('Raw product data: $rawData');

      final product = {
        'janCode': janCode,
        ...rawData,
      };

      print('Final product data: $product');
      print('Product name: ${product['productName']}');
      print('Manufacturer: ${product['manufacturer']}');
      print('Category: ${product['category']}');

      // Cache the product info
      await _firestoreService.cacheProductInfo(
        janCode: janCode,
        productName: product['productName'] as String,
        manufacturer: product['manufacturer'] as String?,
        category: product['category'] as String?,
        imageUrl: product['imageUrl'] as String?,
      );

      return product;
    }

    print('Product not found: $janCode');
    return null;
  }

  // JANCODE LOOKUP API用のパーサーメソッド
  String _getProductNameFromAPI(Map<String, dynamic> product) {
    return product['itemName'] ?? 'Unknown Product';
  }

  String? _getManufacturerFromAPI(Map<String, dynamic> product) {
    return product['makerName'] ?? product['brandName'];
  }

  Future<String?> _getCategoryFromAPI(Map<String, dynamic> product) async {
    // 統合版Geminiを使ってカテゴリと賞味期限を同時に分析
    final analysis = await _geminiService.analyzeProduct(
      productName: product['itemName']?.toString() ?? '',
      manufacturer: product['makerName']?.toString(),
      brandName: product['brandName']?.toString(),
      categoryOptions: ['飲料', '食品', '調味料', '冷凍食品', 'その他'],
    );
    return analysis.category;
  }

  /// 統合版Gemini分析結果をキャッシュに保存するためのメソッド
  Future<void> _cacheProductAnalysis(String janCode, ProductAnalysis analysis) async {
    try {
      await _firestoreService.cacheProductInfo(
        janCode: janCode,
        productName: '', // 既存の商品名は保持
        manufacturer: null,
        category: analysis.category,
        imageUrl: null,
        nutritionInfo: null,
        allergens: null,
        expiryDays: analysis.expiryDays,
        confidence: analysis.confidence,
      );
    } catch (e) {
      print('Error caching product analysis: $e');
    }
  }

  /// Geminiを使って商品のカテゴリを判定（旧版 - フォールバック用）
  Future<String?> _determineCategoryWithGemini(Map<String, dynamic> product) async {
    try {
      final itemName = product['itemName']?.toString() ?? '';
      final brandName = product['brandName']?.toString() ?? '';
      final makerName = product['makerName']?.toString() ?? '';
      final productDetails = product['ProductDetails']?.toString() ?? '';

      // ユーザー定義のカテゴリリスト
      final availableCategories = ['飲料', '食品', '調味料', '冷凍食品', 'その他'];

      final prompt = '''
商品のカテゴリを判定してください。

商品情報:
- 商品名: $itemName
- ブランド名: $brandName
- メーカー名: $makerName
- 商品詳細: $productDetails

利用可能なカテゴリ:
${availableCategories.map((cat) => '- $cat').join('\n')}

上記の商品情報を分析し、利用可能なカテゴリの中から最も適切なカテゴリを1つ選択してください。

回答形式:
{"category": "選択したカテゴリ名"}

例: {"category": "飲料"}
''';

      print('Geminiにカテゴリ判定を依頼中...');
      final response = await _geminiService.generateContent(prompt);

      if (response.text != null) {
        print('Gemini response: ${response.text}');

        // JSONを抽出して解析
        final jsonStr = _extractJson(response.text!);
        if (jsonStr != null) {
          final json = _parseJson(jsonStr);
          if (json is Map && json['category'] != null) {
            final category = json['category'].toString();

            // 利用可能なカテゴリに含まれているかチェック
            if (availableCategories.contains(category)) {
              print('Gemini判定結果: $category');
              return category;
            } else {
              print('Gemini判定結果が利用可能なカテゴリに含まれていません: $category');
            }
          }
        }
      }

      print('Gemini判定に失敗、フォールバック判定を使用');
      return _fallbackCategoryDetermination(product);

    } catch (e) {
      print('Gemini判定でエラー: $e');
      return _fallbackCategoryDetermination(product);
    }
  }

  /// フォールバック用のカテゴリ判定（従来のキーワード検索）
  String _fallbackCategoryDetermination(Map<String, dynamic> product) {
    final itemName = product['itemName']?.toString().toLowerCase() ?? '';
    final brandName = product['brandName']?.toString().toLowerCase() ?? '';

    if (itemName.contains('茶') || itemName.contains('コーヒー') || itemName.contains('ジュース') ||
        itemName.contains('水') || itemName.contains('飲料')) {
      return '飲料';
    } else if (itemName.contains('麺') || itemName.contains('ラーメン') || itemName.contains('うどん')) {
      return '即席麺';
    } else if (itemName.contains('牛乳') || itemName.contains('ヨーグルト') || itemName.contains('チーズ')) {
      return '乳製品';
    } else if (itemName.contains('冷凍') || itemName.contains('アイス')) {
      return '冷凍食品';
    } else if (itemName.contains('調味料') || itemName.contains('醤油') || itemName.contains('味噌')) {
      return '調味料';
    }

    return 'その他';
  }

  /// JSON文字列を抽出
  String? _extractJson(String text) {
    final jsonPattern = RegExp(r'\{[^{}]*"category"[^{}]*\}');
    final match = jsonPattern.firstMatch(text);
    return match?.group(0);
  }

  /// JSONを解析
  dynamic _parseJson(String jsonStr) {
    try {
      return json.decode(jsonStr);
    } catch (e) {
      print('JSON解析エラー: $e');
      return null;
    }
  }

  String? _getImageUrlFromAPI(Map<String, dynamic> product) {
    return product['itemImageUrl'];
  }

  Map<String, dynamic>? _getNutritionInfoFromAPI(Map<String, dynamic> product) {
    // JANCODE LOOKUP APIでは栄養情報が直接提供されないため、
    // ProductDetailsから抽出を試みる
    final details = product['ProductDetails']?.toString();
    if (details != null && details.isNotEmpty) {
      // 基本的な栄養情報の抽出ロジック（簡易版）
      return {
        'details': details,
      };
    }
    return null;
  }

  List<String>? _getAllergensFromAPI(Map<String, dynamic> product) {
    // JANCODE LOOKUP APIではアレルゲン情報が直接提供されないため、
    // ProductDetailsから抽出を試みる
    final details = product['ProductDetails']?.toString();
    if (details != null && details.isNotEmpty) {
      // アレルゲン情報の抽出ロジック（簡易版）
      final allergens = <String>[];
      final allergenKeywords = ['小麦', '乳', '卵', '大豆', 'ナッツ', '魚', '甲殻類'];

      for (final keyword in allergenKeywords) {
        if (details.contains(keyword)) {
          allergens.add(keyword);
        }
      }

      return allergens.isNotEmpty ? allergens : null;
    }
    return null;
  }

  // 既存のローカルデータベース用メソッド（後方互換性のため保持）
  String _getProductName(Map<String, dynamic> product) {
    // 日本語名を最優先で取得
    if (product['name_ja'] != null && product['name_ja'].toString().isNotEmpty) {
      return product['name_ja'];
    }

    if (product['name'] != null && product['name'].toString().isNotEmpty) {
      final name = product['name'].toString();
      // 日本語文字が含まれているかチェック
      if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(name)) {
        return name;
      }
    }

    return product['name'] ?? 'Unknown Product';
  }

  String? _getManufacturer(Map<String, dynamic> product) {
    return product['manufacturer'] ??
           product['brand'] ??
           product['maker'];
  }

  String? _getCategory(Map<String, dynamic> product) {
    // カテゴリを日本語にマッピング
    final category = product['category'] ?? product['genre'];
    if (category == null) return null;

    return _mapCategoryToJapanese(category.toString());
  }

  String _mapCategoryToJapanese(String category) {
    final categoryMap = {
      'beverages': '飲料',
      'food': '食品',
      'snacks': 'お菓子',
      'dairy': '乳製品',
      'frozen': '冷凍食品',
      'condiments': '調味料',
      'alcohol': '酒類',
      'health': '健康食品',
      'beauty': '化粧品',
      'household': '日用品',
      'other': 'その他',
    };

    return categoryMap[category.toLowerCase()] ?? category;
  }

  String? _getImageUrl(Map<String, dynamic> product) {
    return product['image_url'] ??
           product['image'] ??
           product['thumbnail'];
  }

  Map<String, dynamic>? _getNutritionInfo(Map<String, dynamic> product) {
    if (product['nutrition'] == null) return null;

    final nutrition = product['nutrition'] as Map<String, dynamic>;
    return {
      'energy_kcal': nutrition['energy_kcal'],
      'proteins': nutrition['proteins'],
      'carbohydrates': nutrition['carbohydrates'],
      'sugars': nutrition['sugars'],
      'fat': nutrition['fat'],
      'saturated_fat': nutrition['saturated_fat'],
      'fiber': nutrition['fiber'],
      'sodium': nutrition['sodium'],
      'salt': nutrition['salt'],
    };
  }

  List<String>? _getAllergens(Map<String, dynamic> product) {
    if (product['allergens'] != null && product['allergens'] is List) {
      return (product['allergens'] as List).cast<String>();
    }
    return null;
  }

  // 日本の主要商品データベース（フォールバック用）
  static final Map<String, Map<String, dynamic>> japaneseProducts = {
    '4901777018888': {
      'productName': 'コカ・コーラ 500ml',
      'manufacturer': 'ザ・コカ・コーラ・カンパニー',
      'category': '飲料',
      'imageUrl': null,
    },
    '4902220770199': {
      'productName': 'ポカリスエット 500ml',
      'manufacturer': '大塚製薬',
      'category': '飲料',
      'imageUrl': null,
    },
    '4901005202078': {
      'productName': 'カップヌードル',
      'manufacturer': '日清食品',
      'category': '即席麺',
      'imageUrl': null,
    },
    '4901301231123': {
      'productName': 'ヤクルト',
      'manufacturer': 'ヤクルト',
      'category': '乳製品',
      'imageUrl': null,
    },
    '4902102072670': {
      'productName': '午後の紅茶 ストレートティー',
      'manufacturer': 'キリンビバレッジ',
      'category': '飲料',
      'imageUrl': null,
    },
    '4901005200074': {
      'productName': 'どん兵衛 きつねうどん',
      'manufacturer': '日清食品',
      'category': '即席麺',
      'imageUrl': null,
    },
    '4901551354313': {
      'productName': 'カルピスウォーター',
      'manufacturer': 'アサヒ飲料',
      'category': '飲料',
      'imageUrl': null,
    },
    '4901777018871': {
      'productName': 'ファンタ オレンジ',
      'manufacturer': 'ザ・コカ・コーラ・カンパニー',
      'category': '飲料',
      'imageUrl': null,
    },
    '4901085181843': {
      'productName': '健康ミネラル麦茶',
      'manufacturer': 'キリンビバレッジ',
      'category': '飲料',
      'imageUrl': null,
    },
    '4901005202078': {
      'productName': 'カップヌードル シーフード',
      'manufacturer': '日清食品',
      'category': '即席麺',
      'imageUrl': null,
    },
    '4901005202079': {
      'productName': 'カップヌードル カレー',
      'manufacturer': '日清食品',
      'category': '即席麺',
      'imageUrl': null,
    },
    '4901005202080': {
      'productName': 'カップヌードル チキンラーメン',
      'manufacturer': '日清食品',
      'category': '即席麺',
      'imageUrl': null,
    },
    '4901325275110': {
      'productName': 'おーいお茶 緑茶',
      'manufacturer': '伊藤園',
      'category': '飲料',
      'imageUrl': null,
    },
  };

  Future<Map<String, dynamic>?> getProductWithFallback(String janCode) async {
    // Try JAN Code API first
    var product = await getProductByJAN(janCode);

    // If not found, check Japanese products database
    if (product == null && japaneseProducts.containsKey(janCode)) {
      product = {
        'janCode': janCode,
        ...japaneseProducts[janCode]!,
      };

      // Cache the product
      await _firestoreService.cacheProductInfo(
        janCode: janCode,
        productName: product['productName'] as String,
        manufacturer: product['manufacturer'] as String?,
        category: product['category'] as String?,
        imageUrl: product['imageUrl'] as String?,
      );
    }

    return product;
  }
}
