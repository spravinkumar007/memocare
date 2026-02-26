import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/backup_service.dart';
import '../services/reminder_scheduler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackup = false;
  bool _isExporting = false;
  final BackupService _backupService = BackupService();
  final ReminderScheduler _scheduler = ReminderScheduler();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // App Settings Section (3D)
          _build3DSection('App Settings', [
            _build3DSwitchTile(
              'Enable Notifications',
              'Receive reminders and alerts',
              Icons.notifications,
              Colors.blue,
              _notificationsEnabled,
                  (value) {
                setState(() => _notificationsEnabled = value);
                if (value) {
                  _scheduler.startScheduler();
                } else {
                  _scheduler.stopScheduler();
                }
              },
            ),
            _build3DSwitchTile(
              'Dark Mode',
              'Switch to dark theme',
              Icons.dark_mode,
              Colors.purple,
              _darkModeEnabled,
                  (value) => setState(() => _darkModeEnabled = value),
            ),
            _build3DSwitchTile(
              'Auto Backup',
              'Automatically backup data',
              Icons.backup,
              Colors.green,
              _autoBackup,
                  (value) => setState(() => _autoBackup = value),
            ),
          ]),

          const SizedBox(height: 16),

          // Data Management Section (3D)
          _build3DSection('Data Management', [
            _build3DListTile(
              'Export Data',
              'Create a backup of all your data',
              Icons.backup,
              Colors.blue,
              _isExporting ? Icons.download : null,
              _isExporting,
              _exportData,
            ),
            const Divider(height: 1, indent: 72),
            _build3DListTile(
              'Import Data',
              'Restore from backup',
              Icons.restore,
              Colors.green,
              Icons.upload,
              false,
              _importData,
            ),
            const Divider(height: 1, indent: 72),
            _build3DListTile(
              'Clear All Data',
              'Reset app to initial state',
              Icons.delete_forever,
              Colors.red,
              Icons.warning,
              false,
              _clearData,
            ),
          ]),

          const SizedBox(height: 16),

          // About Section (3D)
          _build3DSection('About', [
            _build3DInfoTile(
              'Version',
              '1.0.0',
              Icons.info,
              Colors.blue,
            ),
            const Divider(height: 1, indent: 72),
            _build3DInfoTile(
              'Last Updated',
              'November 2024',
              Icons.update,
              Colors.orange,
            ),
            const Divider(height: 1, indent: 72),
            _build3DActionTile(
              'Rate the App',
              Icons.favorite,
              Colors.red,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rate feature coming soon!'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _build3DSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(-2, -2),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _build3DSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      bool value,
      Function(bool) onChanged,
      ) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: color,
      activeTrackColor: color.withOpacity(0.5),
    );
  }

  Widget _build3DListTile(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      IconData? trailingIcon,
      bool isLoading,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: isLoading
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      )
          : Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(trailingIcon ?? Icons.arrow_forward_ios, color: color, size: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _build3DInfoTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _build3DActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
      ),
      onTap: onTap,
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      await _backupService.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import feature coming soon!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Clear All Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
            'This will delete all your data. This action cannot be undone. '
                'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      if (mounted) {
        _scheduler.stopScheduler();
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _scheduler.stopScheduler();
    super.dispose();
  }
}