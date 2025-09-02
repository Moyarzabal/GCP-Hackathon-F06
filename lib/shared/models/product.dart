import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.barcode,
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
      'quantity': quantity,
      'unit': unit,
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
    String? barcode,
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
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}