import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService();
  final _notificationService = NotificationService();

  bool _isBusy = false;
  String? _lastBackupTime;
  String _farmName = 'My Farm';
  String _farmerName = 'Farm Manager';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // Only listen to auth changes when Firebase is actually ready
    FirebaseService.authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = await _backupService.getLastBackupTime();
    if (mounted) {
      setState(() {
        _lastBackupTime = lastTime;
        _farmName = prefs.getString('farm_name') ?? 'My Farm';
        _farmerName = prefs.getString('farmer_name') ?? 'Farm Manager';
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  bool get _isSignedIn => FirebaseService.isSignedIn;
  dynamic get _user => FirebaseService.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: const Text('Settings & Backup',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFarmProfileCard(),
          const SizedBox(height: 24),

          // ── Google Sync ──
          const SectionHeader(
              title: 'Google Account & Sync', icon: Icons.sync_rounded),
          const SizedBox(height: 12),
          _buildGoogleSyncCard(),
          const SizedBox(height: 24),

          // ── Export ──
          const SectionHeader(
              title: 'Export Data', icon: Icons.file_download_rounded),
          const SizedBox(height: 12),
          _buildExportCard(),
          const SizedBox(height: 24),

          // ── Notifications ──
          const SectionHeader(
              title: 'Notifications & Alerts',
              icon: Icons.notifications_active_rounded),
          const SizedBox(height: 12),
          _buildNotificationCard(),
          const SizedBox(height: 24),

          // ── About ──
          const SectionHeader(
              title: 'About App', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildAboutCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Farm Profile ────────────────────────────────────────────────────────────

  Widget _buildFarmProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.agriculture_rounded,
                color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_farmName,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('Owner: $_farmerName',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppTheme.accent, size: 20),
            onPressed: _editFarmProfile,
          ),
        ],
      ),
    );
  }

  // ── Google Sync ─────────────────────────────────────────────────────────────

  Widget _buildGoogleSyncCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isSignedIn ? AppTheme.accentGreen : AppTheme.textMuted)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSignedIn
                      ? Icons.verified_user_rounded
                      : Icons.account_circle_outlined,
                  color: _isSignedIn ? AppTheme.accentGreen : AppTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignedIn ? 'Connected' : 'Not connected',
                      style: TextStyle(
                          color: _isSignedIn
                              ? AppTheme.accentGreen
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    Text(
                      _isSignedIn
                          ? (_user?.email ?? 'Google account')
                          : 'Sign in to enable cloud backup & sync',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isBusy
                    ? null
                    : (_isSignedIn ? _signOut : _signIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSignedIn ? AppTheme.primaryLight : AppTheme.accent,
                  foregroundColor:
                      _isSignedIn ? AppTheme.textPrimary : AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(_isSignedIn ? 'Sign Out' : 'Sign In',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          if (_isSignedIn) ...[
            const Divider(height: 24, color: AppTheme.divider),
            // Last backup info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last backup:',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                Text(
                  _lastBackupTime != null
                      ? DateFormat('d MMM yyyy, hh:mm a')
                          .format(DateTime.parse(_lastBackupTime!))
                      : 'Never',
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _backupNow,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent))
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('Backup Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _restoreNow,
                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      side: const BorderSide(color: AppTheme.accentBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Sign in with your Google account to sync all animal data across devices and keep a cloud backup.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_chart_rounded,
                  color: AppTheme.accentGreen, size: 22),
            ),
            title: const Text('Export to Excel (.xlsx)',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'All animals, health, finance & breeding records',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: _isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGreen))
                : const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
            onTap: _isBusy ? null : _exportExcel,
          ),
        ],
      ),
    );
  }

  // ── Notifications ───────────────────────────────────────────────────────────

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notificationsEnabled,
            activeColor: AppTheme.accent,
            title: const Text('Enable Reminders',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            subtitle: const Text('Vaccination, deworming & breeding alerts',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', val);
              setState(() => _notificationsEnabled = val);
            },
          ),
          const Divider(height: 16, color: AppTheme.divider),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.send_rounded, color: AppTheme.accent, size: 20),
            title: const Text('Send Test Notification',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            subtitle: const Text('Verify alerts are working',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            onTap: () async {
              await _notificationService.showInstantNotification(
                title: '🐄 Farm Manager',
                body: 'Notification system is working!',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Test notification sent!'),
                    backgroundColor: AppTheme.accentGreen));
              }
            },
          ),
        ],
      ),
    );
  }

  // ── About ───────────────────────────────────────────────────────────────────

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        children: [
          _AboutRow(label: 'App Name', value: 'Farm Manager'),
          _AboutRow(label: 'Version', value: '2.0.0'),
          _AboutRow(label: 'Database', value: 'SQLite + Firebase'),
          _AboutRow(
              label: 'Supported Animals',
              value: 'All types (sheep, goat, cow…)'),
        ],
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _isBusy = true);
    try {
      final cred = await _backupService.signInWithGoogle();
      if (cred != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Signed in as ${cred.user?.email}'),
            backgroundColor: AppTheme.accentGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: AppTheme.accentRed));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    await _backupService.signOut();
    setState(() {});
  }

  Future<void> _backupNow() async {
    setState(() => _isBusy = true);
    final result = await _backupService.backupToCloud();
    final lastTime = await _backupService.getLastBackupTime();
    if (mounted) {
      setState(() {
        _isBusy = false;
        _lastBackupTime = lastTime;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? AppTheme.accentGreen : AppTheme.accentRed));
    }
  }

  Future<void> _restoreNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Restore from Cloud?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'This will replace all local data with your cloud backup.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent),
              child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    final result = await _backupService.restoreFromCloud();
    if (mounted) {
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? AppTheme.accentGreen : AppTheme.accentRed));
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isBusy = true);
    final result = await _backupService.exportToExcel();
    if (mounted) {
      setState(() => _isBusy = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.accentRed));
      }
    }
  }

  void _editFarmProfile() {
    final farmCtrl = TextEditingController(text: _farmName);
    final farmerCtrl = TextEditingController(text: _farmerName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Edit Farm Profile',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: farmCtrl,
                decoration:
                    const InputDecoration(labelText: 'Farm Name')),
            const SizedBox(height: 12),
            TextField(
                controller: farmerCtrl,
                decoration:
                    const InputDecoration(labelText: 'Owner Name')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final fn = farmCtrl.text.trim();
              final fmn = farmerCtrl.text.trim();
              if (fn.isNotEmpty) await prefs.setString('farm_name', fn);
              if (fmn.isNotEmpty) await prefs.setString('farmer_name', fmn);
              if (mounted) {
                setState(() {
                  if (fn.isNotEmpty) _farmName = fn;
                  if (fmn.isNotEmpty) _farmerName = fmn;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
