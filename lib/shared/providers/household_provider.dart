import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userHouseholdProvider = StreamProvider<DocumentSnapshot?>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await for (final snapshot in userDoc.snapshots()) {
    if (snapshot.exists && snapshot.data()?['householdId'] != null) {
      final householdId = snapshot.data()!['householdId'];
      final householdDoc = FirebaseFirestore.instance
          .collection('households')
          .doc(householdId);
      await for (final householdSnapshot in householdDoc.snapshots()) {
        yield householdSnapshot;
      }
    } else {
      yield null;
    }
  }
});

final householdProductsProvider = StreamProvider<QuerySnapshot>((ref) {
  final household = ref.watch(userHouseholdProvider);
  final householdData = household.asData?.value;
  
  if (householdData == null || !householdData.exists) {
    return FirebaseFirestore.instance
        .collection('items')
        .limit(0)
        .snapshots();
  }

  final householdId = householdData.id;
  return ref.watch(firestoreServiceProvider).getHouseholdProducts(householdId);
});

final expiringProductsProvider = StreamProvider.family<QuerySnapshot, int>(
  (ref, daysAhead) {
    final household = ref.watch(userHouseholdProvider);
    final householdData = household.asData?.value;
    
    if (householdData == null || !householdData.exists) {
      return FirebaseFirestore.instance
          .collection('items')
          .limit(0)
          .snapshots();
    }

    final householdId = householdData.id;
    return ref
        .watch(firestoreServiceProvider)
        .getExpiringProducts(householdId, daysAhead);
  },
);