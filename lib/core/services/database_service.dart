import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neko_money_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ledgers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        iconPoint INTEGER,
        iconFamily TEXT,
        iconPackage TEXT,
        remark TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        iconFontPackage TEXT,
        colorValue INTEGER NOT NULL,
        type TEXT NOT NULL,
        "index" INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        initialBalance REAL NOT NULL DEFAULT 0.0,
        remark TEXT NOT NULL DEFAULT '',
        iconCodePoint INTEGER,
        iconFontFamily TEXT,
        iconFontPackage TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_history (
        id TEXT PRIMARY KEY,
        assetId TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        date INTEGER NOT NULL,
        reason TEXT NOT NULL DEFAULT 'unknown',
        relatedTransactionId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        ledgerId TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        categoryName TEXT,
        ledgerName TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        type TEXT NOT NULL,
        destinationLedgerId TEXT,
        destinationLedgerName TEXT,
        isBookmarked INTEGER NOT NULL DEFAULT 0,
        assetId TEXT,
        assetName TEXT,
        destinationAssetId TEXT,
        destinationAssetName TEXT,
        remarks TEXT,
        isReimbursement INTEGER NOT NULL DEFAULT 0,
        reimbursedAmount REAL,
        reimbursedAssetId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
