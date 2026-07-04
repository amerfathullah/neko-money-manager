import '../../../../core/services/database_service.dart';
import '../models/ledger.dart';

class LedgerRepository {
  Future<List<Ledger>> getLedgers() async {
    final db = await DatabaseService.database;
    final maps = await db.query('ledgers');
    return maps.map((m) => Ledger.fromJson(m)).toList();
  }

  Future<void> addLedger(Ledger ledger) async {
    final db = await DatabaseService.database;
    await db.insert('ledgers', ledger.toJson());
  }

  Future<void> updateLedger(Ledger ledger) async {
    final db = await DatabaseService.database;
    await db.update('ledgers', ledger.toJson(), where: 'id = ?', whereArgs: [ledger.id]);
  }

  Future<void> deleteLedger(String ledgerId) async {
    final db = await DatabaseService.database;
    await db.delete('ledgers', where: 'id = ?', whereArgs: [ledgerId]);
  }
}
