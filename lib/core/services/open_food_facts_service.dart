import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';
  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      // First check cache in Firestore
      final cachedProduct = await _firestoreService.getProductByJAN(barcode);
      if (cachedProduct != null) {
        print('Product found in cache: $barcode');
        return cachedProduct;
      }

      print('Fetching product from Open Food Facts: $barcode');

      // If not in cache, fetch from Open Food Facts API
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
        headers: {
          'User-Agent': 'FridgeManager/1.0 (iOS)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Open Food Facts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          
          final productInfo = {
            'janCode': barcode,
            'productName': _getProductName(product),
            'manufacturer': product['brands'] ?? '',
            'category': _getCategory(product),
            'imageUrl': _getImageUrl(product),
            'nutritionInfo': _getNutritionInfo(product),
            'allergens': _getAllergens(product),
          };

          print('Product found: ${productInfo['productName']}');

          // Cache the product info
          try {
            await _firestoreService.cacheProductInfo(
              janCode: barcode,
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
          print('Product not found in Open Food Facts database');
        }
      } else {
        print('Open Food Facts API error: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('Error fetching product from Open Food Facts: $e');
      return null;
    }
  }

  String _getProductName(Map<String, dynamic> product) {
    return product['product_name_ja'] ?? 
           product['product_name_en'] ?? 
           product['product_name'] ?? 
           'Unknown Product';
  }

  String? _getCategory(Map<String, dynamic> product) {
    if (product['categories_hierarchy'] != null && 
        product['categories_hierarchy'] is List &&
        (product['categories_hierarchy'] as List).isNotEmpty) {
      final categories = product['categories_hierarchy'] as List;
      return categories.last.toString().replaceAll('en:', '').replaceAll('-', ' ');
    }
    return product['categories'] ?? null;
  }

  String? _getImageUrl(Map<String, dynamic> product) {
    return product['image_url'] ?? 
           product['image_front_url'] ?? 
           product['image_small_url'];
  }

  Map<String, dynamic>? _getNutritionInfo(Map<String, dynamic> product) {
    if (product['nutriments'] == null) return null;
    
    final nutriments = product['nutriments'] as Map<String, dynamic>;
    return {
      'energy_kcal': nutriments['energy-kcal_100g'],
      'proteins': nutriments['proteins_100g'],
      'carbohydrates': nutriments['carbohydrates_100g'],
      'sugars': nutriments['sugars_100g'],
      'fat': nutriments['fat_100g'],
      'saturated_fat': nutriments['saturated-fat_100g'],
      'fiber': nutriments['fiber_100g'],
      'sodium': nutriments['sodium_100g'],
      'salt': nutriments['salt_100g'],
    };
  }

  List<String>? _getAllergens(Map<String, dynamic> product) {
    if (product['allergens_tags'] != null && product['allergens_tags'] is List) {
      return (product['allergens_tags'] as List)
          .map((e) => e.toString().replaceAll('en:', ''))
          .toList();
    }
    return null;
  }

  // Fallback Japanese product database
  static final Map<String, Map<String, dynamic>> japaneseProducts = {
    '4901777018888': {
      'productName': 'コカ・コーラ 500ml',
      'manufacturer': 'The Coca-Cola Company',
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
      'manufacturer': 'The Coca-Cola Company',
      'category': '飲料',
      'imageUrl': null,
    },
  };

  Future<Map<String, dynamic>?> getProductWithFallback(String barcode) async {
    // Try Open Food Facts first
    var product = await getProductByBarcode(barcode);
    
    // If not found, check Japanese products database
    if (product == null && japaneseProducts.containsKey(barcode)) {
      product = {
        'janCode': barcode,
        ...japaneseProducts[barcode]!,
      };
      
      // Cache the product
      await _firestoreService.cacheProductInfo(
        janCode: barcode,
        productName: product['productName'] as String,
        manufacturer: product['manufacturer'] as String?,
        category: product['category'] as String?,
        imageUrl: product['imageUrl'] as String?,
      );
    }
    
    return product;
  }
}