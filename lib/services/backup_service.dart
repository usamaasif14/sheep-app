// backup_service.dart - Firebase cloud backup and restore
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _db = DatabaseService();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  // ============ AUTHENTICATION ============

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw BackupException('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ============ CLOUD BACKUP ============

  Future<BackupResult> backupToCloud() async {
    if (!isSignedIn) throw BackupException('Not signed in. Please sign in to backup.');

    try {
      final userId = currentUser!.uid;
      final data = await _db.exportAllData();
      final jsonData = jsonEncode(data);

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('backups/$userId/sheep_farm_backup.json');
      await storageRef.putString(jsonData, metadata: SettableMetadata(contentType: 'application/json'));
      final downloadUrl = await storageRef.getDownloadURL();

      // Save backup metadata to Firestore
      await _firestore.collection('users').doc(userId).collection('backups').add({
        'timestamp': FieldValue.serverTimestamp(),
        'storageUrl': downloadUrl,
        'sheepCount': (data['sheep'] as List).length,
        'deviceInfo': 'Android',
      });

      // Save last backup time locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastBackupTime', DateTime.now().toIso8601String());

      return BackupResult(success: true, message: 'Backup completed successfully!');
    } catch (e) {
      return BackupResult(success: false, message: 'Backup failed: $e');
    }
  }

  Future<BackupResult> restoreFromCloud() async {
    if (!isSignedIn) throw BackupException('Not signed in. Please sign in to restore.');

    try {
      final userId = currentUser!.uid;

      // Get latest backup URL from Firestore
      final backupsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (backupsSnapshot.docs.isEmpty) {
        return BackupResult(success: false, message: 'No backups found in cloud.');
      }

      final latestBackup = backupsSnapshot.docs.first.data();
      final storageUrl = latestBackup['storageUrl'] as String;

      // Download from Storage
      final storageRef = _storage.ref().child('backups/$userId/sheep_farm_backup.json');
      final data = await storageRef.getData();
      if (data == null) return BackupResult(success: false, message: 'Backup file not found.');

      final jsonString = utf8.decode(data);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import data into local DB
      await _db.importData(backupData);

      return BackupResult(success: true, message: 'Data restored successfully!');
    } catch (e) {
      return BackupResult(success: false, message: 'Restore failed: $e');
    }
  }

  Future<List<BackupInfo>> getBackupHistory() async {
    if (!isSignedIn) return [];

    try {
      final userId = currentUser!.uid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BackupInfo(
          id: doc.id,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          sheepCount: data['sheepCount'] ?? 0,
          storageUrl: data['storageUrl'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastBackupTime');
  }

  Future<BackupResult> exportToLocalJson() async {
    try {
      final data = await _db.exportAllData();
      final jsonData = jsonEncode(data);
      return BackupResult(success: true, message: 'Export ready', data: jsonData);
    } catch (e) {
      return BackupResult(success: false, message: 'Export failed: $e');
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
