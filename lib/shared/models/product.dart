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

class Product {
  final String? id;
  final String? janCode;
  final String name;
  final DateTime? scannedAt;
  final DateTime? addedDate;
  final DateTime? expiryDate;
  final String category;
  final String? imageUrl;
  final String? barcode;
  final String? manufacturer;
  final int quantity;
  final String unit;
  final ProductLocation? location;
  
  Product({
    this.id,
    this.janCode,
    required this.name,
    this.scannedAt,
    this.addedDate,
    this.expiryDate,
    required this.category,
    this.imageUrl,
    this.barcode,
    this.manufacturer,
    this.quantity = 1,
    this.unit = 'piece',
    this.location,
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
      'barcode': barcode,
      'manufacturer': manufacturer,
      'quantity': quantity,
      'unit': unit,
      if (location != null) 'location': location!.toMap(),
    };
  }

  static Product fromFirestore(String id, Map<String, dynamic> data) {
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
      barcode: data['barcode'] as String?,
      manufacturer: data['manufacturer'] as String?,
      quantity: data['quantity'] as int? ?? 1,
      unit: data['unit'] as String? ?? 'piece',
      location: ProductLocation.fromMap(
        (data['location'] as Map?)?.cast<String, dynamic>(),
      ),
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
    String? barcode,
    String? manufacturer,
    int? quantity,
    String? unit,
    ProductLocation? location,
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
      barcode: barcode ?? this.barcode,
      manufacturer: manufacturer ?? this.manufacturer,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
    );
  }
}