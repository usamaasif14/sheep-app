// firebase_service.dart
// Single safe gateway for all Firebase calls.
// The app works 100% offline. Firebase only activates when
// google-services.json is present in android/app/.
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  FirebaseService._();

  static bool _ready = false;
  static bool get isReady => _ready;
  static bool get isSignedIn => _ready && FirebaseAuth.instance.currentUser != null;
  static User? get currentUser => _ready ? FirebaseAuth.instance.currentUser : null;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // ── Init (safe — never crashes the app) ───────────────────────────
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
      debugPrint('✅ Firebase ready — Google Sync enabled');
    } catch (e) {
      _ready = false;
      debugPrint('ℹ️ Firebase not configured — app running offline: $e');
    }
  }

  // ── Auth state stream (empty if not ready) ────────────────────────
  static Stream<User?> get authStateChanges {
    if (!_ready) return const Stream.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  // ── Google Sign-In ────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    if (!_ready) throw Exception('Firebase not configured. Add google-services.json.');
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final auth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    if (!_ready) return;
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  // ── Cloud Firestore ───────────────────────────────────────────────
  static Future<void> saveBackupMeta(String uid, Map<String, dynamic> meta) async {
    if (!_ready) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('backups')
        .add({...meta, 'timestamp': FieldValue.serverTimestamp()});
  }

  static Future<Map<String, dynamic>?> getLatestBackupMeta(String uid) async {
    if (!_ready) return null;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('backups')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  // ── Firebase Storage ──────────────────────────────────────────────
  static Future<String> uploadBackup(String uid, String json) async {
    final ref = FirebaseStorage.instance.ref('backups/$uid/farm_backup.json');
    await ref.putString(json,
        metadata: SettableMetadata(contentType: 'application/json'));
    return ref.getDownloadURL();
  }

  static Future<List<int>?> downloadBackup(String uid) async {
    final ref = FirebaseStorage.instance.ref('backups/$uid/farm_backup.json');
    return ref.getData();
  }
}
