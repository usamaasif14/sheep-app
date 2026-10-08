// backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _db = DatabaseService();

  bool get isSignedIn => FirebaseService.isSignedIn;
  dynamic get currentUser => FirebaseService.currentUser;

  Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastBackupTime');
  }

  Future<dynamic> signInWithGoogle() => FirebaseService.signInWithGoogle();
  Future<void> signOut() => FirebaseService.signOut();

  // ── Cloud Backup ──────────────────────────────────────────────────

  Future<BackupResult> backupToCloud() async {
    if (!FirebaseService.isReady) {
      return BackupResult(
          success: false,
          message: 'Firebase not configured. Add google-services.json to enable sync.');
    }
    if (!isSignedIn) {
      return BackupResult(success: false, message: 'Please sign in with Google first.');
    }
    try {
      final uid = currentUser!.uid as String;
      final data = await _db.exportAllData();
      final jsonData = jsonEncode(data);

      final downloadUrl = await FirebaseService.uploadBackup(uid, jsonData);

      await FirebaseService.saveBackupMeta(uid, {
        'timestamp': FieldValue.serverTimestamp(),
        'downloadUrl': downloadUrl,
        'animalCount': (data['animals'] as List?)?.length ?? 0,
        'version': data['version'],
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());

      return BackupResult(success: true, message: 'Cloud backup successful!');
    } catch (e) {
      return BackupResult(success: false, message: 'Backup failed: $e');
    }
  }

  Future<BackupResult> restoreFromCloud() async {
    if (!FirebaseService.isReady) {
      return BackupResult(
          success: false, message: 'Firebase not configured.');
    }
    if (!isSignedIn) {
      return BackupResult(success: false, message: 'Please sign in with Google first.');
    }
    try {
      final uid = currentUser!.uid as String;
      final meta = await FirebaseService.getLatestBackupMeta(uid);
      if (meta == null) {
        return BackupResult(success: false, message: 'No cloud backup found.');
      }

      final bytes = await FirebaseService.downloadBackup(uid);
      if (bytes == null) {
        return BackupResult(success: false, message: 'Backup file missing in storage.');
      }

      final backupData = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await _db.importData(backupData);

      return BackupResult(success: true, message: 'Data restored from cloud!');
    } catch (e) {
      return BackupResult(success: false, message: 'Restore failed: $e');
    }
  }

  // ── Excel Export ──────────────────────────────────────────────────

  Future<BackupResult> exportToExcel() async {
    try {
      final data = await _db.exportAllData();
      final excel = Excel.createExcel();

      // Animals sheet
      final animalSheet = excel['Animals'];
      excel.setDefaultSheet('Animals');
      _header(animalSheet, [
        'Tag No', 'Name', 'Type', 'Breed', 'Gender', 'DOB', 'Age',
        'Weight(kg)', 'Color', 'Status', 'Cost(Rs)', 'Location',
        'Group/Owner', 'Mother ID', 'Father ID', 'Notes', 'Date Added',
      ]);
      for (final row in (data['animals'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        final dob = DateTime.tryParse(m['dateOfBirth'] as String? ?? '');
        final added = DateTime.tryParse(m['dateAdded'] as String? ?? '');
        _row(animalSheet, [
          m['tagNumber'] ?? '', m['name'] ?? '', m['animalType'] ?? 'Sheep',
          m['breed'] ?? '', m['gender'] ?? '',
          dob != null ? DateFormat('dd/MM/yyyy').format(dob) : '',
          dob != null ? _age(dob) : '',
          m['weight']?.toString() ?? '',
          m['color'] ?? '', m['status'] ?? '',
          m['purchaseCost']?.toString() ?? '',
          m['birthLocation'] ?? '', m['groupOwner'] ?? '',
          m['motherId'] ?? '', m['fatherId'] ?? '',
          m['notes'] ?? '',
          added != null ? DateFormat('dd/MM/yyyy').format(added) : '',
        ]);
      }

      // Health sheet
      final healthSheet = excel['Health Records'];
      _header(healthSheet, [
        'Animal ID', 'Type', 'Description', 'Medicine', 'Dosage', 'Unit',
        'Vet', 'Cost(Rs)', 'Date', 'Next Due', 'Status', 'Notes',
      ]);
      for (final row in (data['health_records'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        final d = DateTime.tryParse(m['date'] as String? ?? '');
        final nd = DateTime.tryParse(m['nextDueDate'] as String? ?? '');
        _row(healthSheet, [
          m['sheepId'] ?? '', m['type'] ?? '', m['description'] ?? '',
          m['medicine'] ?? '', m['dosage']?.toString() ?? '',
          m['dosageUnit'] ?? '', m['veterinarian'] ?? '',
          m['cost']?.toString() ?? '',
          d != null ? DateFormat('dd/MM/yyyy').format(d) : '',
          nd != null ? DateFormat('dd/MM/yyyy').format(nd) : '',
          m['status'] ?? '', m['notes'] ?? '',
        ]);
      }

      // Finance sheet
      final finSheet = excel['Finance'];
      _header(finSheet, [
        'Type', 'Category', 'Description', 'Amount(Rs)', 'Date',
        'Animal ID', 'Notes',
      ]);
      for (final row in (data['financial_records'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        final d = DateTime.tryParse(m['date'] as String? ?? '');
        _row(finSheet, [
          m['type'] ?? '', m['category'] ?? '', m['description'] ?? '',
          m['amount']?.toString() ?? '',
          d != null ? DateFormat('dd/MM/yyyy').format(d) : '',
          m['sheepId'] ?? '', m['notes'] ?? '',
        ]);
      }

      // Breeding sheet
      final breedSheet = excel['Breeding'];
      _header(breedSheet, [
        'Female ID', 'Male ID', 'Mating Date', 'Expected Birth',
        'Actual Birth', 'Status', 'Offspring Born', 'Survived', 'Notes',
      ]);
      for (final row in (data['breeding_records'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        _row(breedSheet, [
          m['eweId'] ?? '', m['ramId'] ?? '',
          m['matingDate'] ?? '', m['expectedLambingDate'] ?? '',
          m['actualLambingDate'] ?? '', m['status'] ?? '',
          m['lambsBorn']?.toString() ?? '',
          m['lambsSurvived']?.toString() ?? '', m['notes'] ?? '',
        ]);
      }

      // Save and share
      final dir = await getTemporaryDirectory();
      final name =
          'FarmManager_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$name');
      final bytes = excel.encode();
      if (bytes == null) {
        return BackupResult(success: false, message: 'Failed to encode Excel.');
      }
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Farm Manager Export — $name',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());

      return BackupResult(success: true, message: 'Excel exported!');
    } catch (e) {
      return BackupResult(success: false, message: 'Export failed: $e');
    }
  }

  void _header(Sheet sheet, List<String> cols) {
    sheet.appendRow(cols.map((c) => TextCellValue(c)).toList());
    final idx = sheet.maxRows - 1;
    for (int c = 0; c < cols.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: idx));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF1A2E45'),
        fontColorHex: ExcelColor.fromHexString('FFE8A838'),
      );
    }
  }

  void _row(Sheet sheet, List<dynamic> values) {
    sheet.appendRow(values.map((v) => TextCellValue(v.toString())).toList());
  }

  String _age(DateTime dob) {
    final months = (DateTime.now().difference(dob).inDays / 30.44).floor();
    if (months < 12) return '${months}mo';
    return '${(months / 12).floor()}yr';
  }
}

class BackupResult {
  final bool success;
  final String message;
  final String? data;
  BackupResult({required this.success, required this.message, this.data});
}
