import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final proProvider = StreamNotifierProvider<ProNotifier, bool>(ProNotifier.new);

class ProNotifier extends StreamNotifier<bool> {
  @override
  Stream<bool> build() {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return Stream.value(false); // Default to free if not logged in
    }

    // Listen to the user document for 'isPro' field
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || !data.containsKey('isPro')) {
            return false;
          }
          return data['isPro'] as bool;
        });
  }

  Future<void> upgradeToPro() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isPro': true,
    }, SetOptions(merge: true));
  }

  Future<void> downgradeToFree() async {
    // For testing purposes
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isPro': false,
    }, SetOptions(merge: true));
  }
}
