import 'package:logging/logging.dart';

import '../../shared/models/product.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/shopping_item.dart';
import 'adk_api_client.dart';

/// マルチエージェント献立提案サービス
/// ADK APIを使用して複数の専門エージェントによる献立提案を提供
class MultiAgentMealPlanningService {
  static final Logger _logger = Logger('MultiAgentMealPlanningService');
  
  final ADKApiClient _apiClient;

  MultiAgentMealPlanningService({ADKApiClient? apiClient})
      : _apiClient = apiClient ?? ADKApiClient();

  /// ADKエージェントを使用した献立提案
  Future<MealPlan> suggestMealPlan({
    required List<Product> refrigeratorItems,
    required String householdId,
    required ADKUserPreferences preferences,
  }) async {
    try {
      _logger.info('マルチエージェント献立提案開始', {
        'householdId': householdId,
        'productCount': refrigeratorItems.length,
        'maxCookingTime': preferences.maxCookingTime,
      });

      // ADK API経由で献立提案を取得
      final response = await _apiClient.suggestMealPlan(
        refrigeratorItems: refrigeratorItems,
        householdId: householdId,
        preferences: preferences,
      );

      _logger.info('マルチエージェント献立提案完了', {
        'householdId': householdId,
        'processingTime': response.processingTime,
        'confidence': response.mealPlan.confidence,
        'agentsUsed': response.agentsUsed,
      });

      return response.mealPlan;
    } catch (e) {
      _logger.severe('マルチエージェント献立提案エラー', e);
      rethrow;
    }
  }

  /// 代替献立提案
  Future<List<MealPlan>> suggestAlternatives({
    required MealPlan originalMealPlan,
    required List<Product> refrigeratorItems,
    required String householdId,
    required ADKUserPreferences preferences,
    required String reason,
  }) async {
    try {
      _logger.info('マルチエージェント代替献立提案開始', {
        'householdId': householdId,
        'reason': reason,
      });

      final alternatives = await _apiClient.suggestAlternatives(
        originalMealPlan: originalMealPlan,
        refrigeratorItems: refrigeratorItems,
        householdId: householdId,
        preferences: preferences,
        reason: reason,
      );

      _logger.info('マルチエージェント代替献立提案完了', {
        'householdId': householdId,
        'alternativeCount': alternatives.length,
      });

      return alternatives;
    } catch (e) {
      _logger.severe('マルチエージェント代替献立提案エラー', e);
      rethrow;
    }
  }

  /// 買い物リスト生成
  Future<List<ShoppingItem>> generateShoppingList({
    required MealPlan mealPlan,
    required List<Product> availableProducts,
  }) async {
    try {
      _logger.info('買い物リスト生成開始', {
        'mealPlanId': mealPlan.householdId,
      });

      // 利用可能な商品名のセットを作成
      final availableProductNames = availableProducts
          .map((product) => product.name.toLowerCase())
          .toSet();

      final shoppingItems = <ShoppingItem>[];

      // すべての材料を収集
      final allIngredients = [
        ...mealPlan.mainDish.ingredients,
        ...mealPlan.sideDish.ingredients,
        ...mealPlan.soup.ingredients,
        ...mealPlan.rice.ingredients,
      ];

      // 不足している材料を買い物リストに追加
      for (final ingredient in allIngredients) {
        if (ingredient.shoppingRequired ||
            !availableProductNames.contains(ingredient.name.toLowerCase())) {
          final shoppingItem = ShoppingItem(
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            category: ingredient.category,
            isCustom: false,
            addedBy: 'adk_agent',
            addedAt: DateTime.now(),
            notes: ingredient.notes,
          );

          shoppingItems.add(shoppingItem);
        }
      }

      _logger.info('買い物リスト生成完了', {
        'mealPlanId': mealPlan.householdId,
        'shoppingItemCount': shoppingItems.length,
      });

      return shoppingItems;
    } catch (e) {
      _logger.severe('買い物リスト生成エラー', e);
      rethrow;
    }
  }

  /// ヘルスチェック
  Future<bool> healthCheck() async {
    try {
      return await _apiClient.healthCheck();
    } catch (e) {
      _logger.warning('マルチエージェントサービスヘルスチェック失敗', e);
      return false;
    }
  }

  /// 利用可能なエージェント一覧を取得
  List<String> getAvailableAgents() {
    return [
      'ingredient_analysis',
      'nutrition_balance',
      'recipe_suggestion',
      'cooking_optimization',
      'meal_theme',
      'image_generation',
      'user_preference_conversation',
    ];
  }

  /// エージェントの説明を取得
  Map<String, String> getAgentDescriptions() {
    return {
      'ingredient_analysis': '冷蔵庫の食材を分析し、賞味期限を考慮した優先度付けを行います',
      'nutrition_balance': '栄養バランスを分析し、健康的な献立を提案します',
      'recipe_suggestion': '利用可能な食材から具体的な料理メニューを提案します',
      'cooking_optimization': '調理時間と手順を最適化し、効率的な調理計画を作成します',
      'meal_theme': '献立全体のテーマと統一感を決定します',
      'image_generation': '各料理の魅力的な写真を生成します',
      'user_preference_conversation': 'ユーザーとの自然な対話で設定を収集します',
    };
  }
}
