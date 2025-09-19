import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final int order;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String householdId;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.order,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.householdId,
  });

  /// カテゴリのコピーを作成（一部フィールドを変更）
  Category copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    int? order,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? householdId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      householdId: householdId ?? this.householdId,
    );
  }

  /// Firestoreからカテゴリを作成
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: data['categoryId'] as String,
      name: data['name'] as String,
      color: _parseColor(data['color'] as String?),
      icon: _parseIcon(data['icon'] as String?),
      order: data['order'] as int? ?? 0,
      isDefault: data['isDefault'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      householdId: data['householdId'] as String,
    );
  }

  /// Firestore用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': id,
      'householdId': householdId,
      'name': name,
      'color': _colorToHex(color),
      'icon': _iconToName(icon),
      'order': order,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 色を16進数文字列に変換
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  /// 16進数文字列から色を解析
  static Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.grey;
    }

    try {
      // #を除去して16進数として解析
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// アイコン名からIconDataを解析
  static IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.category;
    }

    // アイコン名からIconDataを取得
    switch (iconName) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'meat':
        return Icons.restaurant;
      case 'seafood':
        return Icons.set_meal;
      case 'dairy':
        return Icons.local_drink;
      case 'grains':
        return Icons.grain;
      case 'beverages':
        return Icons.local_bar;
      case 'food':
        return Icons.fastfood;
      case 'seasoning':
        return Icons.kitchen;
      case 'frozen':
        return Icons.ac_unit;
      case 'other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  /// IconDataからアイコン名を取得
  static String _iconToName(IconData icon) {
    if (icon == Icons.eco) return 'vegetables';
    if (icon == Icons.apple) return 'fruits';
    if (icon == Icons.restaurant) return 'meat';
    if (icon == Icons.set_meal) return 'seafood';
    if (icon == Icons.local_drink) return 'dairy';
    if (icon == Icons.grain) return 'grains';
    if (icon == Icons.local_bar) return 'beverages';
    if (icon == Icons.fastfood) return 'food';
    if (icon == Icons.kitchen) return 'seasoning';
    if (icon == Icons.ac_unit) return 'frozen';
    return 'other';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color, icon: $icon, order: $order)';
  }
}

/// デフォルトカテゴリの定義
class DefaultCategories {
  static const List<Map<String, dynamic>> categories = [
    {
      'name': '野菜',
      'color': Colors.green,
      'icon': Icons.eco,
      'order': 0,
    },
    {
      'name': '果物',
      'color': Colors.orange,
      'icon': Icons.apple,
      'order': 1,
    },
    {
      'name': '肉類',
      'color': Colors.red,
      'icon': Icons.restaurant,
      'order': 2,
    },
    {
      'name': '魚介類',
      'color': Colors.blue,
      'icon': Icons.set_meal,
      'order': 3,
    },
    {
      'name': '乳製品',
      'color': Colors.white,
      'icon': Icons.local_drink,
      'order': 4,
    },
    {
      'name': '穀物',
      'color': Colors.brown,
      'icon': Icons.grain,
      'order': 5,
    },
    {
      'name': '飲料',
      'color': Colors.cyan,
      'icon': Icons.local_bar,
      'order': 6,
    },
    {
      'name': '食品',
      'color': Colors.purple,
      'icon': Icons.fastfood,
      'order': 7,
    },
    {
      'name': '調味料',
      'color': Colors.amber,
      'icon': Icons.kitchen,
      'order': 8,
    },
    {
      'name': '冷凍食品',
      'color': Colors.lightBlue,
      'icon': Icons.ac_unit,
      'order': 9,
    },
    {
      'name': 'その他',
      'color': Colors.grey,
      'icon': Icons.category,
      'order': 10,
    },
  ];
}

