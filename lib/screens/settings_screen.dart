import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vens_period_tracker/utils/constants.dart';
import 'package:vens_period_tracker/utils/notification_service.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/screens/pill_reminder_settings_screen.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/models/pill_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _periodNotifications = true;
  bool _ovulationNotifications = true;
  bool _fertileDaysNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _periodNotifications = prefs.getBool('period_notifications') ?? true;
      _ovulationNotifications = prefs.getBool('ovulation_notifications') ?? true;
      _fertileDaysNotifications = prefs.getBool('fertile_days_notifications') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('period_notifications', _periodNotifications);
    await prefs.setBool('ovulation_notifications', _ovulationNotifications);
    await prefs.setBool('fertile_days_notifications', _fertileDaysNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Period Notifications'),
              subtitle: const Text('Get notified before your period starts'),
              value: _periodNotifications,
              onChanged: (value) {
                setState(() {
                  _periodNotifications = value;
                });
                _saveSettings();
                _updateNotifications();
              },
            ),
            SwitchListTile(
              title: const Text('Ovulation Notifications'),
              subtitle: const Text('Get notified on your ovulation day'),
              value: _ovulationNotifications,
              onChanged: (value) {
                setState(() {
                  _ovulationNotifications = value;
                });
                _saveSettings();
                _updateNotifications();
              },
            ),
            SwitchListTile(
              title: const Text('Fertile Days Notifications'),
              subtitle: const Text('Get notified during your fertile window'),
              value: _fertileDaysNotifications,
              onChanged: (value) {
                setState(() {
                  _fertileDaysNotifications = value;
                });
                _saveSettings();
                _updateNotifications();
              },
            ),
            ListTile(
              title: const Text('Pill Reminders'),
              subtitle: const Text('Configure birth control pill reminders'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PillReminderSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            ListTile(
              title: const Text('Backup and Restore'),
              subtitle: const Text('Back up your data or restore from backup'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showBackupOptions();
              },
            ),
            ListTile(
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all your data permanently'),
              trailing: const Icon(Icons.delete_outline, color: Colors.red),
              onTap: () {
                _showClearDataConfirmation();
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Would launch privacy policy webpage
              },
            ),
            ListTile(
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Would launch terms of service webpage
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('user_preferences').listenable(),
                builder: (context, box, child) {
                  return Text(
                    'Version 1.3.0+3',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  void _updateNotifications() {
    if (!_periodNotifications && !_ovulationNotifications && !_fertileDaysNotifications) {
      _notificationService.cancelAllNotifications();
    } else {
      // Re-register notifications based on current selections
      final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
      cycleProvider.updateNotifications();
    }
  }
  
  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup & Restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.backup),
                label: const Text('Backup Data'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup functionality will be implemented in a future update'),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restore Data'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restore functionality will be implemented in a future update'),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
  
  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all your data including period history, pill tracking, and settings. This action cannot be undone.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Clear all Hive boxes
                await Hive.box<PeriodData>('period_data').clear();
                await Hive.box<PillData>('pill_data').clear();
                await Hive.box('user_preferences').clear();
                
                // Reset providers
                Provider.of<CycleProvider>(context, listen: false).resetData();
                Provider.of<PillProvider>(context, listen: false).resetData();
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been cleared'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
} 