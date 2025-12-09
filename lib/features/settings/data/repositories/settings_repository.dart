import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> getCurrency(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('global')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['currency'] as String?;
      }
      return null;
    } catch (e) {
      // Return null on error, provider will fallback
      return null;
    }
  }

  Future<void> setCurrency(String userId, String symbol) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('global')
        .set({'currency': symbol}, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getSettingsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> updateSettings(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .set(data, SetOptions(merge: true));
  }
}
