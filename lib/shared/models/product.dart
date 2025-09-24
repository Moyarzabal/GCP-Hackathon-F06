import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 冷蔵庫の区画を表す列挙
enum FridgeCompartment {
  refrigerator,
  vegetableDrawer,
  freezer,
  doorLeft,
  doorRight,
}

/// 商品の物理配置（室/段/座標）
class ProductLocation {
  final FridgeCompartment compartment;
  final int level; // 0 = 最上段
  final Offset? position; // 0..1 の相対座標

  const ProductLocation({
    required this.compartment,
    required this.level,
    this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'compartment': compartment.name,
      'level': level,
      if (position != null) 'position': {'x': position!.dx, 'y': position!.dy},
    };
  }

  static ProductLocation? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final compartmentStr = map['compartment'] as String?;
    final level = map['level'] as int? ?? 0;
    final pos = map['position'];

    FridgeCompartment? compartment;
    if (compartmentStr != null) {
      compartment = FridgeCompartment.values.firstWhere(
        (e) => e.name == compartmentStr,
        orElse: () => FridgeCompartment.refrigerator,
      );
    } else {
      compartment = FridgeCompartment.refrigerator;
    }

    Offset? position;
    if (pos is Map) {
      final x = (pos['x'] as num?)?.toDouble();
      final y = (pos['y'] as num?)?.toDouble();
      if (x != null && y != null) {
        position = Offset(x, y);
      }
    }

    return ProductLocation(
      compartment: compartment,
      level: level,
      position: position,
    );
  }
}

/// 商品の画像段階を表す列挙型
enum ImageStage {
  veryFresh, // 7日以上
  fresh, // 3-7日
  warning, // 1-3日
  urgent, // 1日未満
  expired, // 期限切れ
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
  final ProductLocation? location;
  final DateTime? deletedAt; // 論理削除用フィールド

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
    this.location,
    this.deletedAt,
  });

  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    final difference =
        expiryDate!.difference(DateTime(now.year, now.month, now.day));
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
      if (location != null) 'location': location!.toMap(),
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  static Product fromFirestore(String id, Map<String, dynamic> data) {
    // imageUrlsの変換
    Map<ImageStage, String>? imageUrls;
    if (data['imageUrls'] != null) {
      print('🔍 Product.fromFirestore: imageUrls found for product $id');
      print('    Raw imageUrls data: ${data['imageUrls']}');
      print('    Type: ${data['imageUrls'].runtimeType}');

      final imageUrlsData = data['imageUrls'] as Map<String, dynamic>;
      imageUrls = {};
      for (final entry in imageUrlsData.entries) {
        print('    Processing entry: ${entry.key} -> ${entry.value}');
        final stage = ImageStage.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => ImageStage.veryFresh,
        );
        imageUrls[stage] = entry.value as String;
      }
      print('    Converted imageUrls: $imageUrls');
    } else {
      print('🔍 Product.fromFirestore: no imageUrls for product $id');
    }

    // Timestamp型とmillisecondsSinceEpochの両方に対応
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return Product(
      id: id,
      janCode: data['janCode'] as String?,
      name: data['name'] as String? ?? '',
      scannedAt: _parseDateTime(data['scannedAt']),
      addedDate: _parseDateTime(data['addedDate']),
      expiryDate: _parseDateTime(data['expiryDate']),
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageUrls: imageUrls,
      barcode: data['barcode'] as String?,
      manufacturer: data['manufacturer'] as String?,
      quantity: data['quantity'] as int? ?? 1,
      unit: data['unit'] as String? ?? 'piece',
      location: ProductLocation.fromMap(
        (data['location'] as Map?)?.cast<String, dynamic>(),
      ),
      deletedAt: _parseDateTime(data['deletedAt']),
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
    ProductLocation? location,
    DateTime? deletedAt,
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
      location: location ?? this.location,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
