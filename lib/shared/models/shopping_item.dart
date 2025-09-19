import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 買い物アイテムのモデル
class ShoppingItem {
  final String? id;
  final String name;
  final String quantity;
  final String unit;
  final String category;
  final bool isCompleted;
  final bool isCustom;
  final String addedBy;
  final DateTime addedAt;
  final DateTime? completedAt;
  final String notes;
  final double? estimatedPrice;

  ShoppingItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isCompleted = false,
    this.isCustom = false,
    required this.addedBy,
    required this.addedAt,
    this.completedAt,
    this.notes = '',
    this.estimatedPrice,
  });

  /// 緊急度（カスタムアイテムは緊急度低）
  bool get isUrgent => !isCustom;

  /// 表示名（数量込み）
  String get displayName {
    return '$name $quantity$unit';
  }

  /// カテゴリのアイコン
  IconData get categoryIcon {
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

  /// カテゴリの色
  Color get categoryColor {
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

  /// 完了状態の表示名
  String get statusDisplayName {
    return isCompleted ? '完了' : '未完了';
  }

  /// 完了状態の色
  Color get statusColor {
    return isCompleted ? Colors.green : Colors.grey;
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'isCompleted': isCompleted,
      'isCustom': isCustom,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'estimatedPrice': estimatedPrice,
    };
  }

  static ShoppingItem fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      unit: data['unit'] as String,
      category: data['category'] as String,
      isCompleted: data['isCompleted'] as bool? ?? false,
      isCustom: data['isCustom'] as bool? ?? false,
      addedBy: data['addedBy'] as String,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String? ?? '',
      estimatedPrice: data['estimatedPrice'] as double?,
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? category,
    bool? isCompleted,
    bool? isCustom,
    String? addedBy,
    DateTime? addedAt,
    DateTime? completedAt,
    String? notes,
    double? estimatedPrice,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustom: isCustom ?? this.isCustom,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }
}

/// 買い物リストのモデル
class ShoppingList {
  final String? id;
  final String householdId;
  final String? mealPlanId;
  final List<ShoppingItem> items;
  final ShoppingListStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? totalEstimatedPrice;

  ShoppingList({
    this.id,
    required this.householdId,
    this.mealPlanId,
    required this.items,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.totalEstimatedPrice,
  });

  /// 完了したアイテムの数
  int get completedItemCount {
    return items.where((item) => item.isCompleted).length;
  }

  /// 未完了のアイテムの数
  int get pendingItemCount {
    return items.where((item) => !item.isCompleted).length;
  }

  /// 完了率（0.0-1.0）
  double get completionRate {
    if (items.isEmpty) return 0.0;
    return completedItemCount / items.length;
  }

  /// 完了率の表示（パーセント）
  String get completionRateDisplay {
    return '${(completionRate * 100).toInt()}%';
  }

  /// 状態の表示名
  String get statusDisplayName {
    switch (status) {
      case ShoppingListStatus.active:
        return 'アクティブ';
      case ShoppingListStatus.completed:
        return '完了';
      case ShoppingListStatus.cancelled:
        return 'キャンセル';
    }
  }

  /// 状態の色
  Color get statusColor {
    switch (status) {
      case ShoppingListStatus.active:
        return Colors.blue;
      case ShoppingListStatus.completed:
        return Colors.green;
      case ShoppingListStatus.cancelled:
        return Colors.red;
    }
  }

  /// カテゴリ別にグループ化されたアイテム
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  /// 未完了のアイテムをカテゴリ別にグループ化
  Map<String, List<ShoppingItem>> get pendingItemsByCategory {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items.where((item) => !item.isCompleted)) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'mealPlanId': mealPlanId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'totalEstimatedPrice': totalEstimatedPrice,
    };
  }

  static ShoppingList fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingList(
      id: id,
      householdId: data['householdId'] as String,
      mealPlanId: data['mealPlanId'] as String?,
      items: (data['items'] as List<dynamic>)
          .map((item) => ShoppingItem.fromFirestore('', item as Map<String, dynamic>))
          .toList(),
      status: ShoppingListStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ShoppingListStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      totalEstimatedPrice: data['totalEstimatedPrice'] as double?,
    );
  }

  ShoppingList copyWith({
    String? id,
    String? householdId,
    String? mealPlanId,
    List<ShoppingItem>? items,
    ShoppingListStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    double? totalEstimatedPrice,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      mealPlanId: mealPlanId ?? this.mealPlanId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      totalEstimatedPrice: totalEstimatedPrice ?? this.totalEstimatedPrice,
    );
  }
}

/// 買い物リストの状態を表す列挙型
enum ShoppingListStatus {
  active,      // アクティブ
  completed,   // 完了
  cancelled,   // キャンセル
}

