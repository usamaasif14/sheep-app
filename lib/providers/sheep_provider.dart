// sheep_provider.dart
import 'package:flutter/foundation.dart';
import '../models/animal_model.dart';
import '../models/health_model.dart';
import '../models/breeding_model.dart';
import '../services/database_service.dart';

class SheepProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Animal> _all = [];
  List<Animal> _filtered = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _genderFilter = 'All';
  String _typeFilter = 'All';

  List<Animal> get allAnimals => _filtered;
  List<Animal> get allSheep => _filtered;
  Map<String, int> get statistics => _stats;
  bool get isLoading => _isLoading;
  int get totalCount => _all.length;
  int get activeCount => _all.where((a) => ['Active','Pregnant','Gave Birth'].contains(a.status)).length;
  int get femaleCount => _all.where((a) => a.gender == 'Female' && ['Active','Pregnant','Gave Birth'].contains(a.status)).length;
  int get maleCount => _all.where((a) => a.gender == 'Male' && ['Active','Pregnant','Gave Birth'].contains(a.status)).length;
  int get pregnantCount => _all.where((a) => a.status == 'Pregnant').length;

  List<Animal> get activeFemales => _all.where((a) => a.gender == 'Female' && ['Active','Pregnant','Gave Birth'].contains(a.status)).toList();
  List<Animal> get activeMales => _all.where((a) => a.gender == 'Male' && ['Active','Pregnant','Gave Birth'].contains(a.status)).toList();

  Future<void> loadSheep() async {
    _isLoading = true;
    notifyListeners();
    try {
      _all = await _db.getAllAnimals();
      _stats = await _db.getAnimalStatistics();
      _applyFilters();
    } catch (e) {
      debugPrint('Load animals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filtered = _all.where((a) {
      if (_statusFilter != 'All' && a.status != _statusFilter) return false;
      if (_genderFilter != 'All' && a.gender != _genderFilter) return false;
      if (_typeFilter != 'All' && a.animalType != _typeFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return a.tagNumber.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q) ||
            a.breed.toLowerCase().contains(q) ||
            a.animalType.toLowerCase().contains(q) ||
            (a.motherName ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void setSearch(String q) { _searchQuery = q; _applyFilters(); }
  void setStatusFilter(String s) { _statusFilter = s; _applyFilters(); }
  void setGenderFilter(String g) { _genderFilter = g; _applyFilters(); }
  void setTypeFilter(String t) { _typeFilter = t; _applyFilters(); }

  Future<void> addSheep(Animal a) async { await _db.insertAnimal(a); await loadSheep(); }
  Future<void> updateSheep(Animal a) async { await _db.updateAnimal(a); await loadSheep(); }
  Future<void> deleteSheep(String id) async { await _db.deleteAnimal(id); await loadSheep(); }

  Future<List<Animal>> getOffspring(String parentId) => _db.getOffspring(parentId);
  Future<List<HealthRecord>> getHealthRecords(String id) => _db.getHealthRecordsForSheep(id);
  Future<void> addHealthRecord(HealthRecord r) async { await _db.insertHealthRecord(r); notifyListeners(); }
  Future<List<WeightRecord>> getWeightHistory(String id) => _db.getWeightRecordsForSheep(id);
  Future<void> addWeightRecord(WeightRecord r) async { await _db.insertWeightRecord(r); notifyListeners(); }
  Future<List<BreedingRecord>> getBreedingRecords(String id) => _db.getBreedingRecordsForSheep(id);
  Future<List<HealthRecord>> getUpcomingHealthTasks() => _db.getUpcomingHealthTasks();

  Future<List<AnimalEvent>> getEvents(String animalId) => _db.getEventsForAnimal(animalId);
  Future<void> addEvent(AnimalEvent e) async { await _db.insertEvent(e); notifyListeners(); }
  Future<void> updateEvent(AnimalEvent e) async { await _db.updateEvent(e); notifyListeners(); }
  Future<void> deleteEvent(String id) async { await _db.deleteEvent(id); notifyListeners(); }

  Map<String, int> getBreedDistribution() {
    final map = <String, int>{};
    for (final a in _all.where((a) => ['Active','Pregnant','Gave Birth'].contains(a.status))) {
      final k = a.breed.isEmpty ? 'Unknown' : a.breed;
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> getTypeDistribution() {
    final map = <String, int>{};
    for (final a in _all.where((a) => ['Active','Pregnant','Gave Birth'].contains(a.status))) {
      map[a.animalType] = (map[a.animalType] ?? 0) + 1;
    }
    return map;
  }
}

// ── Finance Provider ──────────────────────────────────────────────────────────
class FinanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FinancialRecord> _records = [];
  Map<String, double> _summary = {'income': 0.0, 'expense': 0.0};
  double _totalPurchaseCost = 0.0;
  bool _isLoading = false;

  List<FinancialRecord> get records => _records;
  bool get isLoading => _isLoading;
  double get totalIncome => _summary['income'] ?? 0.0;
  double get totalExpense => (_summary['expense'] ?? 0.0) + _totalPurchaseCost;
  double get totalExpenseOnly => _summary['expense'] ?? 0.0;
  double get totalPurchaseCost => _totalPurchaseCost;
  double get netProfit => totalIncome - totalExpense;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await _db.getAllFinancialRecords();
      _summary = await _db.getFinancialSummary();
      _totalPurchaseCost = await _db.getTotalPurchaseCost();
    } catch (e) {
      debugPrint('Load finance error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(FinancialRecord r) async { await _db.insertFinancialRecord(r); await loadRecords(); }
  Future<void> deleteRecord(String id) async { await _db.deleteFinancialRecord(id); await loadRecords(); }

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
      final ms = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final income = _records.where((r) => r.type == 'Income' && r.date.year == date.year && r.date.month == date.month).fold(0.0, (s, r) => s + r.amount);
      final expense = _records.where((r) => r.type == 'Expense' && r.date.year == date.year && r.date.month == date.month).fold(0.0, (s, r) => s + r.amount);
      result.add({'month': ms, 'income': income, 'expense': expense});
    }
    return result;
  }
}
