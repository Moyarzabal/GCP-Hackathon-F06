import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/meal_plan_square_card.dart';
import '../widgets/meal_detail_dialog.dart';
import '../widgets/alternative_meal_plans_dialog.dart';
import '../../../../core/services/image_generation_service.dart';
import '../../../../core/services/adk_api_client.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  Map<String, String?> _mealImages = {};
  bool _isGeneratingImages = false;

  @override
  void initState() {
    super.initState();
    // 画面が表示されたときに献立を提案
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suggestMealPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanAsync = ref.watch(mealPlanProvider);
      // final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '本日の献立',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _suggestMealPlan,
            tooltip: '献立を再提案',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showMealPlanHistory(context),
            tooltip: '献立履歴',
          ),
        ],
      ),
      body: Column(
        children: [
          // エラー表示
          if (mealPlanAsync.hasError)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '献立の生成に失敗しました: ${mealPlanAsync.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _suggestMealPlan,
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),

          // メインコンテンツ
          Expanded(
            child: mealPlanAsync.when(
              data: (mealPlan) => mealPlan != null
                  ? _buildMealPlanContent(mealPlan)
                  : _buildEmptyState(),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanContent(MealPlan mealPlan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 献立ヘッダー
          _buildMealPlanHeader(mealPlan),
          
          const SizedBox(height: 24),
          
          // 献立カード（アクションボタンも含む）
          _buildMealPlanCards(mealPlan),
          
          const SizedBox(height: 24),
          
          // 材料情報
          _buildIngredientsInfo(mealPlan),
        ],
      ),
    );
  }

  Widget _buildMealPlanHeader(MealPlan mealPlan) {
    // 献立のテーマを決定（主菜のカテゴリや調理法に基づく）
    String theme = _determineMealTheme(mealPlan);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '今日の献立テーマ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 献立のテーマ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              theme,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${mealPlan.totalCookingTime}分',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.star,
                label: mealPlan.difficultyDisplayName,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.favorite,
                label: '${mealPlan.nutritionScore.toInt()}点',
                color: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 信頼度表示
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '信頼度: ${(mealPlan.confidence * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 献立のテーマを決定する
  String _determineMealTheme(MealPlan mealPlan) {
    final mainDish = mealPlan.mainDish.name.toLowerCase();
    final sideDish = mealPlan.sideDish.name.toLowerCase();
    final soup = mealPlan.soup.name.toLowerCase();
    
    // 主菜の調理法や食材に基づいてテーマを決定
    if (mainDish.contains('炒め') || mainDish.contains('炒')) {
      return '中華風炒め物テーマ';
    } else if (mainDish.contains('焼き') || mainDish.contains('焼')) {
      return 'シンプル焼き物テーマ';
    } else if (mainDish.contains('煮') || mainDish.contains('煮物')) {
      return '和風煮物テーマ';
    } else if (mainDish.contains('揚げ') || mainDish.contains('フライ')) {
      return '揚げ物テーマ';
    } else if (mainDish.contains('蒸し') || mainDish.contains('蒸')) {
      return 'ヘルシー蒸し物テーマ';
    } else if (mainDish.contains('サラダ') || mainDish.contains('和え')) {
      return 'ヘルシーサラダテーマ';
    } else if (mainDish.contains('カレー') || mainDish.contains('シチュー')) {
      return 'スパイシーカレーテーマ';
    } else if (mainDish.contains('パスタ') || mainDish.contains('スパゲッティ')) {
      return 'イタリアンテーマ';
    } else if (mainDish.contains('丼') || mainDish.contains('どんぶり')) {
      return '丼物テーマ';
    } else if (mainDish.contains('鍋') || mainDish.contains('しゃぶしゃぶ')) {
      return '温かい鍋物テーマ';
    } else {
      // 副菜や汁物からも判断
      if (sideDish.contains('和え') || soup.contains('味噌')) {
        return '和風家庭料理テーマ';
      } else if (sideDish.contains('サラダ') || soup.contains('コンソメ')) {
        return '洋風ヘルシーテーマ';
      } else {
        return 'バランス良い家庭料理テーマ';
      }
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanCards(MealPlan mealPlan) {
    return Column(
      children: [
        // 2x2の正方形ブロックグリッド
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, // 正方形
          children: [
            MealPlanSquareCard(
              mealItem: mealPlan.mainDish,
              title: '主菜',
              imageUrl: _mealImages['mainDish'],
              onTap: () => _showMealDetail(context, mealPlan.mainDish),
            ),
            MealPlanSquareCard(
              mealItem: mealPlan.sideDish,
              title: '副菜',
              imageUrl: _mealImages['sideDish'],
              onTap: () => _showMealDetail(context, mealPlan.sideDish),
            ),
            MealPlanSquareCard(
              mealItem: mealPlan.soup,
              title: '汁物',
              imageUrl: _mealImages['soup'],
              onTap: () => _showMealDetail(context, mealPlan.soup),
            ),
            MealPlanSquareCard(
              mealItem: mealPlan.rice,
              title: '主食',
              imageUrl: _mealImages['rice'],
              onTap: () => _showMealDetail(context, mealPlan.rice),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // アクションボタン
        _buildActionButtons(mealPlan),
      ],
    );
  }

  Widget _buildMealPlanInfo(MealPlan mealPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 調理時間
          Row(
            children: [
              Text(
                '調理目安時間の合計',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${mealPlan.totalCookingTime}分以上',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 主要食材
          Text(
            '主な食材',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mealPlan.allIngredients
                .where((ingredient) => ingredient.available)
                .take(6)
                .map((ingredient) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        ingredient.name,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MealPlan mealPlan) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isGeneratingImages ? null : () => _suggestMealPlan(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isGeneratingImages
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('画像生成中...'),
                    ],
                  )
                : const Text('再提案'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _acceptMealPlan(mealPlan),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '献立を決定',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsInfo(MealPlan mealPlan) {
    final missingIngredients = mealPlan.missingIngredients;
    final expiringIngredients = mealPlan.expiringIngredients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '材料情報',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (expiringIngredients.isNotEmpty) ...[
          _buildIngredientSection(
            title: '賞味期限が近い食材',
            ingredients: expiringIngredients,
            color: Colors.orange,
            icon: Icons.warning,
          ),
          const SizedBox(height: 12),
        ],
        
        if (missingIngredients.isNotEmpty) ...[
          _buildIngredientSection(
            title: '買い物が必要な食材',
            ingredients: missingIngredients,
            color: Colors.red,
            icon: Icons.shopping_cart,
          ),
          const SizedBox(height: 12),
        ],
        
        _buildIngredientSection(
          title: '利用可能な食材',
          ingredients: mealPlan.mainDish.ingredients
              .where((ingredient) => ingredient.available)
              .toList(),
          color: Colors.green,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildIngredientSection({
    required String title,
    required List<Ingredient> ingredients,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ingredients.map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ingredient.displayName,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '献立を提案します',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '冷蔵庫の食材を分析して\n最適な献立を提案します',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _suggestMealPlan,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('献立を提案'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'AIが献立を考えています...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _suggestMealPlan,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _suggestMealPlan() async {
    print('🍽️ MealPlanScreen: 献立提案ボタンが押されました');
    // TODO: 実際のhouseholdIdを取得
    const householdId = 'default_household';
    print('   世帯ID: $householdId');
    
    // 献立を提案
    await ref.read(mealPlanProvider.notifier).suggestMealPlan(householdId: householdId);
    
    // 献立が生成されたら画像を生成
    final mealPlan = ref.read(mealPlanProvider).value;
    if (mealPlan != null) {
      _generateMealImages(mealPlan);
    }
  }

  /// ADK Backendを使用して画像を生成
  Future<String?> _generateImageViaADK(
    ADKApiClient adkApiClient,
    String dishName,
    String description,
  ) async {
    try {
      // ADK Backendの画像生成APIを呼び出し
      print('🖼️ 画像生成開始: $dishName');
      
      // 実際のADK Backend APIを呼び出し
      final response = await adkApiClient.generateImage(
        prompt: '$dishName: $description',
        style: 'photorealistic',
        size: '1024x1024',
      );
      
      if (response != null && response['image_url'] != null) {
        final imageUrl = response['image_url'] as String;
        print('✅ 画像生成完了: $dishName');
        print('   画像URL: $imageUrl');
        return imageUrl;
      } else {
        print('⚠️ 画像生成レスポンスが空: $dishName');
        return null;
      }
    } catch (e) {
      print('❌ 画像生成エラー: $e');
      return null;
    }
  }

  Future<void> _generateMealImages(MealPlan mealPlan) async {
    // 即座にプレースホルダー画像を設定
    setState(() {
      _mealImages = {
        'mainDish': null,
        'sideDish': null,
        'soup': null,
        'rice': null,
      };
      _isGeneratingImages = true;
    });

    try {
      // シンプルな画像生成APIを呼び出し
      final adkApiClient = ADKApiClient.forSimpleImageApi();
      
      // 並列で画像生成を実行（タイムアウトを延長）
      final futures = [
        _generateImageViaADKWithTimeout(
          adkApiClient, 
          mealPlan.mainDish.name,
          mealPlan.mainDish.description,
          120, // 2分でタイムアウト
        ),
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.sideDish.name,
          mealPlan.sideDish.description,
          120,
        ),
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.soup.name,
          mealPlan.soup.description,
          120,
        ),
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.rice.name,
          mealPlan.rice.description,
          120,
        ),
      ];
      
      // 並列実行で結果を待つ
      final results = await Future.wait(futures);
      
      setState(() {
        _mealImages = {
          'mainDish': results[0],
          'sideDish': results[1],
          'soup': results[2],
          'rice': results[3],
        };
        _isGeneratingImages = false;
      });

      print('✅ 献立画像生成完了');
      print('   主菜画像: ${results[0]}');
      print('   副菜画像: ${results[1]}');
      print('   汁物画像: ${results[2]}');
      print('   主食画像: ${results[3]}');
    } catch (e) {
      print('❌ 献立画像生成エラー: $e');
      setState(() {
        _isGeneratingImages = false;
      });
    }
  }

  /// タイムアウト付きの画像生成
  Future<String?> _generateImageViaADKWithTimeout(
    ADKApiClient adkApiClient,
    String dishName,
    String description,
    int timeoutSeconds,
  ) async {
    try {
      print('🖼️ 画像生成開始（タイムアウト: ${timeoutSeconds}秒）: $dishName');
      
      // タイムアウト付きで画像生成を実行
      final response = await adkApiClient.generateImage(
        prompt: '$dishName: $description',
        style: 'photorealistic',
        size: '1024x1024',
      ).timeout(Duration(seconds: timeoutSeconds));
      
      if (response != null && response['image_url'] != null) {
        final imageUrl = response['image_url'] as String;
        print('✅ 画像生成完了: $dishName');
        print('   画像URL: $imageUrl');
        return imageUrl;
      } else {
        print('⚠️ 画像生成レスポンスが空: $dishName');
        return null;
      }
    } catch (e) {
      print('❌ 画像生成エラー（タイムアウト）: $dishName - $e');
      return null;
    }
  }

  void _acceptMealPlan(MealPlan mealPlan) async {
    if (mealPlan.id != null) {
      await ref.read(mealPlanProvider.notifier).acceptMealPlan(mealPlan.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('献立を承認しました'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '買い物リスト',
              textColor: Colors.white,
              onPressed: () => _generateShoppingList(mealPlan),
            ),
          ),
        );
      }
    }
  }


  void _showMealDetail(BuildContext context, MealItem mealItem) {
    showDialog(
      context: context,
      builder: (context) => MealDetailDialog(mealItem: mealItem),
    );
  }

  void _showMealPlanHistory(BuildContext context) {
    // TODO: 献立履歴画面を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('献立履歴機能は準備中です'),
      ),
    );
  }

  void _generateShoppingList(MealPlan mealPlan) {
    // TODO: 買い物リスト生成機能を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('買い物リスト生成機能は準備中です'),
      ),
    );
  }
}
