import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

import '../../shared/models/product.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/shopping_item.dart';

/// ADK API クライアント
class ADKApiClient {
  static final Logger _logger = Logger('ADKApiClient');

  late final Dio _dio;
  final String baseUrl;

  ADKApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? dotenv.env['ADK_API_BASE_URL'] ?? 'http://localhost:8000' {
    _initializeDio();
  }

  /// シンプルな画像生成API用のクライアント
  static ADKApiClient forSimpleImageApi() {
    return ADKApiClient(baseUrl: 'http://localhost:8003');
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 1200),  // 接続タイムアウトを20分に延長
      receiveTimeout: const Duration(seconds: 1800), // 受信タイムアウトを30分に延長
      sendTimeout: const Duration(seconds: 1200),     // 送信タイムアウトを20分に延長
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ログインターセプター
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => _logger.info(object),
    ));

    // エラーハンドリングインターセプター
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _logger.severe('API Error: ${error.message}');
        _handleError(error);
        handler.next(error);
      },
    ));
  }

  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ADKApiException('接続がタイムアウトしました', 'TIMEOUT_ERROR');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (statusCode == 400) {
          throw ADKApiException(
            responseData?['message'] ?? 'リクエストが無効です',
            'BAD_REQUEST',
          );
        } else if (statusCode == 500) {
          throw ADKApiException(
            responseData?['message'] ?? 'サーバー内部エラーが発生しました',
            'INTERNAL_SERVER_ERROR',
          );
        } else {
          throw ADKApiException(
            'APIエラーが発生しました (${statusCode})',
            'API_ERROR',
          );
        }
      case DioExceptionType.cancel:
        throw ADKApiException('リクエストがキャンセルされました', 'CANCELLED');
      case DioExceptionType.connectionError:
        throw ADKApiException('ネットワーク接続エラー', 'CONNECTION_ERROR');
      default:
        throw ADKApiException('不明なエラーが発生しました', 'UNKNOWN_ERROR');
    }
  }

  /// 献立提案API
  Future<ADKMealPlanningResponse> suggestMealPlan({
    required List<Product> refrigeratorItems,
    required String householdId,
    required ADKUserPreferences preferences,
  }) async {
    try {
      _logger.info('ADK献立提案開始', {
        'householdId': householdId,
        'productCount': refrigeratorItems.length,
      });

      final requestData = {
        'refrigerator_items': refrigeratorItems.map((product) => {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'quantity': product.quantity,
          'unit': product.unit,
          'expiry_date': product.expiryDate?.toIso8601String(),
          'days_until_expiry': product.daysUntilExpiry,
          'current_image_url': product.currentImageUrl,
        }).toList(),
        'household_id': householdId,
        'user_preferences': {
          'max_cooking_time': preferences.maxCookingTime,
          'preferred_difficulty': preferences.preferredDifficulty.name,
          'dietary_restrictions': preferences.dietaryRestrictions,
          'allergies': preferences.allergies,
          'disliked_ingredients': preferences.dislikedIngredients,
          'preferred_cuisines': preferences.preferredCuisines,
        },
      };

      final response = await _dio.post('/api/v1/meal-planning/suggest', data: requestData);

      final mealPlanData = response.data['meal_plan'];
      final shoppingListData = response.data['shopping_list'] as List<dynamic>;

      final mealPlan = _parseMealPlan(mealPlanData);
      final shoppingList = shoppingListData
          .map((item) => _parseShoppingItem(item))
          .toList();

      _logger.info('ADK献立提案完了', {
        'householdId': householdId,
        'processingTime': response.data['processing_time'],
        'confidence': mealPlan.confidence,
      });

      return ADKMealPlanningResponse(
        mealPlan: mealPlan,
        shoppingList: shoppingList,
        processingTime: response.data['processing_time']?.toDouble() ?? 0.0,
        agentsUsed: List<String>.from(response.data['agents_used'] ?? []),
      );
    } catch (e) {
      _logger.severe('ADK献立提案エラー', e);
      rethrow;
    }
  }

  /// 代替献立提案API
  Future<List<MealPlan>> suggestAlternatives({
    required MealPlan originalMealPlan,
    required List<Product> refrigeratorItems,
    required String householdId,
    required ADKUserPreferences preferences,
    required String reason,
  }) async {
    try {
      _logger.info('ADK代替献立提案開始', {
        'householdId': householdId,
        'reason': reason,
      });

      final requestData = {
        'original_meal_plan': _mealPlanToJson(originalMealPlan),
        'refrigerator_items': refrigeratorItems.map((product) => {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'quantity': product.quantity,
          'unit': product.unit,
          'expiry_date': product.expiryDate?.toIso8601String(),
          'days_until_expiry': product.daysUntilExpiry,
          'current_image_url': product.currentImageUrl,
        }).toList(),
        'household_id': householdId,
        'user_preferences': {
          'max_cooking_time': preferences.maxCookingTime,
          'preferred_difficulty': preferences.preferredDifficulty.name,
          'dietary_restrictions': preferences.dietaryRestrictions,
          'allergies': preferences.allergies,
          'disliked_ingredients': preferences.dislikedIngredients,
          'preferred_cuisines': preferences.preferredCuisines,
        },
        'reason': reason,
      };

      final response = await _dio.post('/api/v1/meal-planning/alternatives', data: requestData);

      final alternativesData = response.data as List<dynamic>;
      final alternatives = alternativesData.map((data) => _parseMealPlan(data)).toList();

      _logger.info('ADK代替献立提案完了', {
        'householdId': householdId,
        'alternativeCount': alternatives.length,
      });

      return alternatives;
    } catch (e) {
      _logger.severe('ADK代替献立提案エラー', e);
      rethrow;
    }
  }

  /// ヘルスチェック
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      _logger.warning('ADK APIヘルスチェック失敗', e);
      return false;
    }
  }

  /// メールプランのパース
  MealPlan _parseMealPlan(Map<String, dynamic> data) {
    return MealPlan(
      householdId: data['household_id'] as String,
      date: DateTime.parse(data['date'] as String),
      status: MealPlanStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MealPlanStatus.suggested,
      ),
      mainDish: _parseMealItem(data['main_dish'] as Map<String, dynamic>),
      sideDish: _parseMealItem(data['side_dish'] as Map<String, dynamic>),
      soup: _parseMealItem(data['soup'] as Map<String, dynamic>),
      rice: _parseMealItem(data['rice'] as Map<String, dynamic>),
      totalCookingTime: data['total_cooking_time'] as int? ?? 60,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionScore: (data['nutrition_score'] as num?)?.toDouble() ?? 80.0,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.8,
      createdAt: DateTime.parse(data['created_at'] as String),
      createdBy: data['created_by'] as String? ?? 'adk_agent',
    );
  }

  /// メールアイテムのパース
  MealItem _parseMealItem(Map<String, dynamic> data) {
    return MealItem(
      name: data['name'] as String,
      category: MealCategory.main, // デフォルト値
      description: data['description'] as String? ?? '',
      ingredients: (data['ingredients'] as List<dynamic>)
          .map((ingredient) => _parseIngredient(ingredient as Map<String, dynamic>))
          .toList(),
      recipe: _parseRecipe(data['recipe'] as Map<String, dynamic>),
      cookingTime: data['cooking_time'] as int? ?? 30,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionInfo: _parseNutritionInfo(data['nutrition_info'] as Map<String, dynamic>),
      createdAt: DateTime.now(),
    );
  }

  /// レシピのパース
  Recipe _parseRecipe(Map<String, dynamic> data) {
    return Recipe(
      steps: (data['steps'] as List<dynamic>)
          .asMap()
          .entries
          .map((entry) => RecipeStep(
                stepNumber: entry.key + 1,
                description: entry.value as String,
              ))
          .toList(),
      cookingTime: data['cooking_time'] as int? ?? 30,
      prepTime: data['prep_time'] as int? ?? 10,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      tips: (data['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      servingSize: data['serving_size'] as int? ?? 4,
      nutritionInfo: _parseNutritionInfo(data['nutrition_info'] as Map<String, dynamic>),
    );
  }

  /// 材料のパース
  Ingredient _parseIngredient(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      unit: data['unit'] as String,
      available: data['available'] as bool? ?? true,
      expiryDate: data['expiry_date'] != null
          ? DateTime.parse(data['expiry_date'] as String)
          : null,
      shoppingRequired: data['shopping_required'] as bool? ?? false,
      productId: data['product_id'] as String?,
      priority: ExpiryPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => ExpiryPriority.fresh,
      ),
      category: data['category'] as String? ?? 'その他',
      imageUrl: data['image_url'] as String?,
      notes: data['notes'] as String? ?? '',
    );
  }

  /// 栄養情報のパース
  NutritionInfo _parseNutritionInfo(Map<String, dynamic> data) {
    return NutritionInfo(
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (data['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (data['sugar'] as num?)?.toDouble() ?? 0.0,
      sodium: (data['sodium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 買い物アイテムのパース
  ShoppingItem _parseShoppingItem(Map<String, dynamic> data) {
    return ShoppingItem(
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      unit: data['unit'] as String,
      category: data['category'] as String,
      isCustom: data['is_custom'] as bool? ?? false,
      addedBy: data['added_by'] as String? ?? 'adk_agent',
      addedAt: DateTime.parse(data['added_at'] as String),
      notes: data['notes'] as String? ?? '',
    );
  }

  /// メールプランをJSONに変換
  Map<String, dynamic> _mealPlanToJson(MealPlan mealPlan) {
    return {
      'household_id': mealPlan.householdId,
      'date': mealPlan.date.toIso8601String(),
      'status': mealPlan.status.name,
      'main_dish': _mealItemToJson(mealPlan.mainDish),
      'side_dish': _mealItemToJson(mealPlan.sideDish),
      'soup': _mealItemToJson(mealPlan.soup),
      'rice': _mealItemToJson(mealPlan.rice),
      'total_cooking_time': mealPlan.totalCookingTime,
      'difficulty': mealPlan.difficulty.name,
      'nutrition_score': mealPlan.nutritionScore,
      'confidence': mealPlan.confidence,
      'created_at': mealPlan.createdAt.toIso8601String(),
      'created_by': mealPlan.createdBy,
    };
  }

  /// メールアイテムをJSONに変換
  Map<String, dynamic> _mealItemToJson(MealItem mealItem) {
    return {
      'name': mealItem.name,
      'description': mealItem.description,
      'ingredients': mealItem.ingredients.map((ingredient) => {
        'name': ingredient.name,
        'quantity': ingredient.quantity,
        'unit': ingredient.unit,
        'available': ingredient.available,
        'shopping_required': ingredient.shoppingRequired,
        'priority': ingredient.priority.name,
        'category': ingredient.category,
        'notes': ingredient.notes,
      }).toList(),
      'recipe': {
        'steps': mealItem.recipe.steps.map((step) => step.description).toList(),
        'cooking_time': mealItem.recipe.cookingTime,
        'difficulty': mealItem.recipe.difficulty.name,
        'tips': mealItem.recipe.tips,
      },
      'cooking_time': mealItem.cookingTime,
      'difficulty': mealItem.difficulty.name,
      'nutrition_info': {
        'calories': mealItem.nutritionInfo.calories,
        'protein': mealItem.nutritionInfo.protein,
        'carbohydrates': mealItem.nutritionInfo.carbohydrates,
        'fat': mealItem.nutritionInfo.fat,
      },
    };
  }
}

/// ADK API例外
class ADKApiException implements Exception {
  final String message;
  final String errorCode;

  ADKApiException(this.message, this.errorCode);

  @override
  String toString() => 'ADKApiException: $message (Code: $errorCode)';
}

/// ADKユーザー設定
class ADKUserPreferences {
  final int maxCookingTime;
  final DifficultyLevel preferredDifficulty;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final List<String> dislikedIngredients;
  final List<String> preferredCuisines;

  const ADKUserPreferences({
    this.maxCookingTime = 60,
    this.preferredDifficulty = DifficultyLevel.easy,
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.dislikedIngredients = const [],
    this.preferredCuisines = const [],
  });
}

/// ADK献立提案レスポンス
class ADKMealPlanningResponse {
  final MealPlan mealPlan;
  final List<ShoppingItem> shoppingList;
  final double processingTime;
  final List<String> agentsUsed;

  ADKMealPlanningResponse({
    required this.mealPlan,
    required this.shoppingList,
    required this.processingTime,
    required this.agentsUsed,
  });
}

/// 画像生成メソッドをADKApiClientに追加
extension ImageGeneration on ADKApiClient {
  /// 画像生成APIを呼び出し（シンプル版）
  Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String style = 'photorealistic',
    String size = '1024x1024',
    int maxRetries = 3,
  }) async {
    final startTime = DateTime.now();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🖼️ シンプル画像生成API呼び出し開始 (試行 $attempt/$maxRetries)');
        print('   開始時刻: ${startTime.toIso8601String()}');
        print('   プロンプト: $prompt');
        print('   スタイル: $style');
        print('   サイズ: $size');
        print('   ベースURL: ${_dio.options.baseUrl}');
        print('   接続タイムアウト: ${_dio.options.connectTimeout}');
        print('   受信タイムアウト: ${_dio.options.receiveTimeout}');

        // 事前にヘルスチェックを実行
        print('🔍 サーバーヘルスチェック中...');
        final isHealthy = await healthCheck();
        if (!isHealthy) {
          print('⚠️ サーバーが正常に応答しません。フォールバック処理に移行します。');
          if (attempt < maxRetries) {
            print('🔄 リトライします... (${attempt + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 5 * attempt)); // 指数バックオフ
            continue;
          }
          return null;
        }
        print('✅ サーバーは正常に応答しています');

        // シンプルな画像生成APIを呼び出し
        final response = await _dio.post(
          '/generate-image',
          data: {
            'prompt': prompt,
            'style': style,
            'size': size,
          },
        );

        if (response.statusCode == 200) {
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);
          print('✅ シンプル画像生成API成功');
          print('   終了時刻: ${endTime.toIso8601String()}');
          print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');
          print('   レスポンスヘッダー: ${response.headers}');
          print('   レスポンスデータ型: ${response.data.runtimeType}');
          print('   レスポンスデータ: ${response.data}');

          // レスポンスから画像URLを取得
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            print('   レスポンスキー: ${data.keys.toList()}');

            final imageUrl = data['image_url'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              print('🎯 生成された画像URL: $imageUrl');
              return {'image_url': imageUrl};
            } else {
              print('❌ 画像URLが空またはnullです');
              print('   image_url値: $imageUrl');
            }
          } else {
            print('❌ レスポンスがMap形式ではありません: ${response.data}');
          }

          // レスポンスが無効な場合、リトライ
          if (attempt < maxRetries) {
            print('🔄 無効なレスポンスのためリトライします... (${attempt + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 5 * attempt));
            continue;
          }
          return null;
        } else {
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime);
          print('❌ シンプル画像生成API失敗: ${response.statusCode}');
          print('   終了時刻: ${endTime.toIso8601String()}');
          print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');

          // ステータスコードエラーの場合、リトライ
          if (attempt < maxRetries) {
            print('🔄 ステータスコードエラーのためリトライします... (${attempt + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 5 * attempt));
            continue;
          }
          return null;
        }
      } catch (e) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        print('❌ シンプル画像生成APIエラー (試行 $attempt/$maxRetries): $e');
        print('   終了時刻: ${endTime.toIso8601String()}');
        print('   所要時間: ${duration.inMilliseconds}ms (${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒)');
        print('   エラー詳細: ${e.toString()}');

        // エラーの種類を判定
        String errorType = 'その他のエラー';
        String errorMessage = '画像生成に失敗しました';

        if (e.toString().contains('Connection refused')) {
          errorType = '接続拒否';
          errorMessage = 'APIサーバーが起動していない可能性があります。サーバーの起動を確認してください。';
        } else if (e.toString().contains('timeout')) {
          errorType = 'タイムアウト';
          errorMessage = 'ネットワーク接続に時間がかかっています。しばらく待ってから再試行してください。';
        } else if (e.toString().contains('Failed host lookup')) {
          errorType = 'ホスト名解決失敗';
          errorMessage = 'DNSの問題でサーバーに接続できません。ネットワーク設定を確認してください。';
        } else if (e.toString().contains('SocketException')) {
          errorType = 'ソケットエラー';
          errorMessage = 'ネットワーク接続に問題があります。インターネット接続を確認してください。';
        }

        print('🔍 エラー種別: $errorType');
        print('📝 エラーメッセージ: $errorMessage');

        // リトライ可能なエラーの場合、リトライ
        if (attempt < maxRetries && (e.toString().contains('timeout') || e.toString().contains('Connection refused'))) {
          print('🔄 リトライ可能なエラーのためリトライします... (${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 5 * attempt));
          continue;
        }

        // 最後の試行で失敗した場合、フォールバック
        if (attempt == maxRetries) {
          print('🔄 フォールバック: ローカルプレースホルダー画像を使用');
          return null;
        }
      }
    }

    return null;
  }
}
