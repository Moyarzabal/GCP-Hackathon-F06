import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../shared/models/meal_plan.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/models/shopping_item.dart';
import '../../../../core/services/ai_meal_planning_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/providers/app_state_provider.dart';

/// Firestoreサービスのプロバイダー
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// AI献立提案サービスのプロバイダー
final aiMealPlanningServiceProvider = Provider<AIMealPlanningService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is not defined in .env file');
  }
  
  final config = MealPlanningConfig(apiKey: apiKey);
  return AIMealPlanningService(config);
});

/// 献立プロバイダー
final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, AsyncValue<MealPlan?>>((ref) {
  return MealPlanNotifier(
    ref.read(aiMealPlanningServiceProvider),
    ref.read(firestoreServiceProvider),
  );
});

/// 献立履歴プロバイダー
final mealPlanHistoryProvider = StateNotifierProvider<MealPlanHistoryNotifier, AsyncValue<List<MealPlan>>>((ref) {
  return MealPlanHistoryNotifier(
    ref.read(firestoreServiceProvider),
  );
});

/// 買い物リストプロバイダー
final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, AsyncValue<List<ShoppingItem>>>((ref) {
  return ShoppingListNotifier(
    ref.read(firestoreServiceProvider),
  );
});

/// 献立の状態管理
class MealPlanNotifier extends StateNotifier<AsyncValue<MealPlan?>> {
  final AIMealPlanningService _aiService;
  final FirestoreService _firestoreService;

  MealPlanNotifier(this._aiService, this._firestoreService) : super(const AsyncValue.data(null));

  /// 献立を提案する
  Future<void> suggestMealPlan({
    required String householdId,
    UserPreferences? preferences,
  }) async {
    print('🍽️ MealPlanNotifier: 献立提案開始');
    state = const AsyncValue.loading();
    
    try {
      // 冷蔵庫の商品データを取得
      print('📦 冷蔵庫の商品データを取得中...');
      final products = await _firestoreService.getAllProducts();
      print('   取得した商品数: ${products.length}');
      
      // デフォルトの好み設定
      final userPreferences = preferences ?? const UserPreferences();
      print('   ユーザー設定: ${userPreferences.toJson()}');
      
      // AIに献立生成を依頼
      print('🤖 AIサービスに献立生成を依頼中...');
      final mealPlan = await _aiService.suggestMealPlan(
        refrigeratorItems: products,
        householdId: householdId,
        preferences: userPreferences,
      );
      
      // Firestoreに保存
      print('💾 Firestoreに献立を保存中...');
      final mealPlanId = await _firestoreService.saveMealPlan(mealPlan);
      final savedMealPlan = mealPlan.copyWith(id: mealPlanId);
      print('   保存された献立ID: $mealPlanId');
      
      state = AsyncValue.data(savedMealPlan);
      print('✅ MealPlanNotifier: 献立提案完了');
    } catch (error, stackTrace) {
      print('❌ MealPlanNotifier: 献立提案エラー: $error');
      print('   スタックトレース: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立を承認する
  Future<void> acceptMealPlan(String mealPlanId) async {
    if (state.value == null) return;
    
    try {
      // Firestoreで状態を更新
      await _firestoreService.updateMealPlanStatus(
        mealPlanId,
        MealPlanStatus.accepted,
      );
      
      // ローカル状態を更新
      final updatedMealPlan = state.value!.copyWith(
        status: MealPlanStatus.accepted,
        acceptedAt: DateTime.now(),
      );
      
      state = AsyncValue.data(updatedMealPlan);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立を拒否する
  Future<void> rejectMealPlan(String mealPlanId, String reason) async {
    if (state.value == null) return;
    
    try {
      // Firestoreで状態を更新
      await _firestoreService.updateMealPlanStatus(
        mealPlanId,
        MealPlanStatus.cancelled,
      );
      
      // ローカル状態を更新
      final updatedMealPlan = state.value!.copyWith(
        status: MealPlanStatus.cancelled,
      );
      
      state = AsyncValue.data(updatedMealPlan);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 代替献立を提案する
  Future<void> suggestAlternatives(String reason) async {
    if (state.value == null) return;
    
    try {
      // 冷蔵庫の商品データを取得
      final products = await _firestoreService.getAllProducts();
      
      // 代替献立を生成
      final alternatives = await _aiService.suggestAlternatives(
        originalMealPlan: state.value!,
        refrigeratorItems: products,
        householdId: state.value!.householdId,
        preferences: const UserPreferences(),
        reason: reason,
      );
      
      // 最初の代替案を選択
      if (alternatives.isNotEmpty) {
        final selectedAlternative = alternatives.first;
        final mealPlanId = await _firestoreService.saveMealPlan(selectedAlternative);
        final savedMealPlan = selectedAlternative.copyWith(id: mealPlanId);
        
        state = AsyncValue.data(savedMealPlan);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立を完了にする
  Future<void> completeMealPlan(String mealPlanId) async {
    if (state.value == null) return;
    
    try {
      // Firestoreで状態を更新
      await _firestoreService.updateMealPlanStatus(
        mealPlanId,
        MealPlanStatus.completed,
      );
      
      // ローカル状態を更新
      final updatedMealPlan = state.value!.copyWith(
        status: MealPlanStatus.completed,
        completedAt: DateTime.now(),
      );
      
      state = AsyncValue.data(updatedMealPlan);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立を評価する
  Future<void> rateMealPlan(String mealPlanId, double rating) async {
    if (state.value == null) return;
    
    try {
      // Firestoreで評価を更新
      await _firestoreService.updateMealPlanRating(mealPlanId, rating);
      
      // ローカル状態を更新（評価は個別のメニューアイテムに保存されるため、ここでは何もしない）
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立をクリアする
  void clearMealPlan() {
    state = const AsyncValue.data(null);
  }
}

/// 献立履歴の状態管理
class MealPlanHistoryNotifier extends StateNotifier<AsyncValue<List<MealPlan>>> {
  final FirestoreService _firestoreService;

  MealPlanHistoryNotifier(this._firestoreService) : super(const AsyncValue.data([]));

  /// 献立履歴を取得する
  Future<void> loadMealPlanHistory(String householdId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final mealPlans = await _firestoreService.getMealPlanHistory(
        householdId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      state = AsyncValue.data(mealPlans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 献立履歴をリフレッシュする
  Future<void> refreshHistory(String householdId) async {
    await loadMealPlanHistory(householdId);
  }
}

/// 買い物リストの状態管理
class ShoppingListNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  final FirestoreService _firestoreService;

  ShoppingListNotifier(this._firestoreService) : super(const AsyncValue.data([]));

  /// 買い物リストを生成する
  Future<void> generateShoppingList(MealPlan mealPlan) async {
    state = const AsyncValue.loading();
    
    try {
      // AIサービスで買い物リストを生成
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is not defined in .env file');
      }
      
      final aiService = AIMealPlanningService(
        MealPlanningConfig(apiKey: apiKey),
      );
      final shoppingItems = aiService.generateShoppingList(mealPlan);
      
      // Firestoreに保存
      final shoppingListId = await _firestoreService.saveShoppingList(
        mealPlan.householdId,
        mealPlan.id,
        shoppingItems,
      );
      
      // IDを設定して保存
      final itemsWithIds = shoppingItems.asMap().entries.map((entry) {
        return entry.value.copyWith(id: '${shoppingListId}_${entry.key}');
      }).toList();
      
      state = AsyncValue.data(itemsWithIds);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 買い物アイテムの状態を切り替える
  Future<void> toggleItemStatus(String itemId) async {
    final currentItems = state.value;
    if (currentItems == null) return;
    
    try {
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      
      if (itemIndex != -1) {
        final item = currentItems[itemIndex];
        final updatedItem = item.copyWith(
          isCompleted: !item.isCompleted,
          completedAt: !item.isCompleted ? DateTime.now() : null,
        );
        
        // Firestoreで更新
        await _firestoreService.updateShoppingItem(itemId, {
          'isCompleted': updatedItem.isCompleted,
          'completedAt': updatedItem.completedAt?.millisecondsSinceEpoch,
        });
        
        // ローカル状態を更新
        final updatedItems = List<ShoppingItem>.from(currentItems);
        updatedItems[itemIndex] = updatedItem;
        state = AsyncValue.data(updatedItems);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// カスタムアイテムを追加する
  Future<void> addCustomItem({
    required String name,
    required String quantity,
    required String unit,
    required String category,
    required String addedBy,
  }) async {
    try {
      final newItem = ShoppingItem(
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        isCustom: true,
        addedBy: addedBy,
        addedAt: DateTime.now(),
      );
      
      // Firestoreに保存
      final itemId = await _firestoreService.addShoppingItem(newItem);
      final savedItem = newItem.copyWith(id: itemId);
      
      // ローカル状態に追加
      final currentItems = state.value ?? [];
      state = AsyncValue.data([...currentItems, savedItem]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 買い物アイテムを削除する
  Future<void> deleteItem(String itemId) async {
    try {
      // Firestoreから削除
      await _firestoreService.deleteShoppingItem(itemId);
      
      // ローカル状態から削除
      final currentItems = state.value ?? [];
      final updatedItems = currentItems.where((item) => item.id != itemId).toList();
      state = AsyncValue.data(updatedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 完了したアイテムをクリアする
  Future<void> clearCompletedItems() async {
    try {
      final currentItems = state.value ?? [];
      final completedItems = currentItems.where((item) => item.isCompleted).toList();
      
      // Firestoreから削除
      for (final item in completedItems) {
        if (item.id != null) {
          await _firestoreService.deleteShoppingItem(item.id!);
        }
      }
      
      // ローカル状態から削除
      final pendingItems = currentItems.where((item) => !item.isCompleted).toList();
      state = AsyncValue.data(pendingItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 買い物リストをクリアする
  void clearShoppingList() {
    state = const AsyncValue.data([]);
  }
}
