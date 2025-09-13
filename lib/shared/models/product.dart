import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 商品の画像段階を表す列挙型
enum ImageStage {
  veryFresh,    // 7日以上
  fresh,        // 3-7日
  warning,      // 1-3日
  urgent,       // 1日未満
  expired,      // 期限切れ
}

class Product {
  final String? id;
  final String? janCode;
  final String name;
  final DateTime? scannedAt;
  final DateTime? addedDate;
  final DateTime? expiryDate;
  final String category;
  final String? imageUrl; // 後方互換性のため残す
  final Map<ImageStage, String>? imageUrls; // 各段階の画像URL
  final String? barcode;
  final String? manufacturer;
  final int quantity;
  final String unit;
  
  Product({
    this.id,
    this.janCode,
    required this.name,
    this.scannedAt,
    this.addedDate,
    this.expiryDate,
    required this.category,
    this.imageUrl,
    this.imageUrls,
    this.barcode,
    this.manufacturer,
    this.quantity = 1,
    this.unit = 'piece',
  });
  
  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    final difference = expiryDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }
  
  String get emotionState {
    final days = daysUntilExpiry;
    if (days > 7) return '😊';
    if (days > 3) return '😐';
    if (days > 1) return '😟';
    if (days >= 1) return '😰';
    return '💀';
  }

  /// 現在の残り日数に応じた画像段階を取得
  ImageStage get currentImageStage {
    final days = daysUntilExpiry;
    if (days > 7) return ImageStage.veryFresh;
    if (days > 3) return ImageStage.fresh;
    if (days > 1) return ImageStage.warning;
    if (days >= 1) return ImageStage.urgent;
    return ImageStage.expired;
  }

  /// 現在の残り日数に応じた画像URLを取得
  String? get currentImageUrl {
    // 新しい複数画像システムを優先
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      final stage = currentImageStage;
      return imageUrls![stage];
    }
    // 後方互換性のため既存のimageUrlも使用
    return imageUrl;
  }
  
  Color get statusColor {
    final days = daysUntilExpiry;
    if (days > 7) return const Color(0xFF10b981);
    if (days > 3) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'janCode': janCode,
      'name': name,
      'scannedAt': scannedAt?.millisecondsSinceEpoch,
      'addedDate': addedDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'category': category,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls?.map((key, value) => MapEntry(key.name, value)),
      'barcode': barcode,
      'manufacturer': manufacturer,
      'quantity': quantity,
      'unit': unit,
    };
  }

  static Product fromFirestore(String id, Map<String, dynamic> data) {
    // imageUrlsの変換
    Map<ImageStage, String>? imageUrls;
    if (data['imageUrls'] != null) {
      final imageUrlsData = data['imageUrls'] as Map<String, dynamic>;
      imageUrls = {};
      for (final entry in imageUrlsData.entries) {
        final stage = ImageStage.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => ImageStage.veryFresh,
        );
        imageUrls[stage] = entry.value as String;
      }
    }

    return Product(
      id: id,
      janCode: data['janCode'] as String?,
      name: data['name'] as String? ?? '',
      scannedAt: data['scannedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['scannedAt'] as int)
          : null,
      addedDate: data['addedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['addedDate'] as int)
          : null,
      expiryDate: data['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['expiryDate'] as int)
          : null,
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageUrls: imageUrls,
      barcode: data['barcode'] as String?,
      manufacturer: data['manufacturer'] as String?,
      quantity: data['quantity'] as int? ?? 1,
      unit: data['unit'] as String? ?? 'piece',
    );
  }

  Product copyWith({
    String? id,
    String? janCode,
    String? name,
    DateTime? scannedAt,
    DateTime? addedDate,
    DateTime? expiryDate,
    String? category,
    String? imageUrl,
    Map<ImageStage, String>? imageUrls,
    String? barcode,
    String? manufacturer,
    int? quantity,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      janCode: janCode ?? this.janCode,
      name: name ?? this.name,
      scannedAt: scannedAt ?? this.scannedAt,
      addedDate: addedDate ?? this.addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      barcode: barcode ?? this.barcode,
      manufacturer: manufacturer ?? this.manufacturer,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}