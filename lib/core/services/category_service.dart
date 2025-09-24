import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// 世帯のカテゴリ一覧を取得
  Future<List<Category>> getCategories(String householdId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('householdId', isEqualTo: householdId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      // エラーの場合はデフォルトカテゴリを返す
      return _getDefaultCategories(householdId);
    }
  }

  /// 世帯のカテゴリ一覧をストリームで監視
  Stream<List<Category>> watchCategories(String householdId) {
    try {
      return _firestore
          .collection('categories')
          .where('householdId', isEqualTo: householdId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error watching categories: $e');
      // エラーの場合はデフォルトカテゴリのストリームを返す
      return Stream.value(_getDefaultCategories(householdId));
    }
  }

  /// カテゴリを追加
  Future<String> addCategory({
    required String householdId,
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    try {
      // 既存のカテゴリ数を取得してorderを設定
      final existingCategories = await getCategories(householdId);
      final order = existingCategories.length;

      final categoryId = _uuid.v4();
      final now = DateTime.now();

      final category = Category(
        id: categoryId,
        name: name,
        color: color,
        icon: icon,
        order: order,
        isDefault: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        householdId: householdId,
      );

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .set(category.toFirestore());

      return categoryId;
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('カテゴリの追加に失敗しました: $e');
    }
  }

  /// カテゴリを更新
  Future<void> updateCategory(Category category) async {
    try {
      final updatedCategory = category.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(updatedCategory.toFirestore());
    } catch (e) {
      print('Error updating category: $e');
      throw Exception('カテゴリの更新に失敗しました: $e');
    }
  }

  /// カテゴリを削除（論理削除）
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('カテゴリの削除に失敗しました: $e');
    }
  }

  /// カテゴリの並び順を更新
  Future<void> updateCategoryOrder(List<Category> categories) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final updatedCategory = category.copyWith(
          order: i,
          updatedAt: DateTime.now(),
        );

        batch.update(
          _firestore.collection('categories').doc(category.id),
          updatedCategory.toFirestore(),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Error updating category order: $e');
      throw Exception('カテゴリの並び順更新に失敗しました: $e');
    }
  }

  /// デフォルトカテゴリを初期化
  Future<void> initializeDefaultCategories(String householdId) async {
    try {
      // 既存のカテゴリがあるかチェック
      final existingCategories = await getCategories(householdId);
      if (existingCategories.isNotEmpty) {
        return; // 既にカテゴリが存在する場合は何もしない
      }

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (int i = 0; i < DefaultCategories.categories.length; i++) {
        final categoryData = DefaultCategories.categories[i];
        final categoryId = _uuid.v4();

        final category = Category(
          id: categoryId,
          name: categoryData['name'] as String,
          color: categoryData['color'] as Color,
          icon: categoryData['icon'] as IconData,
          order: categoryData['order'] as int,
          isDefault: true,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          householdId: householdId,
        );

        batch.set(
          _firestore.collection('categories').doc(categoryId),
          category.toFirestore(),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Error initializing default categories: $e');
      throw Exception('デフォルトカテゴリの初期化に失敗しました: $e');
    }
  }

  /// カテゴリ名の重複チェック
  Future<bool> isCategoryNameUnique(String householdId, String name,
      {String? excludeId}) async {
    try {
      Query query = _firestore
          .collection('categories')
          .where('householdId', isEqualTo: householdId)
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true);

      if (excludeId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking category name uniqueness: $e');
      return false;
    }
  }

  /// カテゴリの使用状況を取得
  Future<Map<String, int>> getCategoryUsage(String householdId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('householdId', isEqualTo: householdId)
          .get();

      final usage = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null) {
          usage[category] = (usage[category] ?? 0) + 1;
        }
      }

      return usage;
    } catch (e) {
      print('Error getting category usage: $e');
      return {};
    }
  }

  /// デフォルトカテゴリを取得（オフライン時用）
  List<Category> _getDefaultCategories(String householdId) {
    final now = DateTime.now();
    return DefaultCategories.categories
        .map((data) => Category(
              id: 'default_${data['name']}',
              name: data['name'] as String,
              color: data['color'] as Color,
              icon: data['icon'] as IconData,
              order: data['order'] as int,
              isDefault: true,
              isActive: true,
              createdAt: now,
              updatedAt: now,
              householdId: householdId,
            ))
        .toList();
  }
}
