// settings_screen.dart - Application settings, cloud backup, restore, and farm profile
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';
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

  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupTime;
  String _farmName = 'My Sheep Farm';
  String _farmerName = 'Farm Manager';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = await _backupService.getLastBackupTime();
    setState(() {
      _lastBackupTime = lastTime;
      _farmName = prefs.getString('farm_name') ?? 'My Sheep Farm';
      _farmerName = prefs.getString('farmer_name') ?? 'Farm Manager';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Settings & Backup',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Farm Profile Card
          _buildFarmProfileCard(),
          const SizedBox(height: 24),

          // Cloud Backup Section
          const SectionHeader(title: 'Cloud Backup & Sync', icon: Icons.cloud_sync_rounded),
          const SizedBox(height: 12),
          _buildCloudBackupCard(),
          const SizedBox(height: 24),

          // Offline Data Management
          const SectionHeader(title: 'Data & Offline Export', icon: Icons.storage_rounded),
          const SizedBox(height: 12),
          _buildOfflineDataCard(),
          const SizedBox(height: 24),

          // Notifications & Reminders
          const SectionHeader(title: 'Notifications & Alerts', icon: Icons.notifications_active_rounded),
          const SizedBox(height: 12),
          _buildNotificationSettingsCard(),
          const SizedBox(height: 24),

          // App Information & Play Store Readiness
          const SectionHeader(title: 'About App & Play Store', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildAboutCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
            child: const Icon(Icons.agriculture_rounded, color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _farmName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Owner: $_farmerName',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 20),
            onPressed: _showEditFarmProfileDialog,
            tooltip: 'Edit Farm Details',
          ),
        ],
      ),
    );
  }

  Widget _buildCloudBackupCard() {
    final isSignedIn = _backupService.isSignedIn;
    final user = _backupService.currentUser;

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
          Row(
            children: [
              Icon(
                isSignedIn ? Icons.check_circle_rounded : Icons.account_circle_outlined,
                color: isSignedIn ? AppTheme.accentGreen : AppTheme.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignedIn ? 'Google Account Connected' : 'Google Cloud Account',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      isSignedIn ? (user?.email ?? 'Logged in') : 'Sign in to enable automatic cloud backup',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isSignedIn ? _handleSignOut : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSignedIn ? AppTheme.primaryLight : AppTheme.accent,
                  foregroundColor: isSignedIn ? AppTheme.textPrimary : AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(isSignedIn ? 'Sign Out' : 'Sign In', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.divider),

          // Last backup status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Last Cloud Backup:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text(
                _lastBackupTime != null
                    ? DateFormat('d MMM yyyy, hh:mm a').format(DateTime.parse(_lastBackupTime!))
                    : 'Never backed up',
                style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backup & Restore Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBackingUp ? null : _handleBackupToCloud,
                  icon: _isBackingUp
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                      : const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Backup Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRestoring ? null : _handleRestoreFromCloud,
                  icon: _isRestoring
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentBlue))
                      : const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('Restore Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    side: const BorderSide(color: AppTheme.accentBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineDataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_download_rounded, color: AppTheme.accentBlue, size: 22),
            ),
            title: const Text('Export JSON Database', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Export all sheep, health and financial records', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            onTap: _handleExportLocalJson,
          ),
          const Divider(height: 16, color: AppTheme.divider),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_upload_rounded, color: AppTheme.accentGreen, size: 22),
            ),
            title: const Text('Import Local Backup', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Restore records from saved JSON backup file', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select backup file from device storage to restore'),
                  backgroundColor: AppTheme.accentBlue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
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
            title: const Text('Enable Reminders', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Vaccination, deworming and lambing alerts', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', val);
              setState(() => _notificationsEnabled = val);
            },
          ),
          const Divider(height: 16, color: AppTheme.divider),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.send_rounded, color: AppTheme.accent, size: 20),
            title: const Text('Send Test Notification', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            subtitle: const Text('Verify that alert system works properly', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            onTap: () async {
              await _notificationService.showInstantNotification(
                title: '🐑 Sheep Manager Alert',
                body: 'Notification system is fully configured and operational!',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!'), backgroundColor: AppTheme.accentGreen),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Version', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('1.0.0 (Production Release)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Platform', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('Android (Google Play Ready)', style: TextStyle(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Database', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('SQLite + Cloud Firestore', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 24, color: AppTheme.divider),
          const Text(
            'Sheep Farm Manager is an offline-first management suite engineered for sheep breeders and farmers. Keep track of individual tags, breeding dates, lambing cycles, vaccination schedules, and farm income/expenses with secure cloud synchronization.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final cred = await _backupService.signInWithGoogle();
      if (cred != null) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in as ${cred.user?.email}'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in error: $e'), backgroundColor: AppTheme.accentRed),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _backupService.signOut();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully'), backgroundColor: AppTheme.accent),
    );
  }

  Future<void> _handleBackupToCloud() async {
    if (!_backupService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    setState(() => _isBackingUp = true);
    final result = await _backupService.backupToCloud();
    final lastTime = await _backupService.getLastBackupTime();
    setState(() {
      _isBackingUp = false;
      _lastBackupTime = lastTime;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _handleRestoreFromCloud() async {
    if (!_backupService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Restore from Cloud?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Restoring will replace current local database records with the latest cloud backup. Do you want to proceed?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Proceed Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    final result = await _backupService.restoreFromCloud();
    setState(() => _isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _handleExportLocalJson() async {
    final result = await _backupService.exportToLocalJson();
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local export generated successfully!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppTheme.accentRed),
      );
    }
  }

  void _showEditFarmProfileDialog() {
    final farmController = TextEditingController(text: _farmName);
    final farmerController = TextEditingController(text: _farmerName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Edit Farm Profile', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: farmController,
              decoration: const InputDecoration(labelText: 'Farm Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: farmerController,
              decoration: const InputDecoration(labelText: 'Owner / Farmer Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final fn = farmController.text.trim();
              final fmn = farmerController.text.trim();
              if (fn.isNotEmpty) await prefs.setString('farm_name', fn);
              if (fmn.isNotEmpty) await prefs.setString('farmer_name', fmn);
              setState(() {
                _farmName = fn.isNotEmpty ? fn : _farmName;
                _farmerName = fmn.isNotEmpty ? fmn : _farmerName;
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
