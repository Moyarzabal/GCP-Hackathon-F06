import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// 世帯情報を管理するプロバイダー
final userHouseholdProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('households')
      .where('members', arrayContains: user.id)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return {
      'id': doc.id,
      ...doc.data(),
    };
  });
});

// Firestoreサービスプロバイダー
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 世帯を作成
  Future<String> createHousehold(String name, String ownerId) async {
    final docRef = await _firestore.collection('households').add({
      'name': name,
      'ownerId': ownerId,
      'members': [ownerId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // 世帯に参加
  Future<void> joinHousehold(String householdId, String userId) async {
    await _firestore.collection('households').doc(householdId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // 世帯情報を取得
  Future<Map<String, dynamic>?> getHousehold(String householdId) async {
    final doc = await _firestore.collection('households').doc(householdId).get();
    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  // 招待コードで世帯を検索
  Future<Map<String, dynamic>?> findHouseholdByCode(String code) async {
    final query = await _firestore
        .collection('households')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return {
      'id': doc.id,
      ...doc.data(),
    };
  }
}
