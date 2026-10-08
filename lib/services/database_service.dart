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
    return openDatabase(path, version: 4, onCreate: _createTables, onUpgrade: _onUpgrade, onOpen: _ensureColumns);
  }

  // Called every time DB is opened — ensures all columns exist regardless of migration history
  Future<void> _ensureColumns(Database db) async {
    final cols = ['animalType TEXT DEFAULT \'Sheep\'', 'purchaseCost REAL',
      'birthLocation TEXT', 'groupOwner TEXT', 'ownershipType TEXT DEFAULT \'Personal\'',
      'partnerName TEXT', 'motherId TEXT', 'motherName TEXT', 'fatherId TEXT',
      'photoPath TEXT', 'notes TEXT'];
    for (final col in cols) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN $col'); } catch (_) {}
    }
    try { await db.execute('CREATE TABLE IF NOT EXISTS custom_values (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT NOT NULL, value TEXT NOT NULL, UNIQUE(category, value))'); } catch (_) {}
    try { await db.execute('CREATE TABLE IF NOT EXISTS animal_groups (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, createdAt TEXT NOT NULL)'); } catch (_) {}
    try { await db.execute('CREATE TABLE IF NOT EXISTS animal_events (id TEXT PRIMARY KEY, animalId TEXT NOT NULL, eventType TEXT NOT NULL, title TEXT NOT NULL, description TEXT, date TEXT NOT NULL, cost REAL, createdAt TEXT NOT NULL)'); } catch (_) {}
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE sheep ADD COLUMN animalType TEXT DEFAULT "Sheep"'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN purchaseCost REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN birthLocation TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE sheep ADD COLUMN groupOwner TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('CREATE TABLE IF NOT EXISTS animals (id TEXT PRIMARY KEY, tagNumber TEXT NOT NULL, name TEXT, animalType TEXT DEFAULT \'Sheep\', breed TEXT, gender TEXT NOT NULL, dateOfBirth TEXT NOT NULL, weight REAL, color TEXT, status TEXT DEFAULT \'Active\', purchaseCost REAL, birthLocation TEXT, groupOwner TEXT, motherId TEXT, motherName TEXT, fatherId TEXT, photoPath TEXT, notes TEXT, dateAdded TEXT NOT NULL, lastUpdated TEXT NOT NULL)'); } catch (_) {}
      try { await db.execute('CREATE TABLE IF NOT EXISTS custom_values (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT NOT NULL, value TEXT NOT NULL, UNIQUE(category, value))'); } catch (_) {}
      try { await db.execute('CREATE TABLE IF NOT EXISTS animal_groups (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, createdAt TEXT NOT NULL)'); } catch (_) {}
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN motherName TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animals ADD COLUMN ownershipType TEXT DEFAULT "Personal"'); } catch (_) {}
      try { await db.execute('ALTER TABLE animals ADD COLUMN partnerName TEXT'); } catch (_) {}
      try { await db.execute('CREATE TABLE IF NOT EXISTS animal_events (id TEXT PRIMARY KEY, animalId TEXT NOT NULL, eventType TEXT NOT NULL, title TEXT NOT NULL, description TEXT, date TEXT NOT NULL, cost REAL, createdAt TEXT NOT NULL)'); } catch (_) {}
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE animals (
        id TEXT PRIMARY KEY, tagNumber TEXT NOT NULL, name TEXT,
        animalType TEXT DEFAULT 'Sheep', breed TEXT, gender TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL, weight REAL, color TEXT,
        status TEXT DEFAULT 'Active', purchaseCost REAL,
        birthLocation TEXT, groupOwner TEXT,
        ownershipType TEXT DEFAULT 'Personal', partnerName TEXT,
        motherId TEXT, motherName TEXT, fatherId TEXT,
        photoPath TEXT, notes TEXT,
        dateAdded TEXT NOT NULL, lastUpdated TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_records (
        id TEXT PRIMARY KEY, sheepId TEXT NOT NULL, type TEXT NOT NULL,
        description TEXT NOT NULL, medicine TEXT, dosage REAL, dosageUnit TEXT,
        veterinarian TEXT, cost REAL, date TEXT NOT NULL, nextDueDate TEXT,
        status TEXT DEFAULT 'Completed', notes TEXT, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE weight_records (
        id TEXT PRIMARY KEY, sheepId TEXT NOT NULL,
        weight REAL NOT NULL, date TEXT NOT NULL, notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE breeding_records (
        id TEXT PRIMARY KEY, eweId TEXT NOT NULL, ramId TEXT,
        matingDate TEXT NOT NULL, expectedLambingDate TEXT,
        actualLambingDate TEXT, status TEXT DEFAULT 'Mated',
        lambsBorn INTEGER, lambsSurvived INTEGER, notes TEXT, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE financial_records (
        id TEXT PRIMARY KEY, type TEXT NOT NULL, category TEXT NOT NULL,
        description TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL,
        sheepId TEXT, notes TEXT, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE feed_records (
        id TEXT PRIMARY KEY, feedType TEXT NOT NULL, quantity REAL NOT NULL,
        costPerKg REAL, date TEXT NOT NULL, notes TEXT, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL, value TEXT NOT NULL, UNIQUE(category, value)
      )
    ''');
    await db.execute('''
      CREATE TABLE animal_groups (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        description TEXT, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE animal_events (
        id TEXT PRIMARY KEY, animalId TEXT NOT NULL,
        eventType TEXT NOT NULL, title TEXT NOT NULL,
        description TEXT, date TEXT NOT NULL,
        cost REAL, createdAt TEXT NOT NULL
      )
    ''');
  }

  // ══ ANIMALS ══════════════════════════════════════════════════════

  Future<String> insertAnimal(Animal a) async {
    final db = await database;
    await db.insert('animals', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return a.id;
  }

  Future<List<Animal>> getAllAnimals({String? status, String? animalType}) async {
    final db = await database;
    String? where; List<dynamic>? args;
    if (status != null && animalType != null) { where = 'status=? AND animalType=?'; args = [status, animalType]; }
    else if (status != null) { where = 'status=?'; args = [status]; }
    else if (animalType != null) { where = 'animalType=?'; args = [animalType]; }
    final maps = await db.query('animals', where: where, whereArgs: args, orderBy: 'dateAdded DESC');
    return maps.map(Animal.fromMap).toList();
  }

  Future<Animal?> getAnimalById(String id) async {
    final db = await database;
    final m = await db.query('animals', where: 'id=?', whereArgs: [id]);
    return m.isEmpty ? null : Animal.fromMap(m.first);
  }

  Future<List<Animal>> getOffspring(String parentId) async {
    final db = await database;
    final maps = await db.query('animals',
        where: 'motherId=? OR fatherId=?', whereArgs: [parentId, parentId], orderBy: 'dateOfBirth DESC');
    return maps.map(Animal.fromMap).toList();
  }

  Future<int> updateAnimal(Animal a) async {
    final db = await database;
    return db.update('animals', a.toMap(), where: 'id=?', whereArgs: [a.id]);
  }

  Future<int> deleteAnimal(String id) async {
    final db = await database;
    return db.delete('animals', where: 'id=?', whereArgs: [id]);
  }

  Future<Map<String, int>> getAnimalStatistics() async {
    final db = await database;
    final r = (await db.rawQuery('''
      SELECT COUNT(*) as total,
        SUM(CASE WHEN gender='Female' THEN 1 ELSE 0 END) as females,
        SUM(CASE WHEN gender='Male' THEN 1 ELSE 0 END) as males,
        SUM(CASE WHEN status='Active' OR status='Pregnant' OR status='Gave Birth' THEN 1 ELSE 0 END) as active,
        SUM(CASE WHEN status='Sold' THEN 1 ELSE 0 END) as sold,
        SUM(CASE WHEN status='Deceased' THEN 1 ELSE 0 END) as deceased
      FROM animals
    ''')).first;
    return {
      'total': (r['total'] as int?) ?? 0,
      'females': (r['females'] as int?) ?? 0,
      'males': (r['males'] as int?) ?? 0,
      'active': (r['active'] as int?) ?? 0,
      'sold': (r['sold'] as int?) ?? 0,
      'deceased': (r['deceased'] as int?) ?? 0,
    };
  }

  // Get total purchase cost of all animals (for net profit calc)
  Future<double> getTotalPurchaseCost() async {
    final db = await database;
    final r = await db.rawQuery('SELECT SUM(purchaseCost) as total FROM animals');
    return ((r.first['total'] as num?) ?? 0.0).toDouble();
  }

  // Compat aliases
  Future<List<Animal>> getAllSheep({String? status}) => getAllAnimals(status: status);
  Future<Map<String, int>> getSheepStatistics() => getAnimalStatistics();
  Future<String> insertSheep(Animal a) => insertAnimal(a);
  Future<int> updateSheep(Animal a) => updateAnimal(a);
  Future<int> deleteSheep(String id) => deleteAnimal(id);
  Future<Animal?> getSheepById(String id) => getAnimalById(id);

  // ══ HEALTH ═══════════════════════════════════════════════════════

  Future<String> insertHealthRecord(HealthRecord r) async {
    final db = await database;
    await db.insert('health_records', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  Future<List<HealthRecord>> getHealthRecordsForSheep(String id) async {
    final db = await database;
    final maps = await db.query('health_records', where: 'sheepId=?', whereArgs: [id], orderBy: 'date DESC');
    return maps.map(HealthRecord.fromMap).toList();
  }

  Future<List<HealthRecord>> getUpcomingHealthTasks() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final maps = await db.query('health_records',
        where: 'nextDueDate BETWEEN ? AND ?', whereArgs: [now, future], orderBy: 'nextDueDate ASC');
    return maps.map(HealthRecord.fromMap).toList();
  }

  Future<int> deleteHealthRecord(String id) async {
    final db = await database;
    return db.delete('health_records', where: 'id=?', whereArgs: [id]);
  }

  // ══ WEIGHT ════════════════════════════════════════════════════════

  Future<String> insertWeightRecord(WeightRecord r) async {
    final db = await database;
    await db.insert('weight_records', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  Future<List<WeightRecord>> getWeightRecordsForSheep(String id) async {
    final db = await database;
    final maps = await db.query('weight_records', where: 'sheepId=?', whereArgs: [id], orderBy: 'date ASC');
    return maps.map(WeightRecord.fromMap).toList();
  }

  // ══ BREEDING ══════════════════════════════════════════════════════

  Future<String> insertBreedingRecord(BreedingRecord r) async {
    final db = await database;
    await db.insert('breeding_records', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  Future<List<BreedingRecord>> getAllBreedingRecords() async {
    final db = await database;
    final maps = await db.query('breeding_records', orderBy: 'matingDate DESC');
    return maps.map(BreedingRecord.fromMap).toList();
  }

  Future<List<BreedingRecord>> getBreedingRecordsForSheep(String id) async {
    final db = await database;
    final maps = await db.query('breeding_records',
        where: 'eweId=? OR ramId=?', whereArgs: [id, id], orderBy: 'matingDate DESC');
    return maps.map(BreedingRecord.fromMap).toList();
  }

  Future<int> updateBreedingRecord(BreedingRecord r) async {
    final db = await database;
    return db.update('breeding_records', r.toMap(), where: 'id=?', whereArgs: [r.id]);
  }

  // ══ FINANCE ═══════════════════════════════════════════════════════

  Future<String> insertFinancialRecord(FinancialRecord r) async {
    final db = await database;
    await db.insert('financial_records', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  Future<List<FinancialRecord>> getAllFinancialRecords({String? type, int? limitDays}) async {
    final db = await database;
    String? where; List<dynamic>? args;
    if (type != null && limitDays != null) {
      final since = DateTime.now().subtract(Duration(days: limitDays)).toIso8601String();
      where = 'type=? AND date>=?'; args = [type, since];
    } else if (type != null) { where = 'type=?'; args = [type]; }
    else if (limitDays != null) {
      final since = DateTime.now().subtract(Duration(days: limitDays)).toIso8601String();
      where = 'date>=?'; args = [since];
    }
    final maps = await db.query('financial_records', where: where, whereArgs: args, orderBy: 'date DESC');
    return maps.map(FinancialRecord.fromMap).toList();
  }

  Future<Map<String, double>> getFinancialSummary() async {
    final db = await database;
    final r = (await db.rawQuery('''
      SELECT SUM(CASE WHEN type='Income' THEN amount ELSE 0 END) as totalIncome,
             SUM(CASE WHEN type='Expense' THEN amount ELSE 0 END) as totalExpense
      FROM financial_records
    ''')).first;
    return {
      'income': ((r['totalIncome'] as num?) ?? 0.0).toDouble(),
      'expense': ((r['totalExpense'] as num?) ?? 0.0).toDouble(),
    };
  }

  Future<int> deleteFinancialRecord(String id) async {
    final db = await database;
    return db.delete('financial_records', where: 'id=?', whereArgs: [id]);
  }

  // ══ EVENTS ════════════════════════════════════════════════════════

  Future<String> insertEvent(AnimalEvent e) async {
    final db = await database;
    await db.insert('animal_events', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return e.id;
  }

  Future<List<AnimalEvent>> getEventsForAnimal(String animalId) async {
    final db = await database;
    final maps = await db.query('animal_events',
        where: 'animalId=?', whereArgs: [animalId], orderBy: 'date DESC');
    return maps.map(AnimalEvent.fromMap).toList();
  }

  Future<int> updateEvent(AnimalEvent e) async {
    final db = await database;
    return db.update('animal_events', e.toMap(), where: 'id=?', whereArgs: [e.id]);
  }

  Future<int> deleteEvent(String id) async {
    final db = await database;
    return db.delete('animal_events', where: 'id=?', whereArgs: [id]);
  }

  // ══ CUSTOM VALUES ═════════════════════════════════════════════════

  Future<void> saveCustomValue(String category, String value) async {
    if (value.trim().isEmpty) return;
    final db = await database;
    await db.insert('custom_values', {'category': category.toLowerCase(), 'value': value.trim()},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCustomValues(String category) async {
    final db = await database;
    final maps = await db.query('custom_values', where: 'category=?',
        whereArgs: [category.toLowerCase()], orderBy: 'value ASC');
    return maps.map((m) => m['value'] as String).toList();
  }

  Future<void> deleteCustomValue(String category, String value) async {
    final db = await database;
    await db.delete('custom_values', where: 'category=? AND value=?', whereArgs: [category.toLowerCase(), value]);
  }

  // ══ GROUPS ════════════════════════════════════════════════════════

  Future<void> insertGroup(AnimalGroup g) async {
    final db = await database;
    await db.insert('animal_groups', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AnimalGroup>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('animal_groups', orderBy: 'name ASC');
    return maps.map(AnimalGroup.fromMap).toList();
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete('animal_groups', where: 'id=?', whereArgs: [id]);
  }

  // ══ EXPORT / IMPORT ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'animals': await db.query('animals'),
      'health_records': await db.query('health_records'),
      'weight_records': await db.query('weight_records'),
      'breeding_records': await db.query('breeding_records'),
      'financial_records': await db.query('financial_records'),
      'animal_groups': await db.query('animal_groups'),
      'animal_events': await db.query('animal_events'),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '3.0.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in ['animals','health_records','weight_records','breeding_records','financial_records','animal_events']) {
        await txn.delete(t);
      }
      for (final row in (data['animals'] as List? ?? data['sheep'] as List? ?? [])) {
        await txn.insert('animals', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['health_records'] as List? ?? [])) {
        await txn.insert('health_records', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['weight_records'] as List? ?? [])) {
        await txn.insert('weight_records', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['breeding_records'] as List? ?? [])) {
        await txn.insert('breeding_records', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['financial_records'] as List? ?? [])) {
        await txn.insert('financial_records', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final row in (data['animal_events'] as List? ?? [])) {
        await txn.insert('animal_events', Map<String, dynamic>.from(row as Map), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
