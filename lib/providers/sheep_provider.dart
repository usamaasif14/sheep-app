// sheep_provider.dart - State management for sheep data
import 'package:flutter/foundation.dart';
import '../models/sheep_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';
import '../services/database_service.dart';

class SheepProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Sheep> _allSheep = [];
  List<Sheep> _filteredSheep = [];
  Map<String, int> _statistics = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _genderFilter = 'All';

  List<Sheep> get allSheep => _filteredSheep;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get genderFilter => _genderFilter;
  int get totalCount => _allSheep.length;
  int get activeCount => _allSheep.where((s) => s.status == 'Active').length;
  int get femaleCount => _allSheep.where((s) => s.gender == 'Female' && s.status == 'Active').length;
  int get maleCount => _allSheep.where((s) => s.gender == 'Male' && s.status == 'Active').length;

  Future<void> loadSheep() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allSheep = await _db.getAllSheep();
      _statistics = await _db.getSheepStatistics();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredSheep = _allSheep.where((sheep) {
      // Status filter
      if (_statusFilter != 'All' && sheep.status != _statusFilter) return false;
      // Gender filter
      if (_genderFilter != 'All' && sheep.gender != _genderFilter) return false;
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return sheep.tagNumber.toLowerCase().contains(q) ||
            sheep.name.toLowerCase().contains(q) ||
            sheep.breed.toLowerCase().contains(q);
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void setGenderFilter(String gender) {
    _genderFilter = gender;
    _applyFilters();
  }

  Future<void> addSheep(Sheep sheep) async {
    await _db.insertSheep(sheep);
    await loadSheep();
  }

  Future<void> updateSheep(Sheep sheep) async {
    await _db.updateSheep(sheep);
    await loadSheep();
  }

  Future<void> deleteSheep(String id) async {
    await _db.deleteSheep(id);
    await loadSheep();
  }

  Future<List<HealthRecord>> getHealthRecords(String sheepId) async {
    return _db.getHealthRecordsForSheep(sheepId);
  }

  Future<void> addHealthRecord(HealthRecord record) async {
    await _db.insertHealthRecord(record);
    notifyListeners();
  }

  Future<List<WeightRecord>> getWeightHistory(String sheepId) async {
    return _db.getWeightRecordsForSheep(sheepId);
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    await _db.insertWeightRecord(record);
    notifyListeners();
  }

  Future<List<BreedingRecord>> getBreedingRecords(String sheepId) async {
    return _db.getBreedingRecordsForSheep(sheepId);
  }

  Future<List<HealthRecord>> getUpcomingHealthTasks() async {
    return _db.getUpcomingHealthTasks();
  }

  List<Sheep> getSheepByGender(String gender) {
    return _allSheep.where((s) => s.gender == gender && s.status == 'Active').toList();
  }

  List<Sheep> getSheepByBreed() {
    final breedMap = <String, List<Sheep>>{};
    for (final sheep in _allSheep) {
      breedMap.putIfAbsent(sheep.breed, () => []).add(sheep);
    }
    return _allSheep;
  }

  Map<String, int> getBreedDistribution() {
    final breedMap = <String, int>{};
    for (final sheep in _allSheep.where((s) => s.status == 'Active')) {
      breedMap[sheep.breed] = (breedMap[sheep.breed] ?? 0) + 1;
    }
    return breedMap;
  }
}

class FinanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FinancialRecord> _records = [];
  Map<String, double> _summary = {'income': 0.0, 'expense': 0.0};
  bool _isLoading = false;

  List<FinancialRecord> get records => _records;
  Map<String, double> get summary => _summary;
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

  List<FinancialRecord> getByType(String type) {
    return _records.where((r) => r.type == type).toList();
  }

  Map<String, double> getExpenseByCategory() {
    final map = <String, double>{};
    for (final record in _records.where((r) => r.type == 'Expense')) {
      map[record.category] = (map[record.category] ?? 0.0) + record.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> getMonthlyData({int months = 6}) {
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final income = _records
          .where((r) =>
              r.type == 'Income' &&
              r.date.year == date.year &&
              r.date.month == date.month)
          .fold(0.0, (sum, r) => sum + r.amount);
      final expense = _records
          .where((r) =>
              r.type == 'Expense' &&
              r.date.year == date.year &&
              r.date.month == date.month)
          .fold(0.0, (sum, r) => sum + r.amount);
      result.add({'month': monthStr, 'income': income, 'expense': expense});
    }
    return result;
  }
}
