// database_service.dart - SQLite local database management
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sheep_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sheep_farm.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Sheep table
    await db.execute('''
      CREATE TABLE sheep (
        id TEXT PRIMARY KEY,
        tagNumber TEXT NOT NULL,
        name TEXT,
        breed TEXT,
        gender TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        weight REAL,
        color TEXT,
        status TEXT DEFAULT 'Active',
        motherId TEXT,
        fatherId TEXT,
        photoPath TEXT,
        notes TEXT,
        dateAdded TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Health records table
    await db.execute('''
      CREATE TABLE health_records (
        id TEXT PRIMARY KEY,
        sheepId TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        medicine TEXT,
        dosage REAL,
        dosageUnit TEXT,
        veterinarian TEXT,
        cost REAL,
        date TEXT NOT NULL,
        nextDueDate TEXT,
        status TEXT DEFAULT 'Completed',
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (sheepId) REFERENCES sheep(id)
      )
    ''');

    // Weight records
    await db.execute('''
      CREATE TABLE weight_records (
        id TEXT PRIMARY KEY,
        sheepId TEXT NOT NULL,
        weight REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (sheepId) REFERENCES sheep(id)
      )
    ''');

    // Breeding records
    await db.execute('''
      CREATE TABLE breeding_records (
        id TEXT PRIMARY KEY,
        eweId TEXT NOT NULL,
        ramId TEXT,
        matingDate TEXT NOT NULL,
        expectedLambingDate TEXT,
        actualLambingDate TEXT,
        status TEXT DEFAULT 'Mated',
        lambsBorn INTEGER,
        lambsSurvived INTEGER,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (eweId) REFERENCES sheep(id)
      )
    ''');

    // Financial records
    await db.execute('''
      CREATE TABLE financial_records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        sheepId TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Feed records
    await db.execute('''
      CREATE TABLE feed_records (
        id TEXT PRIMARY KEY,
        feedType TEXT NOT NULL,
        quantity REAL NOT NULL,
        costPerKg REAL,
        date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ============ SHEEP CRUD ============

  Future<String> insertSheep(Sheep sheep) async {
    final db = await database;
    await db.insert('sheep', sheep.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return sheep.id;
  }

  Future<List<Sheep>> getAllSheep({String? status}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = status != null
        ? await db.query('sheep', where: 'status = ?', whereArgs: [status], orderBy: 'dateAdded DESC')
        : await db.query('sheep', orderBy: 'dateAdded DESC');
    return maps.map((m) => Sheep.fromMap(m)).toList();
  }

  Future<Sheep?> getSheepById(String id) async {
    final db = await database;
    final maps = await db.query('sheep', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Sheep.fromMap(maps.first);
  }

  Future<List<Sheep>> searchSheep(String query) async {
    final db = await database;
    final maps = await db.query(
      'sheep',
      where: 'tagNumber LIKE ? OR name LIKE ? OR breed LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((m) => Sheep.fromMap(m)).toList();
  }

  Future<int> updateSheep(Sheep sheep) async {
    final db = await database;
    return db.update('sheep', sheep.toMap(), where: 'id = ?', whereArgs: [sheep.id]);
  }

  Future<int> deleteSheep(String id) async {
    final db = await database;
    return db.delete('sheep', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getSheepStatistics() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) as females,
        SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) as males,
        SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active,
        SUM(CASE WHEN status = 'Sold' THEN 1 ELSE 0 END) as sold,
        SUM(CASE WHEN status = 'Deceased' THEN 1 ELSE 0 END) as deceased
      FROM sheep
    ''');
    final row = result.first;
    return {
      'total': (row['total'] as int?) ?? 0,
      'females': (row['females'] as int?) ?? 0,
      'males': (row['males'] as int?) ?? 0,
      'active': (row['active'] as int?) ?? 0,
      'sold': (row['sold'] as int?) ?? 0,
      'deceased': (row['deceased'] as int?) ?? 0,
    };
  }

  // ============ HEALTH RECORDS ============

  Future<String> insertHealthRecord(HealthRecord record) async {
    final db = await database;
    await db.insert('health_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<HealthRecord>> getHealthRecordsForSheep(String sheepId) async {
    final db = await database;
    final maps = await db.query(
      'health_records',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<List<HealthRecord>> getUpcomingHealthTasks() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final maps = await db.query(
      'health_records',
      where: 'nextDueDate BETWEEN ? AND ?',
      whereArgs: [now, future],
      orderBy: 'nextDueDate ASC',
    );
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<int> updateHealthRecord(HealthRecord record) async {
    final db = await database;
    return db.update('health_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteHealthRecord(String id) async {
    final db = await database;
    return db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  // ============ WEIGHT RECORDS ============

  Future<String> insertWeightRecord(WeightRecord record) async {
    final db = await database;
    await db.insert('weight_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<WeightRecord>> getWeightRecordsForSheep(String sheepId) async {
    final db = await database;
    final maps = await db.query(
      'weight_records',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date ASC',
    );
    return maps.map((m) => WeightRecord.fromMap(m)).toList();
  }

  // ============ BREEDING RECORDS ============

  Future<String> insertBreedingRecord(BreedingRecord record) async {
    final db = await database;
    await db.insert('breeding_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<BreedingRecord>> getAllBreedingRecords() async {
    final db = await database;
    final maps = await db.query('breeding_records', orderBy: 'matingDate DESC');
    return maps.map((m) => BreedingRecord.fromMap(m)).toList();
  }

  Future<List<BreedingRecord>> getBreedingRecordsForSheep(String sheepId) async {
    final db = await database;
    final maps = await db.query(
      'breeding_records',
      where: 'eweId = ? OR ramId = ?',
      whereArgs: [sheepId, sheepId],
      orderBy: 'matingDate DESC',
    );
    return maps.map((m) => BreedingRecord.fromMap(m)).toList();
  }

  Future<int> updateBreedingRecord(BreedingRecord record) async {
    final db = await database;
    return db.update('breeding_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  // ============ FINANCIAL RECORDS ============

  Future<String> insertFinancialRecord(FinancialRecord record) async {
    final db = await database;
    await db.insert('financial_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<FinancialRecord>> getAllFinancialRecords({String? type, int? limitDays}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (type != null && limitDays != null) {
      final since = DateTime.now().subtract(Duration(days: limitDays)).toIso8601String();
      whereClause = 'type = ? AND date >= ?';
      whereArgs = [type, since];
    } else if (type != null) {
      whereClause = 'type = ?';
      whereArgs = [type];
    } else if (limitDays != null) {
      final since = DateTime.now().subtract(Duration(days: limitDays)).toIso8601String();
      whereClause = 'date >= ?';
      whereArgs = [since];
    }

    final maps = await db.query(
      'financial_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((m) => FinancialRecord.fromMap(m)).toList();
  }

  Future<Map<String, double>> getFinancialSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'Income' THEN amount ELSE 0 END) as totalIncome,
        SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) as totalExpense
      FROM financial_records
    ''');
    final row = result.first;
    return {
      'income': (row['totalIncome'] as num?)?.toDouble() ?? 0.0,
      'expense': (row['totalExpense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<int> deleteFinancialRecord(String id) async {
    final db = await database;
    return db.delete('financial_records', where: 'id = ?', whereArgs: [id]);
  }

  // ============ FEED RECORDS ============

  Future<String> insertFeedRecord(FeedRecord record) async {
    final db = await database;
    await db.insert('feed_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<FeedRecord>> getAllFeedRecords() async {
    final db = await database;
    final maps = await db.query('feed_records', orderBy: 'date DESC');
    return maps.map((m) => FeedRecord.fromMap(m)).toList();
  }

  // ============ BACKUP / EXPORT ============

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'sheep': await db.query('sheep'),
      'health_records': await db.query('health_records'),
      'weight_records': await db.query('weight_records'),
      'breeding_records': await db.query('breeding_records'),
      'financial_records': await db.query('financial_records'),
      'feed_records': await db.query('feed_records'),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('sheep');
      await txn.delete('health_records');
      await txn.delete('weight_records');
      await txn.delete('breeding_records');
      await txn.delete('financial_records');
      await txn.delete('feed_records');

      // Re-insert from backup
      for (final row in (data['sheep'] as List)) {
        await txn.insert('sheep', Map<String, dynamic>.from(row));
      }
      for (final row in (data['health_records'] as List)) {
        await txn.insert('health_records', Map<String, dynamic>.from(row));
      }
      for (final row in (data['weight_records'] as List)) {
        await txn.insert('weight_records', Map<String, dynamic>.from(row));
      }
      for (final row in (data['breeding_records'] as List)) {
        await txn.insert('breeding_records', Map<String, dynamic>.from(row));
      }
      for (final row in (data['financial_records'] as List)) {
        await txn.insert('financial_records', Map<String, dynamic>.from(row));
      }
      for (final row in (data['feed_records'] as List)) {
        await txn.insert('feed_records', Map<String, dynamic>.from(row));
      }
    });
  }
}
