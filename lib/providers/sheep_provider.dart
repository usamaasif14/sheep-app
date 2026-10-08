// sheep_provider.dart - State management (animals + finance)
import 'package:flutter/foundation.dart';
import '../models/animal_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';
import '../services/database_service.dart';

class SheepProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Animal> _allAnimals = [];
  List<Animal> _filtered = [];
  Map<String, int> _statistics = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _genderFilter = 'All';
  String _typeFilter = 'All'; // animal type filter

  List<Animal> get allSheep => _filtered;
  List<Animal> get allAnimals => _filtered;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  int get totalCount => _allAnimals.length;
  int get activeCount =>
      _allAnimals.where((a) => a.status == 'Active').length;
  int get femaleCount =>
      _allAnimals.where((a) => a.gender == 'Female' && a.status == 'Active').length;
  int get maleCount =>
      _allAnimals.where((a) => a.gender == 'Male' && a.status == 'Active').length;

  Future<void> loadSheep() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allAnimals = await _db.getAllAnimals();
      _statistics = await _db.getAnimalStatistics();
      _applyFilters();
    } catch (e) {
      debugPrint('Load animals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filtered = _allAnimals.where((a) {
      if (_statusFilter != 'All' && a.status != _statusFilter) return false;
      if (_genderFilter != 'All' && a.gender != _genderFilter) return false;
      if (_typeFilter != 'All' && a.animalType != _typeFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.tagNumber.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q) ||
            a.breed.toLowerCase().contains(q) ||
            a.animalType.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    _applyFilters();
  }

  void setStatusFilter(String s) {
    _statusFilter = s;
    _applyFilters();
  }

  void setGenderFilter(String g) {
    _genderFilter = g;
    _applyFilters();
  }

  void setTypeFilter(String t) {
    _typeFilter = t;
    _applyFilters();
  }

  Future<void> addSheep(Animal animal) async {
    await _db.insertAnimal(animal);
    await loadSheep();
  }

  Future<void> updateSheep(Animal animal) async {
    await _db.updateAnimal(animal);
    await loadSheep();
  }

  Future<void> deleteSheep(String id) async {
    await _db.deleteAnimal(id);
    await loadSheep();
  }

  Future<List<Animal>> getOffspring(String parentId) async {
    return _db.getOffspring(parentId);
  }

  Future<List<HealthRecord>> getHealthRecords(String animalId) async {
    return _db.getHealthRecordsForSheep(animalId);
  }

  Future<void> addHealthRecord(HealthRecord record) async {
    await _db.insertHealthRecord(record);
    notifyListeners();
  }

  Future<List<WeightRecord>> getWeightHistory(String animalId) async {
    return _db.getWeightRecordsForSheep(animalId);
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    await _db.insertWeightRecord(record);
    notifyListeners();
  }

  Future<List<BreedingRecord>> getBreedingRecords(String animalId) async {
    return _db.getBreedingRecordsForSheep(animalId);
  }

  Future<List<HealthRecord>> getUpcomingHealthTasks() async {
    return _db.getUpcomingHealthTasks();
  }

  /// Returns all active females (for offspring mother selection)
  List<Animal> get activeFemales =>
      _allAnimals.where((a) => a.gender == 'Female' && a.status == 'Active').toList();

  /// Returns all active males (for offspring father selection)
  List<Animal> get activeMales =>
      _allAnimals.where((a) => a.gender == 'Male' && a.status == 'Active').toList();

  Map<String, int> getBreedDistribution() {
    final map = <String, int>{};
    for (final a in _allAnimals.where((a) => a.status == 'Active')) {
      final key = a.breed.isEmpty ? 'Unknown' : a.breed;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> getTypeDistribution() {
    final map = <String, int>{};
    for (final a in _allAnimals.where((a) => a.status == 'Active')) {
      map[a.animalType] = (map[a.animalType] ?? 0) + 1;
    }
    return map;
  }

  List<Animal> getSheepByGender(String gender) =>
      _allAnimals.where((a) => a.gender == gender && a.status == 'Active').toList();
}

// ── Finance Provider ──────────────────────────────────────────────────────────

class FinanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FinancialRecord> _records = [];
  Map<String, double> _summary = {'income': 0.0, 'expense': 0.0};
  bool _isLoading = false;

  List<FinancialRecord> get records => _records;
  bool get isLoading => _isLoading;
  double get totalIncome => _summary['income'] ?? 0.0;
  double get totalExpense => _summary['expense'] ?? 0.0;
  double get netProfit => totalIncome - totalExpense;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await _db.getAllFinancialRecords();
      _summary = await _db.getFinancialSummary();
    } catch (e) {
      debugPrint('Load finance error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(FinancialRecord record) async {
    await _db.insertFinancialRecord(record);
    await loadRecords();
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteFinancialRecord(id);
    await loadRecords();
  }

  Map<String, double> getExpenseByCategory() {
    final map = <String, double>{};
    for (final r in _records.where((r) => r.type == 'Expense')) {
      map[r.category] = (map[r.category] ?? 0.0) + r.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> getMonthlyData({int months = 6}) {
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      final monthStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final income = _records
          .where((r) =>
              r.type == 'Income' &&
              r.date.year == date.year &&
              r.date.month == date.month)
          .fold(0.0, (s, r) => s + r.amount);
      final expense = _records
          .where((r) =>
              r.type == 'Expense' &&
              r.date.year == date.year &&
              r.date.month == date.month)
          .fold(0.0, (s, r) => s + r.amount);
      result.add({'month': monthStr, 'income': income, 'expense': expense});
    }
    return result;
  }
}
