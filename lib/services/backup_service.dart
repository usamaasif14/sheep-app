// backup_service.dart - Local backup/export (no Firebase required)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _db = DatabaseService();

  // Cloud backup not configured — always returns false
  bool get isSignedIn => false;
  dynamic get currentUser => null;

  Future<void> signOut() async {}

  Future<dynamic> signInWithGoogle() async {
    throw BackupException('Cloud backup requires Firebase setup. Use local export instead.');
  }

  Future<BackupResult> backupToCloud() async {
    return BackupResult(success: false, message: 'Cloud backup not configured. Use local JSON export.');
  }

  Future<BackupResult> restoreFromCloud() async {
    return BackupResult(success: false, message: 'Cloud restore not configured. Use local JSON import.');
  }

  Future<List<BackupInfo>> getBackupHistory() async => [];

  Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastBackupTime');
  }

  Future<BackupResult> exportToLocalJson() async {
    try {
      final data = await _db.exportAllData();
      final jsonData = jsonEncode(data);
      // Save timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());
      return BackupResult(success: true, message: 'Export ready', data: jsonData);
    } catch (e) {
      return BackupResult(success: false, message: 'Export failed: $e');
    }
  }

  Future<BackupResult> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      await _db.importData(data);
      return BackupResult(success: true, message: 'Data imported successfully!');
    } catch (e) {
      return BackupResult(success: false, message: 'Import failed: $e');
    }
  }
}

class BackupResult {
  final bool success;
  final String message;
  final String? data;

  BackupResult({required this.success, required this.message, this.data});
}

class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int sheepCount;
  final String storageUrl;

  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.sheepCount,
    required this.storageUrl,
  });
}

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}
