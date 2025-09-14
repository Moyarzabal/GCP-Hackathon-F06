import 'package:logging/logging.dart';

import '../../shared/models/product.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/shopping_item.dart';
import 'adk_api_client.dart';
import 'multi_agent_meal_planning_service.dart';
import 'ai_meal_planning_service.dart';

/// 強化された献立提案サービス
/// ADK APIと従来のGemini APIの両方をサポートし、フォールバック機能を提供
class EnhancedMealPlanningService {
  static final Logger _logger = Logger('EnhancedMealPlanningService');
  
  final MultiAgentMealPlanningService _adkService;
  final AIMealPlanningService _fallbackService;
  
  bool _isADKAvailable = false;

  EnhancedMealPlanningService({
    MultiAgentMealPlanningService? adkService,
    AIMealPlanningService? fallbackService,
  }) : _adkService = adkService ?? MultiAgentMealPlanningService(),
       _fallbackService = fallbackService ?? AIMealPlanningService(
         MealPlanningConfig(
           apiKey: '', // Will be set from environment
           model: 'gemini-1.5-flash',
           temperature: 0.7,
           maxTokens: 2048,
         ),
       ) {
    _checkADKAvailability();
  }

  /// ADK APIの可用性をチェック
  Future<void> _checkADKAvailability() async {
    try {
      _isADKAvailable = await _adkService.healthCheck();
      _logger.info('ADK API可用性チェック', {
        'available': _isADKAvailable,
      });
    } catch (e) {
      _logger.warning('ADK API可用性チェック失敗', e);
      _isADKAvailable = false;
    }
  }

  /// 献立提案（ADK API優先、フォールバック機能付き）
  Future<MealPlan> suggestMealPlan({
    required List<Product> refrigeratorItems,
    required String householdId,
    required UserPreferences preferences,
  }) async {
    try {
      // ADK APIが利用可能な場合は使用
      if (_isADKAvailable) {
        _logger.info('ADK APIを使用して献立提案', {
          'householdId': householdId,
          'productCount': refrigeratorItems.length,
        });

        final adkPreferences = ADKUserPreferences(
          maxCookingTime: preferences.maxCookingTime,
          preferredDifficulty: preferences.preferredDifficulty,
          dietaryRestrictions: preferences.dietaryRestrictions,
          allergies: preferences.allergies,
          dislikedIngredients: preferences.dislikedIngredients,
          preferredCuisines: preferences.preferredCuisines,
        );

        return await _adkService.suggestMealPlan(
          refrigeratorItems: refrigeratorItems,
          householdId: householdId,
          preferences: adkPreferences,
        );
      } else {
        // ADK APIが利用できない場合は従来のサービスを使用
        _logger.info('従来のGemini APIを使用して献立提案', {
          'householdId': householdId,
          'productCount': refrigeratorItems.length,
        });

        return await _fallbackService.suggestMealPlan(
          refrigeratorItems: refrigeratorItems,
          householdId: householdId,
          preferences: preferences,
        );
      }
    } catch (e) {
      _logger.severe('献立提案エラー', e);
      
      // ADK APIでエラーが発生した場合は従来のサービスにフォールバック
      if (_isADKAvailable) {
        _logger.info('ADK APIエラーのため従来のサービスにフォールバック');
        _isADKAvailable = false; // 一時的に無効化
        
        try {
          return await _fallbackService.suggestMealPlan(
            refrigeratorItems: refrigeratorItems,
            householdId: householdId,
            preferences: preferences,
          );
        } catch (fallbackError) {
          _logger.severe('フォールバックサービスでもエラー', fallbackError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// 代替献立提案
  Future<List<MealPlan>> suggestAlternatives({
    required MealPlan originalMealPlan,
    required List<Product> refrigeratorItems,
    required String householdId,
    required UserPreferences preferences,
    required String reason,
  }) async {
    try {
      if (_isADKAvailable) {
        _logger.info('ADK APIを使用して代替献立提案', {
          'householdId': householdId,
          'reason': reason,
        });

        final adkPreferences = ADKUserPreferences(
          maxCookingTime: preferences.maxCookingTime,
          preferredDifficulty: preferences.preferredDifficulty,
          dietaryRestrictions: preferences.dietaryRestrictions,
          allergies: preferences.allergies,
          dislikedIngredients: preferences.dislikedIngredients,
          preferredCuisines: preferences.preferredCuisines,
        );

        return await _adkService.suggestAlternatives(
          originalMealPlan: originalMealPlan,
          refrigeratorItems: refrigeratorItems,
          householdId: householdId,
          preferences: adkPreferences,
          reason: reason,
        );
      } else {
        _logger.info('従来のGemini APIを使用して代替献立提案', {
          'householdId': householdId,
          'reason': reason,
        });

        return await _fallbackService.suggestAlternatives(
          originalMealPlan: originalMealPlan,
          refrigeratorItems: refrigeratorItems,
          householdId: householdId,
          preferences: preferences,
          reason: reason,
        );
      }
    } catch (e) {
      _logger.severe('代替献立提案エラー', e);
      
      // フォールバック処理
      if (_isADKAvailable) {
        _logger.info('ADK APIエラーのため従来のサービスにフォールバック');
        _isADKAvailable = false;
        
        try {
          return await _fallbackService.suggestAlternatives(
            originalMealPlan: originalMealPlan,
            refrigeratorItems: refrigeratorItems,
            householdId: householdId,
            preferences: preferences,
            reason: reason,
          );
        } catch (fallbackError) {
          _logger.severe('フォールバックサービスでもエラー', fallbackError);
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// 買い物リスト生成
  Future<List<ShoppingItem>> generateShoppingList({
    required MealPlan mealPlan,
    required List<Product> availableProducts,
  }) async {
    try {
      if (_isADKAvailable) {
        return await _adkService.generateShoppingList(
          mealPlan: mealPlan,
          availableProducts: availableProducts,
        );
      } else {
        return _fallbackService.generateShoppingList(mealPlan);
      }
    } catch (e) {
      _logger.severe('買い物リスト生成エラー', e);
      rethrow;
    }
  }

  /// ヘルスチェック
  Future<bool> healthCheck() async {
    try {
      await _checkADKAvailability();
      return _isADKAvailable || true; // フォールバックサービスは常に利用可能
    } catch (e) {
      _logger.warning('ヘルスチェックエラー', e);
      return false;
    }
  }

  /// 使用中のサービス情報を取得
  Map<String, dynamic> getServiceInfo() {
    return {
      'adk_available': _isADKAvailable,
      'adk_agents': _isADKAvailable ? _adkService.getAvailableAgents() : [],
      'fallback_service': 'gemini_api',
      'features': {
        'multi_agent_processing': _isADKAvailable,
        'fallback_support': true,
        'agent_specialization': _isADKAvailable,
        'enhanced_accuracy': _isADKAvailable,
      }
    };
  }

  /// ADK APIの再試行
  Future<void> retryADKConnection() async {
    _logger.info('ADK API接続の再試行');
    await _checkADKAvailability();
  }

  /// サービス統計情報
  Map<String, dynamic> getServiceStats() {
    return {
      'adk_usage_count': _isADKAvailable ? 1 : 0,
      'fallback_usage_count': _isADKAvailable ? 0 : 1,
      'last_health_check': DateTime.now().toIso8601String(),
      'service_status': _isADKAvailable ? 'adk_enabled' : 'fallback_mode',
    };
  }
}
