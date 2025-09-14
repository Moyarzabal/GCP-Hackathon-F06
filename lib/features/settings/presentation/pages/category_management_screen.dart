import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/category.dart';
import '../../../../core/services/category_service.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../widgets/category_edit_dialog.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  Map<String, int> _categoryUsage = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final appState = ref.read(appStateProvider);
      final householdId = appState.currentHouseholdId;
      
      if (householdId == null) {
        throw Exception('世帯IDが取得できません');
      }

      // カテゴリ一覧を取得
      final categories = await _categoryService.getCategories(householdId);
      
      // カテゴリの使用状況を取得
      final usage = await _categoryService.getCategoryUsage(householdId);

      setState(() {
        _categories = categories;
        _categoryUsage = usage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリ管理'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: 'カテゴリを追加',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'カテゴリがありません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'カテゴリを追加して商品を整理しましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: const Text('カテゴリを追加'),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final usageCount = _categoryUsage[category.name] ?? 0;
        
        return _buildCategoryCard(category, usageCount, index);
      },
    );
  }

  Widget _buildCategoryCard(Category category, int usageCount, int index) {
    return Card(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: category.color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            category.icon,
            color: category.color,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$usageCount件の商品',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // デフォルトカテゴリの場合は削除ボタンを非表示
            if (!category.isDefault) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditCategoryDialog(category),
                tooltip: '編集',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _showDeleteCategoryDialog(category),
                tooltip: '削除',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'デフォルト',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.drag_handle,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // 並び順を更新
    _updateCategoryOrder();
  }

  Future<void> _updateCategoryOrder() async {
    try {
      final appState = ref.read(appStateProvider);
      final householdId = appState.currentHouseholdId;
      
      if (householdId != null) {
        await _categoryService.updateCategoryOrder(_categories);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('並び順の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        onSave: _addCategory,
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: _updateCategory,
      ),
    );
  }

  Future<void> _addCategory(String name, Color color, IconData icon) async {
    try {
      final appState = ref.read(appStateProvider);
      final householdId = appState.currentHouseholdId;
      
      if (householdId == null) {
        throw Exception('世帯IDが取得できません');
      }

      // カテゴリ名の重複チェック
      final isUnique = await _categoryService.isCategoryNameUnique(householdId, name);
      if (!isUnique) {
        throw Exception('このカテゴリ名は既に使用されています');
      }

      await _categoryService.addCategory(
        householdId: householdId,
        name: name,
        color: color,
        icon: icon,
      );

      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カテゴリを追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カテゴリの追加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory(String name, Color color, IconData icon) async {
    try {
      final appState = ref.read(appStateProvider);
      final householdId = appState.currentHouseholdId;
      
      if (householdId == null) {
        throw Exception('世帯IDが取得できません');
      }

      // カテゴリ名の重複チェック（自分自身は除外）
      final isUnique = await _categoryService.isCategoryNameUnique(
        householdId, 
        name, 
        excludeId: _categories.firstWhere((c) => c.name == name).id,
      );
      if (!isUnique) {
        throw Exception('このカテゴリ名は既に使用されています');
      }

      final updatedCategory = _categories.firstWhere((c) => c.name == name).copyWith(
        name: name,
        color: color,
        icon: icon,
      );

      await _categoryService.updateCategory(updatedCategory);
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カテゴリを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カテゴリの更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteCategoryDialog(Category category) {
    final usageCount = _categoryUsage[category.name] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリを削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${category.name}」を削除しますか？'),
            if (usageCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'このカテゴリには$usageCount件の商品が登録されています。',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '削除後、これらの商品は「その他」カテゴリに移動されます。',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryService.deleteCategory(category.id);
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カテゴリを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カテゴリの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
