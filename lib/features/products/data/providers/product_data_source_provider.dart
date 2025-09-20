import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datasources/product_datasource.dart';
import '../datasources/firestore_product_datasource.dart';

/// ProductDataSourceプロバイダー
final productDataSourceProvider = Provider<ProductDataSource>((ref) {
  final firestore = FirebaseFirestore.instance;
  return FirestoreProductDataSource(firestore);
});
