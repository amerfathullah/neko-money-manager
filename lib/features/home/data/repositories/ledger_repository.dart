import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ledger.dart';

class LedgerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ledgers';

  Stream<List<Ledger>> getLedgers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Ledger.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> addLedger(String userId, Ledger ledger) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .doc(ledger.id)
        .set(ledger.toJson());
  }

  Future<void> updateLedger(String userId, Ledger ledger) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .doc(ledger.id)
        .update(ledger.toJson());
  }

  Future<void> deleteLedger(String userId, String ledgerId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .doc(ledgerId)
        .delete();
  }
}
