import 'package:flutter/material.dart';

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
    return expiryDate!.difference(DateTime.now()).inDays;
  }
  
  String get emotionState {
    final days = daysUntilExpiry;
    if (days > 7) return '😊';
    if (days > 3) return '😐';
    if (days > 1) return '😟';
    if (days > 0) return '😰';
    return '💀';
  }
  
  Color get statusColor {
    final days = daysUntilExpiry;
    if (days > 7) return const Color(0xFF10b981);
    if (days > 3) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }
}