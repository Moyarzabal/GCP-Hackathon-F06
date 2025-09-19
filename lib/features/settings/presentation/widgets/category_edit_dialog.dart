import 'package:flutter/material.dart';
import '../../../../shared/models/category.dart';
import 'category_color_picker.dart';
import 'category_icon_picker.dart';

class CategoryEditDialog extends StatefulWidget {
  final Category? category;
  final Function(String name, Color color, IconData icon) onSave;

  const CategoryEditDialog({
    Key? key,
    this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      _nameController = TextEditingController(text: widget.category!.name);
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    } else {
      _nameController = TextEditingController();
      _selectedColor = Colors.grey;
      _selectedIcon = Icons.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category != null ? 'カテゴリを編集' : 'カテゴリを追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // カテゴリ名入力
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'カテゴリ名',
                hintText: '例: 野菜、果物、肉類',
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 16),

            // 色選択
            Text(
              '色を選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CategoryColorPicker(
              selectedColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 16),

            // アイコン選択
            Text(
              'アイコンを選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CategoryIconPicker(
              selectedIcon: _selectedIcon,
              onIconChanged: (icon) {
                setState(() {
                  _selectedIcon = icon;
                });
              },
            ),
            const SizedBox(height: 16),

            // プレビュー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedIcon,
                    color: _selectedColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _nameController.text.isEmpty ? 'カテゴリ名' : _nameController.text,
                    style: TextStyle(
                      color: _selectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.category != null ? '更新' : '追加'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリ名を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(name, _selectedColor, _selectedIcon);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

