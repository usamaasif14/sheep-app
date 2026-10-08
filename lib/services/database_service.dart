// database_service.dart - SQLite local database
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/animal_model.dart';
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
    final path = join(dbPath, 'farm_manager.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration: add new columns if upgrading from old sheep-only db
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE sheep ADD COLUMN animalType TEXT DEFAULT "Sheep"'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN purchaseCost REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN birthLocation TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN groupOwner TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      // Create new tables added in v3
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS animals (
            id TEXT PRIMARY KEY,
            tagNumber TEXT NOT NULL,
            name TEXT,
            animalType TEXT DEFAULT 'Sheep',
            breed TEXT,
            gender TEXT NOT NULL,
            dateOfBirth TEXT NOT NULL,
            weight REAL,
            color TEXT,
            status TEXT DEFAULT 'Active',
            purchaseCost REAL,
            birthLocation TEXT,
            groupOwner TEXT,
            motherId TEXT,
            fatherId TEXT,
            photoPath TEXT,
            notes TEXT,
            dateAdded TEXT NOT NULL,
            lastUpdated TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS custom_values (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            value TEXT NOT NULL,
            UNIQUE(category, value)
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS animal_groups (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Animals (all types)
    await db.execute('''
      CREATE TABLE animals (
        id TEXT PRIMARY KEY,
        tagNumber TEXT NOT NULL,
        name TEXT,
        animalType TEXT DEFAULT 'Sheep',
        breed TEXT,
        gender TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        weight REAL,
        color TEXT,
        status TEXT DEFAULT 'Active',
        purchaseCost REAL,
        birthLocation TEXT,
        groupOwner TEXT,
        motherId TEXT,
        fatherId TEXT,
        photoPath TEXT,
        notes TEXT,
        dateAdded TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Health records
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
        createdAt TEXT NOT NULL
      )
    ''');

    // Weight records
    await db.execute('''
      CREATE TABLE weight_records (
        id TEXT PRIMARY KEY,
        sheepId TEXT NOT NULL,
        weight REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
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
        createdAt TEXT NOT NULL
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

    // Custom saved values (breeds, locations, groups, etc.)
    await db.execute('''
      CREATE TABLE custom_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        value TEXT NOT NULL,
        UNIQUE(category, value)
      )
    ''');

    // Groups / owners
    await db.execute('''
      CREATE TABLE animal_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════════════
  // ANIMALS
  // ══════════════════════════════════════════════════════════════════

  Future<String> insertAnimal(Animal animal) async {
    final db = await database;
    await db.insert('animals', animal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return animal.id;
  }

  Future<List<Animal>> getAllAnimals({String? status, String? animalType}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    if (status != null && animalType != null) {
      where = 'status = ? AND animalType = ?';
      whereArgs = [status, animalType];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    } else if (animalType != null) {
      where = 'animalType = ?';
      whereArgs = [animalType];
    }
    final maps = await db.query('animals',
        where: where, whereArgs: whereArgs, orderBy: 'dateAdded DESC');
    return maps.map((m) => Animal.fromMap(m)).toList();
  }

  Future<Animal?> getAnimalById(String id) async {
    final db = await database;
    final maps = await db.query('animals', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Animal.fromMap(maps.first);
  }

  Future<List<Animal>> getOffspring(String parentId) async {
    final db = await database;
    final maps = await db.query('animals',
        where: 'motherId = ? OR fatherId = ?',
        whereArgs: [parentId, parentId],
        orderBy: 'dateOfBirth DESC');
    return maps.map((m) => Animal.fromMap(m)).toList();
  }

  Future<int> updateAnimal(Animal animal) async {
    final db = await database;
    return db.update('animals', animal.toMap(),
        where: 'id = ?', whereArgs: [animal.id]);
  }

  Future<int> deleteAnimal(String id) async {
    final db = await database;
    return db.delete('animals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getAnimalStatistics() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) as females,
        SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) as males,
        SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active,
        SUM(CASE WHEN status = 'Sold' THEN 1 ELSE 0 END) as sold,
        SUM(CASE WHEN status = 'Deceased' THEN 1 ELSE 0 END) as deceased
      FROM animals
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

  // Keep old name for compatibility
  Future<List<Animal>> getAllSheep({String? status}) =>
      getAllAnimals(status: status);
  Future<Map<String, int>> getSheepStatistics() => getAnimalStatistics();
  Future<String> insertSheep(Animal a) => insertAnimal(a);
  Future<int> updateSheep(Animal a) => updateAnimal(a);
  Future<int> deleteSheep(String id) => deleteAnimal(id);
  Future<Animal?> getSheepById(String id) => getAnimalById(id);

  // ══════════════════════════════════════════════════════════════════
  // HEALTH RECORDS
  // ══════════════════════════════════════════════════════════════════

  Future<String> insertHealthRecord(HealthRecord record) async {
    final db = await database;
    await db.insert('health_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<HealthRecord>> getHealthRecordsForSheep(String animalId) async {
    final db = await database;
    final maps = await db.query('health_records',
        where: 'sheepId = ?', whereArgs: [animalId], orderBy: 'date DESC');
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<List<HealthRecord>> getUpcomingHealthTasks() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final future =
        DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final maps = await db.query('health_records',
        where: 'nextDueDate BETWEEN ? AND ?',
        whereArgs: [now, future],
        orderBy: 'nextDueDate ASC');
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<int> deleteHealthRecord(String id) async {
    final db = await database;
    return db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════
  // WEIGHT RECORDS
  // ══════════════════════════════════════════════════════════════════

  Future<String> insertWeightRecord(WeightRecord record) async {
    final db = await database;
    await db.insert('weight_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<WeightRecord>> getWeightRecordsForSheep(String animalId) async {
    final db = await database;
    final maps = await db.query('weight_records',
        where: 'sheepId = ?', whereArgs: [animalId], orderBy: 'date ASC');
    return maps.map((m) => WeightRecord.fromMap(m)).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // BREEDING RECORDS
  // ══════════════════════════════════════════════════════════════════

  Future<String> insertBreedingRecord(BreedingRecord record) async {
    final db = await database;
    await db.insert('breeding_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<BreedingRecord>> getAllBreedingRecords() async {
    final db = await database;
    final maps =
        await db.query('breeding_records', orderBy: 'matingDate DESC');
    return maps.map((m) => BreedingRecord.fromMap(m)).toList();
  }

  Future<List<BreedingRecord>> getBreedingRecordsForSheep(
      String animalId) async {
    final db = await database;
    final maps = await db.query('breeding_records',
        where: 'eweId = ? OR ramId = ?',
        whereArgs: [animalId, animalId],
        orderBy: 'matingDate DESC');
    return maps.map((m) => BreedingRecord.fromMap(m)).toList();
  }

  Future<int> updateBreedingRecord(BreedingRecord record) async {
    final db = await database;
    return db.update('breeding_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  // ══════════════════════════════════════════════════════════════════
  // FINANCIAL RECORDS
  // ══════════════════════════════════════════════════════════════════

  Future<String> insertFinancialRecord(FinancialRecord record) async {
    final db = await database;
    await db.insert('financial_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<FinancialRecord>> getAllFinancialRecords(
      {String? type, int? limitDays}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (type != null && limitDays != null) {
      final since = DateTime.now()
          .subtract(Duration(days: limitDays))
          .toIso8601String();
      where = 'type = ? AND date >= ?';
      args = [type, since];
    } else if (type != null) {
      where = 'type = ?';
      args = [type];
    } else if (limitDays != null) {
      final since = DateTime.now()
          .subtract(Duration(days: limitDays))
          .toIso8601String();
      where = 'date >= ?';
      args = [since];
    }
    final maps = await db.query('financial_records',
        where: where, whereArgs: args, orderBy: 'date DESC');
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
      'income': ((row['totalIncome'] as num?) ?? 0.0).toDouble(),
      'expense': ((row['totalExpense'] as num?) ?? 0.0).toDouble(),
    };
  }

  Future<int> deleteFinancialRecord(String id) async {
    final db = await database;
    return db.delete('financial_records', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════
  // CUSTOM SAVED VALUES (breeds, locations, groups per animal type)
  // ══════════════════════════════════════════════════════════════════

  Future<void> saveCustomValue(String category, String value) async {
    if (value.trim().isEmpty) return;
    final db = await database;
    await db.insert(
      'custom_values',
      {'category': category.toLowerCase(), 'value': value.trim()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getCustomValues(String category) async {
    final db = await database;
    final maps = await db.query('custom_values',
        where: 'category = ?',
        whereArgs: [category.toLowerCase()],
        orderBy: 'value ASC');
    return maps.map((m) => m['value'] as String).toList();
  }

  Future<void> deleteCustomValue(String category, String value) async {
    final db = await database;
    await db.delete('custom_values',
        where: 'category = ? AND value = ?',
        whereArgs: [category.toLowerCase(), value]);
  }

  // ══════════════════════════════════════════════════════════════════
  // GROUPS / OWNERS
  // ══════════════════════════════════════════════════════════════════

  Future<void> insertGroup(AnimalGroup group) async {
    final db = await database;
    await db.insert('animal_groups', group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AnimalGroup>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('animal_groups', orderBy: 'name ASC');
    return maps.map((m) => AnimalGroup.fromMap(m)).toList();
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete('animal_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════
  // BACKUP / EXPORT
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'animals': await db.query('animals'),
      'health_records': await db.query('health_records'),
      'weight_records': await db.query('weight_records'),
      'breeding_records': await db.query('breeding_records'),
      'financial_records': await db.query('financial_records'),
      'animal_groups': await db.query('animal_groups'),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '2.0.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('animals');
      await txn.delete('health_records');
      await txn.delete('weight_records');
      await txn.delete('breeding_records');
      await txn.delete('financial_records');

      for (final row in (data['animals'] as List? ?? data['sheep'] as List? ?? [])) {
        await txn.insert('animals', Map<String, dynamic>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['health_records'] as List? ?? [])) {
        await txn.insert('health_records', Map<String, dynamic>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['weight_records'] as List? ?? [])) {
        await txn.insert('weight_records', Map<String, dynamic>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['breeding_records'] as List? ?? [])) {
        await txn.insert('breeding_records', Map<String, dynamic>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['financial_records'] as List? ?? [])) {
        await txn.insert('financial_records', Map<String, dynamic>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
