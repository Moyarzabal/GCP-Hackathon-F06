import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/meal_plan.dart';
import '../../../../shared/models/shopping_item.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/meal_plan_square_card.dart';
import '../widgets/meal_detail_dialog.dart';
import '../widgets/genre_selection_dialog.dart';
import '../../../../core/services/adk_api_client.dart';
import '../../../../core/services/image_generation_service.dart';
import '../../../../shared/providers/app_state_provider.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  Map<String, String?> _mealImages = {};
  bool _isGeneratingImages = false;
  bool _isInitialLoading = false;
  final ScrollController _scrollController = ScrollController();
  GlobalKey _shoppingListKey = GlobalKey();

  // 代替メニューの表示状態を管理
  Map<String, bool> _showingAlternatives = {
    'main': false,
    'side': false,
    'soup': false,
    'rice': false,
  };
  // 温かみのあるカラーパレット
  static const Color _baseColor = Color(0xFFF6EACB); // クリーム色
  static const Color _primaryColor = Color(0xFFD4A574); // 温かいベージュ
  static const Color _secondaryColor = Color(0xFFB8956A); // 深いベージュ
  static const Color _accentColor = Color(0xFF8B7355); // ブラウン
  static const Color _textColor = Color(0xFF5D4E37); // ダークブラウン

  @override
  void initState() {
    super.initState();
    // 画面が表示されたときに献立を提案
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suggestMealPlan();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 代替メニューの表示状態を切り替える
  void _toggleAlternative(String category) {
    setState(() {
      _showingAlternatives[category] = !_showingAlternatives[category]!;
    });
  }

  /// 現在表示すべきメニューアイテムを取得
  MealItem? _getCurrentMealItem(MealPlan mealPlan, String category) {
    switch (category) {
      case 'main':
        return _showingAlternatives['main']!
            ? mealPlan.alternativeMainDish
            : mealPlan.mainDish;
      case 'side':
        return _showingAlternatives['side']!
            ? mealPlan.alternativeSideDish
            : mealPlan.sideDish;
      case 'soup':
        return _showingAlternatives['soup']!
            ? mealPlan.alternativeSoup
            : mealPlan.soup;
      case 'rice':
        return _showingAlternatives['rice']!
            ? mealPlan.alternativeRice
            : mealPlan.rice;
      default:
        return null;
    }
  }

  /// ジャンル選択ダイアログを表示
  void _showGenreSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => GenreSelectionDialog(
        onGenreSelected: (category) => _addAdditionalDish(category),
      ),
    );
  }

  /// 追加一品を生成して献立に追加
  Future<void> _addAdditionalDish(MealCategory category) async {
    try {
      print('🍽️ 追加一品生成開始: ${category.name}');

      // 現在の献立を取得
      final mealPlan = ref.read(mealPlanProvider).value;
      if (mealPlan == null) return;

      // 追加一品を生成（簡単な実装）
      final additionalDish = _generateAdditionalDish(category, mealPlan);

      // まず追加一品を画像なしで表示
      final updatedMealPlan = mealPlan.copyWith(additionalDish: additionalDish);
      ref.read(mealPlanProvider.notifier).state =
          AsyncValue.data(updatedMealPlan);

      // ローディング表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${additionalDish.name}の画像を生成中...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 画像生成サービスを取得
      final imageGenerationService = ImageGenerationService();

      // 追加一品の画像を生成
      print('🖼️ 追加一品の画像生成開始: ${additionalDish.name}');
      final imageUrl = await imageGenerationService.generateDishImage(
        dishName: additionalDish.name,
        description: additionalDish.description,
        style: 'photorealistic',
        maxRetries: 3,
      );

      // 画像URLが生成された場合は、MealItemに画像URLを設定
      MealItem updatedAdditionalDish = additionalDish;
      if (imageUrl != null) {
        print('✅ 追加一品の画像生成成功: $imageUrl');
        updatedAdditionalDish = additionalDish.copyWith(imageUrl: imageUrl);

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${additionalDish.name}の画像が生成されました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('⚠️ 追加一品の画像生成失敗、画像なしで続行');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${additionalDish.name}の画像生成に失敗しました'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 最終的な献立を更新
      final finalMealPlan =
          mealPlan.copyWith(additionalDish: updatedAdditionalDish);
      ref.read(mealPlanProvider.notifier).state =
          AsyncValue.data(finalMealPlan);

      print('✅ 追加一品生成完了: ${updatedAdditionalDish.name}');
    } catch (e) {
      print('❌ 追加一品生成エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('追加一品の生成に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 追加一品を生成
  MealItem _generateAdditionalDish(MealCategory category, MealPlan mealPlan) {
    final baseName = _getGenreBaseName(category);
    final dishName = _generateDishName(category, mealPlan);

    return MealItem(
      name: dishName,
      category: category,
      description: _getDishDescription(category),
      ingredients: _generateIngredientsForCategory(category),
      recipe: Recipe(
        steps: _getRecipeSteps(category),
        cookingTime: _getCookingTimeForCategory(category),
        prepTime: 5,
        difficulty: DifficultyLevel.easy,
        tips: _getDishTips(category),
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: _getCookingTimeForCategory(category),
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// ジャンルの基本名を取得
  String _getGenreBaseName(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return '主菜';
      case MealCategory.side:
        return '副菜';
      case MealCategory.soup:
        return '汁物';
      case MealCategory.dessert: // おつまみとして使用
        return 'おつまみ';
      default:
        return '料理';
    }
  }

  /// ジャンルに応じた料理名を生成
  String _generateDishName(MealCategory category, MealPlan mealPlan) {
    switch (category) {
      case MealCategory.main:
        return '鶏むね肉の唐揚げ';
      case MealCategory.side:
        return 'きゅうりの浅漬け';
      case MealCategory.soup:
        return 'たまごスープ';
      case MealCategory.dessert: // おつまみとして使用
        return 'ポテトサラダ';
      default:
        return '簡単料理';
    }
  }

  /// ジャンルに応じた材料を生成
  List<Ingredient> _generateIngredientsForCategory(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return [
          Ingredient(
            name: '鶏むね肉',
            quantity: '200',
            unit: 'g',
            available: false,
            shoppingRequired: true,
            priority: ExpiryPriority.fresh,
            category: '肉',
          ),
          Ingredient(
            name: '片栗粉',
            quantity: '大さじ3',
            unit: '',
            available: false,
            shoppingRequired: true,
            priority: ExpiryPriority.fresh,
            category: '調味料',
          ),
        ];
      case MealCategory.side:
        return [
          Ingredient(
            name: 'きゅうり',
            quantity: '2',
            unit: '本',
            available: false,
            shoppingRequired: true,
            priority: ExpiryPriority.fresh,
            category: '野菜',
          ),
          Ingredient(
            name: '塩',
            quantity: '小さじ1',
            unit: '',
            available: true,
            shoppingRequired: false,
            priority: ExpiryPriority.fresh,
            category: '調味料',
          ),
        ];
      case MealCategory.soup:
        return [
          Ingredient(
            name: '卵',
            quantity: '2',
            unit: '個',
            available: true,
            shoppingRequired: false,
            priority: ExpiryPriority.urgent,
            category: '卵',
          ),
          Ingredient(
            name: 'だし',
            quantity: '400',
            unit: 'ml',
            available: false,
            shoppingRequired: true,
            priority: ExpiryPriority.fresh,
            category: '調味料',
          ),
        ];
      case MealCategory.dessert: // おつまみとして使用
        return [
          Ingredient(
            name: 'じゃがいも',
            quantity: '3',
            unit: '個',
            available: true,
            shoppingRequired: false,
            priority: ExpiryPriority.urgent,
            category: '野菜',
          ),
          Ingredient(
            name: 'マヨネーズ',
            quantity: '大さじ2',
            unit: '',
            available: false,
            shoppingRequired: true,
            priority: ExpiryPriority.fresh,
            category: '調味料',
          ),
        ];
      default:
        return [];
    }
  }

  /// ジャンルに応じた調理時間を取得
  int _getCookingTimeForCategory(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return 25;
      case MealCategory.side:
        return 15;
      case MealCategory.soup:
        return 20;
      case MealCategory.dessert: // おつまみとして使用
        return 10;
      default:
        return 15;
    }
  }

  /// ジャンルの表示名を取得
  String _getGenreDisplayName(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return '主菜';
      case MealCategory.side:
        return '副菜';
      case MealCategory.soup:
        return '汁物';
      case MealCategory.dessert: // おつまみとして使用
        return 'おつまみ';
      default:
        return '料理';
    }
  }

  /// 料理の説明を取得
  String _getDishDescription(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return '鶏むね肉を片栗粉で揚げた、サクサクとした唐揚げ';
      case MealCategory.side:
        return 'きゅうりを塩で浅漬けにした、さっぱりとした副菜';
      case MealCategory.soup:
        return '卵を溶いて作る、ふわふわのたまごスープ';
      case MealCategory.dessert: // おつまみとして使用
        return 'じゃがいもをマヨネーズで和えた、定番のポテトサラダ';
      default:
        return '簡単に作れる一品';
    }
  }

  /// レシピの手順を取得
  List<RecipeStep> _getRecipeSteps(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return [
          RecipeStep(stepNumber: 1, description: '鶏むね肉を一口大に切る'),
          RecipeStep(stepNumber: 2, description: '片栗粉をまぶす'),
          RecipeStep(stepNumber: 3, description: '170℃の油で揚げる'),
          RecipeStep(stepNumber: 4, description: 'きつね色になるまで揚げる'),
        ];
      case MealCategory.side:
        return [
          RecipeStep(stepNumber: 1, description: 'きゅうりを輪切りにする'),
          RecipeStep(stepNumber: 2, description: '塩をまぶして10分置く'),
          RecipeStep(stepNumber: 3, description: '水気を絞る'),
        ];
      case MealCategory.soup:
        return [
          RecipeStep(stepNumber: 1, description: 'だしを沸かす'),
          RecipeStep(stepNumber: 2, description: '卵を溶く'),
          RecipeStep(stepNumber: 3, description: '沸騰しただしに卵を流し入れる'),
          RecipeStep(stepNumber: 4, description: '塩で味を整える'),
        ];
      case MealCategory.dessert: // おつまみとして使用
        return [
          RecipeStep(stepNumber: 1, description: 'じゃがいもを茹でる'),
          RecipeStep(stepNumber: 2, description: '皮をむいてつぶす'),
          RecipeStep(stepNumber: 3, description: 'マヨネーズで和える'),
          RecipeStep(stepNumber: 4, description: '塩コショウで味を整える'),
        ];
      default:
        return [
          RecipeStep(stepNumber: 1, description: '材料を準備する'),
          RecipeStep(stepNumber: 2, description: '調理する'),
        ];
    }
  }

  /// 料理のコツを取得
  List<String> _getDishTips(MealCategory category) {
    switch (category) {
      case MealCategory.main:
        return ['油の温度を170℃に保つ', '一度にたくさん揚げない'];
      case MealCategory.side:
        return ['塩の量は控えめに', '水気をしっかり切る'];
      case MealCategory.soup:
        return ['だしは沸騰させてから卵を入れる', '卵は回しながら入れる'];
      case MealCategory.dessert: // おつまみとして使用
        return ['じゃがいもは熱いうちにつぶす', 'マヨネーズは少しずつ加える'];
      default:
        return ['簡単に作れる一品です'];
    }
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
            icon: Icon(
              Icons.shopping_cart,
              color: _accentColor,
            ),
            tooltip: '買い物リストへ',
            onPressed: _scrollToShoppingList,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _accentColor,
            ),
            onPressed: _showReSuggestConfirmation,
            tooltip: '献立を再提案',
          ),
        ],
      ),
      body: mealPlanAsync.when(
        data: (mealPlan) => mealPlan != null
            ? (_isInitialLoading
                ? _buildLoadingWithMealPlan(mealPlan)
                : _buildMealPlanContent(mealPlan))
            : _buildEmptyState(),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildMealPlanContent(MealPlan mealPlan) {
    return SingleChildScrollView(
      controller: _scrollController,
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

          const SizedBox(height: 24),

          // 買い物リスト
          if (mealPlan.hasShoppingList)
            Container(
              key: _shoppingListKey,
              child: _buildShoppingListSection(mealPlan),
            ),
        ],
      ),
    );
  }

  Widget _buildMealPlanHeader(MealPlan mealPlan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _baseColor.withOpacity(0.8),
            _baseColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.restaurant_menu,
          //       color: _textColor,
          //       size: 28,
          //     ),
          //     const SizedBox(width: 12),
          //     Text(
          //       '今日の献立',
          //       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          //         fontWeight: FontWeight.bold,
          //         color: _textColor,
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: 16),

          Row(
            children: [
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${mealPlan.totalCookingTime}分',
                opacity: 0.9,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.star,
                label: mealPlan.difficultyDisplayName,
                opacity: 0.8,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.favorite,
                label: '${mealPlan.nutritionScore.toInt()}点',
                opacity: 0.7,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // const SizedBox(height: 12),

          // 信頼度表示
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: _accentColor.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '信頼度: ${(mealPlan.confidence * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _accentColor.withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required double opacity,
  }) {
    final chipColor = _primaryColor.withOpacity(opacity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _baseColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: _textColor,
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
        // 2x2の正方形ブロックグリッド（主菜、副菜、汁物、もう一品ボタン）
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: MealPlanSquareCard(
                  mealItem: _getCurrentMealItem(mealPlan, 'main'),
                  title: '主菜',
                  imageUrl: _mealImages['mainDish'],
                  onTap: () => _showMealDetail(
                      context, _getCurrentMealItem(mealPlan, 'main')!),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: MealPlanSquareCard(
                  mealItem: _getCurrentMealItem(mealPlan, 'side'),
                  title: '副菜',
                  imageUrl: _mealImages['sideDish'],
                  onTap: () => _showMealDetail(
                      context, _getCurrentMealItem(mealPlan, 'side')!),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: MealPlanSquareCard(
                  mealItem: _getCurrentMealItem(mealPlan, 'soup'),
                  title: '汁物',
                  imageUrl: _mealImages['soup'],
                  onTap: () => _showMealDetail(
                      context, _getCurrentMealItem(mealPlan, 'soup')!),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: mealPlan.additionalDish != null
                    ? MealPlanSquareCard(
                        mealItem: mealPlan.additionalDish,
                        title: _getGenreDisplayName(
                            mealPlan.additionalDish!.category),
                        imageUrl: mealPlan.additionalDish!.imageUrl,
                        onTap: () =>
                            _showMealDetail(context, mealPlan.additionalDish!),
                      )
                    : GestureDetector(
                        onTap: _showGenreSelectionDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _baseColor.withOpacity(0.3),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.4),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 32,
                                color: _primaryColor,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'もう一品',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'タップして追加',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // アクションボタン
        _buildActionButtons(mealPlan),
      ],
    );
  }

  Widget _buildActionButtons(MealPlan mealPlan) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isGeneratingImages ? null : _showReSuggestConfirmation,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textColor,
              side: BorderSide(color: _secondaryColor.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isGeneratingImages
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('作成中...'),
                    ],
                  )
                : const Text('再提案'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              print('🔘 献立決定ボタンが押されました');
              _showMealDecisionConfirmation(mealPlan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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

  Widget _buildShoppingListSection(MealPlan mealPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: _textColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '買い物リスト',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
              ),
              const Spacer(),
              if (mealPlan.estimatedTotalCost > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '概算: ${mealPlan.estimatedTotalCost.toInt()}円',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // 買い物リストアイテム
          ...mealPlan.shoppingList!.map((item) => _buildShoppingListItem(item)),
        ],
      ),
    );
  }

  Widget _buildShoppingListItem(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _secondaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_basket,
            color: _accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _textColor,
                      ),
                ),
                if (item.notes.isNotEmpty)
                  Text(
                    item.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _accentColor.withOpacity(0.8),
                        ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}${item.unit}',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
            opacity: 0.9,
            icon: Icons.warning,
          ),
          const SizedBox(height: 12),
        ],
        if (missingIngredients.isNotEmpty) ...[
          _buildIngredientSection(
            title: '買い物が必要な食材',
            ingredients: missingIngredients,
            opacity: 0.8,
            icon: Icons.shopping_cart,
          ),
          const SizedBox(height: 12),
        ],
        _buildIngredientSection(
          title: '利用可能な食材',
          ingredients: mealPlan.mainDish.ingredients
              .where((ingredient) => ingredient.available)
              .toList(),
          opacity: 0.7,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildIngredientSection({
    required String title,
    required List<Ingredient> ingredients,
    required double opacity,
    required IconData icon,
  }) {
    final sectionColor = _primaryColor.withOpacity(opacity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _baseColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: sectionColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
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
                  color: sectionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ingredient.displayName,
                  style: TextStyle(
                    color: _textColor,
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'AIが献立を作成中...',
              style: TextStyle(
                fontSize: 18,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWithMealPlan(MealPlan mealPlan) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'AIが献立画像を作成中...',
              style: TextStyle(
                fontSize: 18,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _suggestMealPlan() async {
    print('🍽️ MealPlanScreen: 献立提案ボタンが押されました');
    // TODO: 実際のhouseholdIdを取得
    const householdId = 'default_household';
    print('   世帯ID: $householdId');

    setState(() {
      _isInitialLoading = true;
    });

    try {
      // 献立を提案
      await ref
          .read(mealPlanProvider.notifier)
          .suggestMealPlan(householdId: householdId);

      // 献立が生成されたら画像を生成
      final mealPlan = ref.read(mealPlanProvider).value;
      if (mealPlan != null) {
        await _generateMealImages(mealPlan);
      }
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _generateMealImages(MealPlan mealPlan) async {
    // 即座にプレースホルダー画像を設定（主食を除く3品）
    setState(() {
      _mealImages = {
        'mainDish': null,
        'sideDish': null,
        'soup': null,
      };
      _isGeneratingImages = true;
    });

    try {
      // シンプルな画像生成APIを呼び出し
      final adkApiClient = ADKApiClient.forSimpleImageApi();

      // 並列で画像生成を実行（主食を除く3品のみ）
      final futures = [
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.mainDish.name,
          mealPlan.mainDish.description,
          180, // 3分でタイムアウト
        ),
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.sideDish.name,
          mealPlan.sideDish.description,
          180,
        ),
        _generateImageViaADKWithTimeout(
          adkApiClient,
          mealPlan.soup.name,
          mealPlan.soup.description,
          180,
        ),
      ];

      // 並列実行で結果を待つ
      final results = await Future.wait(futures);

      setState(() {
        _mealImages = {
          'mainDish': results[0],
          'sideDish': results[1],
          'soup': results[2],
        };
        _isGeneratingImages = false;
      });

      print('✅ 献立画像生成完了');
      print('   主菜画像: ${results.length > 0 ? results[0] : "null"}');
      print('   副菜画像: ${results.length > 1 ? results[1] : "null"}');
      print('   汁物画像: ${results.length > 2 ? results[2] : "null"}');
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
      final response = await adkApiClient
          .generateImage(
            prompt: '$dishName: $description',
            style: 'photorealistic',
            size: '1024x1024',
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response != null && response['image_url'] != null) {
        final imageUrl = response['image_url'] as String;
        print('✅ 画像生成完了: $dishName');
        print('   画像URL: $imageUrl');
        return imageUrl;
      } else {
        print('⚠️ 画像生成レスポンスが空: $dishName');
        return _getFallbackImageUrl(dishName);
      }
    } catch (e) {
      print('❌ 画像生成エラー（タイムアウト）: $dishName - $e');
      return _getFallbackImageUrl(dishName);
    }
  }

  /// フォールバック画像URLを取得
  String _getFallbackImageUrl(String dishName) {
    final dishLower = dishName.toLowerCase();

    // 料理タイプに応じたフォールバック画像
    if (dishLower.contains('炒め') || dishLower.contains('焼き')) {
      return 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=512&h=512&fit=crop';
    } else if (dishLower.contains('煮') || dishLower.contains('煮物')) {
      return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=512&h=512&fit=crop';
    } else if (dishLower.contains('サラダ') || dishLower.contains('野菜')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=512&h=512&fit=crop';
    } else if (dishLower.contains('汁物') ||
        dishLower.contains('スープ') ||
        dishLower.contains('味噌汁')) {
      return 'https://images.unsplash.com/photo-1547592180-85f173990554?w=512&h=512&fit=crop';
    } else if (dishLower.contains('肉') ||
        dishLower.contains('豚') ||
        dishLower.contains('鶏')) {
      return 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=512&h=512&fit=crop';
    } else if (dishLower.contains('魚') ||
        dishLower.contains('鮭') ||
        dishLower.contains('鯖')) {
      return 'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=512&h=512&fit=crop';
    } else {
      // デフォルトの料理画像
      return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=512&h=512&fit=crop';
    }
  }

  void _showSimpleConfirmation(MealPlan mealPlan) {
    print('🔘 _showSimpleConfirmation called');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('献立を決定しますか？'),
        content: Text('この献立で決定します。'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('決定'),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('献立が決定されました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMealDecisionConfirmation(MealPlan mealPlan) {
    print('🍽️ _showMealDecisionConfirmation called');

    // 使用する食材を抽出
    final allIngredients = <Ingredient>[];
    allIngredients.addAll(mealPlan.mainDish.ingredients);
    allIngredients.addAll(mealPlan.sideDish.ingredients);
    allIngredients.addAll(mealPlan.soup.ingredients);

    print('🥬 Total ingredients: ${allIngredients.length}');

    // 食材リストを文字列として作成
    final ingredientsList = allIngredients
        .map((ingredient) =>
            '• ${ingredient.name} ${ingredient.quantity ?? '適量'}')
        .join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _baseColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: _accentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'この献立で決定し，使用する食材を冷蔵庫から削除しますか？',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: _baseColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withOpacity(0.2),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: _accentColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '使用する食材：',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                constraints: BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                  ),
                ),
                padding: EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Text(
                    ingredientsList,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _accentColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'キャンセル',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '決定',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _executeMealDecision(mealPlan);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeMealDecision(MealPlan mealPlan) async {
    print('🔄 _executeMealDecision started');
    try {
      // 食材使用量減少ロジック実装
      final appState = ref.read(appStateProvider);
      print('📦 Current products count: ${appState.products.length}');
      final allIngredients = <Ingredient>[];
      allIngredients.addAll(mealPlan.mainDish.ingredients);
      allIngredients.addAll(mealPlan.sideDish.ingredients);
      allIngredients.addAll(mealPlan.soup.ingredients);

      int reducedCount = 0;

      // 冷蔵庫の商品から該当食材の数量を減らす
      for (final ingredient in allIngredients) {
        print('🔍 Processing ingredient: ${ingredient.name}');
        final matchingProducts = appState.products
            .where((product) =>
                product.name.contains(ingredient.name) ||
                ingredient.name.contains(product.name))
            .toList();

        print('   Found ${matchingProducts.length} matching products');

        for (final product in matchingProducts) {
          if (product.id != null && product.quantity > 0) {
            print(
                '   📦 Product: ${product.name}, Current quantity: ${product.quantity}');

            // 使用する量を計算（最小1、最大現在の数量）
            final usageAmount = _calculateUsageAmount(ingredient, product);
            final newQuantity =
                (product.quantity - usageAmount).clamp(0, product.quantity);

            print(
                '   📉 Usage amount: $usageAmount, New quantity: $newQuantity');

            if (newQuantity == 0) {
              // 数量が0になる場合は削除
              print('   🗑️ Deleting product (quantity = 0)');
              await ref
                  .read(appStateProvider.notifier)
                  .deleteProductFromFirebase(product.id!);
            } else {
              // 数量を減らす
              print('   📝 Updating product quantity');
              final updatedProduct = product.copyWith(quantity: newQuantity);
              await ref
                  .read(appStateProvider.notifier)
                  .updateProductInFirebase(updatedProduct);
            }
            reducedCount++;
            break; // 同じ食材は1つだけ処理
          }
        }
      }

      // 献立承認処理
      if (mealPlan.id != null) {
        await ref.read(mealPlanProvider.notifier).acceptMealPlan(mealPlan.id!);
      }

      print('✅ Meal decision completed. Reduced count: $reducedCount');

      // 成功メッセージ表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '献立が決定されました。${reducedCount}個の食材を使用しました。',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: '買い物リスト',
              textColor: Colors.black,
              backgroundColor: _accentColor.withOpacity(0.2),
              onPressed: () => _generateShoppingList(mealPlan),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _executeMealDecision: $e');
      // エラーメッセージ表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '食材の使用処理に失敗しました',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // 食材の使用量を計算するヘルパーメソッド
  int _calculateUsageAmount(Ingredient ingredient, dynamic product) {
    // レシピの分量から使用量を推定
    final quantity = ingredient.quantity?.toLowerCase() ?? '';

    if (quantity.contains('個') ||
        quantity.contains('本') ||
        quantity.contains('枚')) {
      // 個数単位の場合
      final match = RegExp(r'(\d+)').firstMatch(quantity);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 1;
      }
      return 1;
    } else if (quantity.contains('g') || quantity.contains('ml')) {
      // 重量・容量単位の場合は現在の数量の半分を使用
      return (product.quantity * 0.5).ceil().clamp(1, product.quantity);
    } else {
      // その他の場合は1個使用
      return 1;
    }
  }

  void _showReSuggestConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _baseColor,
        title: Text(
          '献立を再提案しますか？',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '現在の献立が新しい提案に置き換わります。',
          style: TextStyle(color: _accentColor),
        ),
        actions: [
          TextButton(
            child: Text('キャンセル', style: TextStyle(color: _accentColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('再提案'),
            onPressed: () {
              Navigator.of(context).pop();
              _suggestMealPlan();
            },
          ),
        ],
      ),
    );
  }

  void _showMealDetail(BuildContext context, MealItem mealItem) {
    showDialog(
      context: context,
      builder: (context) => MealDetailDialog(mealItem: mealItem),
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

  void _suggestAdditionalDish(MealPlan mealPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _baseColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'もう一品追加',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'どのような料理を追加しますか？',
                style: TextStyle(color: _accentColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              _buildDishOption(
                title: '副菜',
                subtitle: '野菜やサラダなど',
                icon: Icons.eco,
                onTap: () => _showGenreSelectionDialog(),
              ),
              SizedBox(height: 8),
              _buildDishOption(
                title: '汁物',
                subtitle: 'スープや味噌汁など',
                icon: Icons.local_drink,
                onTap: () => _showGenreSelectionDialog(),
              ),
              SizedBox(height: 8),
              _buildDishOption(
                title: 'おつまみ',
                subtitle: '簡単な一品料理',
                icon: Icons.local_bar,
                onTap: () => _showGenreSelectionDialog(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('キャンセル', style: TextStyle(color: _accentColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDishOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: _primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _accentColor, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: _accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _scrollToShoppingList() {
    final RenderBox? renderBox =
        _shoppingListKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;

      _scrollController.animateTo(
        position.dy - (screenHeight * 0.1), // 上部に少し余白
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }
}
