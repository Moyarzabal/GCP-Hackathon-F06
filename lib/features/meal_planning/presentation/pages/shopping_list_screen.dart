import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/shopping_item.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/shopping_item_card.dart';
import '../widgets/add_item_dialog.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '買い物リスト',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
            tooltip: 'アイテムを追加',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _clearCompletedItems(),
            tooltip: '完了したアイテムをクリア',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: '未完了',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: '完了',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingItemsTab(shoppingListAsync),
          _buildCompletedItemsTab(shoppingListAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('アイテム追加'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPendingItemsTab(
      AsyncValue<List<ShoppingItem>> shoppingListAsync) {
    return shoppingListAsync.when(
      data: (items) {
        final pendingItems = items.where((item) => !item.isCompleted).toList();
        return _buildItemsList(pendingItems, showCompleted: false);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildCompletedItemsTab(
      AsyncValue<List<ShoppingItem>> shoppingListAsync) {
    return shoppingListAsync.when(
      data: (items) {
        final completedItems = items.where((item) => item.isCompleted).toList();
        return _buildItemsList(completedItems, showCompleted: true);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildItemsList(List<ShoppingItem> items,
      {required bool showCompleted}) {
    if (items.isEmpty) {
      return _buildEmptyState(showCompleted);
    }

    // カテゴリ別にグループ化
    final itemsByCategory = <String, List<ShoppingItem>>{};
    for (final item in items) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サマリー情報
          _buildSummaryCard(items),

          const SizedBox(height: 20),

          // カテゴリ別リスト
          ...itemsByCategory.entries.map((entry) {
            final category = entry.key;
            final categoryItems = entry.value;

            return _buildCategorySection(
                category, categoryItems, showCompleted);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<ShoppingItem> items) {
    final totalItems = items.length;
    final completedItems = items.where((item) => item.isCompleted).length;
    final completionRate = totalItems > 0 ? (completedItems / totalItems) : 0.0;
    final estimatedPrice =
        items.fold(0.0, (sum, item) => sum + (item.estimatedPrice ?? 0.0));

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
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '買い物リスト',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryChip(
                icon: Icons.list_alt,
                label: '総アイテム数',
                value: totalItems.toString(),
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildSummaryChip(
                icon: Icons.check_circle,
                label: '完了率',
                value: '${(completionRate * 100).toInt()}%',
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              if (estimatedPrice > 0)
                _buildSummaryChip(
                  icon: Icons.attach_money,
                  label: '予想金額',
                  value: '¥${estimatedPrice.toInt()}',
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      String category, List<ShoppingItem> items, bool showCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getCategoryColor(category).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: _getCategoryColor(category),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}個',
                  style: TextStyle(
                    color: _getCategoryColor(category),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // アイテムリスト
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShoppingItemCard(
                  item: item,
                  onToggle: () => _toggleItemStatus(item),
                  onEdit: () => _editItem(item),
                  onDelete: () => _deleteItem(item),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool showCompleted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showCompleted
                ? Icons.check_circle_outline
                : Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            showCompleted ? '完了したアイテムはありません' : '買い物リストが空です',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showCompleted ? 'アイテムを完了するとここに表示されます' : '献立を承認するか、手動でアイテムを追加してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (!showCompleted) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('アイテムを追加'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('買い物リストを読み込み中...'),
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
            onPressed: () => _refreshShoppingList(),
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

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAddItem: (name, quantity, unit, category) {
          ref.read(shoppingListProvider.notifier).addCustomItem(
                name: name,
                quantity: quantity,
                unit: unit,
                category: category,
                addedBy: 'user', // TODO: 実際のユーザーIDを取得
              );
        },
      ),
    );
  }

  void _toggleItemStatus(ShoppingItem item) {
    if (item.id != null) {
      ref.read(shoppingListProvider.notifier).toggleItemStatus(item.id!);
    }
  }

  void _editItem(ShoppingItem item) {
    // TODO: アイテム編集ダイアログを実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('アイテム編集機能は準備中です'),
      ),
    );
  }

  void _deleteItem(ShoppingItem item) {
    if (item.id != null) {
      ref.read(shoppingListProvider.notifier).deleteItem(item.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name}を削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () {
              // TODO: 元に戻す機能を実装
            },
          ),
        ),
      );
    }
  }

  void _clearCompletedItems() {
    ref.read(shoppingListProvider.notifier).clearCompletedItems();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('完了したアイテムをクリアしました'),
      ),
    );
  }

  void _refreshShoppingList() {
    // TODO: 買い物リストを再読み込み
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('買い物リストを更新しました'),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case '野菜':
      case 'vegetables':
        return Colors.green;
      case '肉':
      case 'meat':
        return Colors.red;
      case '魚':
      case 'fish':
        return Colors.blue;
      case '乳製品':
      case 'dairy':
        return Colors.yellow;
      case '調味料':
      case 'seasonings':
        return Colors.orange;
      case '主食':
      case 'staple':
        return Colors.brown;
      case '果物':
      case 'fruits':
        return Colors.pink;
      case '飲み物':
      case 'beverages':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case '野菜':
      case 'vegetables':
        return Icons.eco;
      case '肉':
      case 'meat':
        return Icons.restaurant;
      case '魚':
      case 'fish':
        return Icons.set_meal;
      case '乳製品':
      case 'dairy':
        return Icons.local_drink;
      case '調味料':
      case 'seasonings':
        return Icons.local_dining;
      case '主食':
      case 'staple':
        return Icons.grain;
      case '果物':
      case 'fruits':
        return Icons.apple;
      case '飲み物':
      case 'beverages':
        return Icons.local_cafe;
      default:
        return Icons.shopping_cart;
    }
  }
}
