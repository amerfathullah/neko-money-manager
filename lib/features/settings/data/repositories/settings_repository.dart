import 'package:sqflite/sqflite.dart';
import '../../../../core/services/database_service.dart';

class SettingsRepository {
  Future<String?> getCurrency() async {
    final db = await DatabaseService.database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: ['currency']);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setCurrency(String symbol) async {
    final db = await DatabaseService.database;
    await db.insert(
      'settings',
      {'key': 'currency', 'value': symbol},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await DatabaseService.database;
    final maps = await db.query('settings');
    final result = <String, dynamic>{};
    for (final row in maps) {
      final key = row['key'] as String;
      final value = row['value'] as String;
      // Parse known settings
      if (key == 'monthlyStartDate' || key == 'firstDayOfWeek') {
        result[key] = int.tryParse(value);
      } else if (key == 'useCommaSeparator') {
        result[key] = value == 'true';
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    final batch = db.batch();
    for (final entry in data.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
