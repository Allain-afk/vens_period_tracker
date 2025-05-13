import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/pill_data.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PillReminderSettingsScreen extends StatefulWidget {
  const PillReminderSettingsScreen({super.key});

  @override
  State<PillReminderSettingsScreen> createState() => _PillReminderSettingsScreenState();
}

class _PillReminderSettingsScreenState extends State<PillReminderSettingsScreen> {
  bool _reminderEnabled = true;
  String _reminderTime = AppConstants.defaultReminderTime;
  bool _preAlarmEnabled = false;
  int _preAlarmMinutes = AppConstants.defaultPreAlarmMinutes;
  bool _autoSnoozeEnabled = false;
  int _autoSnoozeMinutes = AppConstants.defaultAutoSnoozeMinutes;
  int _autoSnoozeRepeat = AppConstants.defaultAutoSnoozeRepeat;
  
  @override
  void initState() {
    super.initState();
    
    // Load existing settings
    final pillData = Provider.of<PillProvider>(context, listen: false).pillData;
    if (pillData != null) {
      _reminderEnabled = pillData.reminderEnabled;
      _reminderTime = pillData.reminderTime;
      _preAlarmEnabled = pillData.preAlarmEnabled;
      _preAlarmMinutes = pillData.preAlarmMinutes;
      _autoSnoozeEnabled = pillData.autoSnoozeEnabled;
      _autoSnoozeMinutes = pillData.autoSnoozeMinutes;
      _autoSnoozeRepeat = pillData.autoSnoozeRepeat;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
      ),
      body: Consumer<PillProvider>(
        builder: (context, provider, child) {
          if (!provider.hasPillData) {
            return const Center(
              child: Text('No birth control method set up yet'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainReminderSettings(),
                const SizedBox(height: 16),
                _buildPreAlarmSettings(),
                const SizedBox(height: 16),
                _buildAutoSnoozeSettings(),
                const SizedBox(height: 32),
                _buildSaveButton(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainReminderSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Main Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Daily Reminder'),
              subtitle: const Text('Get a notification to take your pill'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder Time'),
                subtitle: Text(_formatTimeString(_reminderTime)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _parseTimeString(_reminderTime),
                  );
                  
                  if (picked != null) {
                    setState(() {
                      _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreAlarmSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre-Alarm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get a heads-up notification before your main reminder',
              style: TextStyle(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Pre-Alarm'),
              value: _preAlarmEnabled && _reminderEnabled,
              onChanged: _reminderEnabled 
                ? (value) {
                    setState(() {
                      _preAlarmEnabled = value;
                    });
                  }
                : null,
              contentPadding: EdgeInsets.zero,
            ),
            if (_preAlarmEnabled && _reminderEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Minutes Before'),
                subtitle: Text('$_preAlarmMinutes minutes before main reminder'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showMinutesPickerDialog(
                    initialValue: _preAlarmMinutes,
                    title: 'Minutes Before',
                    onSelected: (value) {
                      setState(() {
                        _preAlarmMinutes = value;
                      });
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAutoSnoozeSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-Snooze',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically remind you again if you miss the notification',
              style: TextStyle(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Auto-Snooze'),
              value: _autoSnoozeEnabled && _reminderEnabled,
              onChanged: _reminderEnabled 
                ? (value) {
                    setState(() {
                      _autoSnoozeEnabled = value;
                    });
                  }
                : null,
              contentPadding: EdgeInsets.zero,
            ),
            if (_autoSnoozeEnabled && _reminderEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Snooze Interval'),
                subtitle: Text('Remind again after $_autoSnoozeMinutes minutes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showMinutesPickerDialog(
                    initialValue: _autoSnoozeMinutes,
                    title: 'Snooze Interval',
                    onSelected: (value) {
                      setState(() {
                        _autoSnoozeMinutes = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat Times'),
                subtitle: Text('Snooze $_autoSnoozeRepeat times before giving up'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showNumberPickerDialog(
                    initialValue: _autoSnoozeRepeat,
                    title: 'Repeat Times',
                    minValue: 1,
                    maxValue: 5,
                    onSelected: (value) {
                      setState(() {
                        _autoSnoozeRepeat = value;
                      });
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaveButton(PillProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _saveSettings(provider);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Save Settings',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
  
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]), 
      minute: int.parse(parts[1]),
    );
  }
  
  String _formatTimeString(String timeString) {
    final timeOfDay = _parseTimeString(timeString);
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year, 
      now.month, 
      now.day, 
      timeOfDay.hour, 
      timeOfDay.minute,
    );
    return DateFormat.jm().format(dateTime); // Format time as 8:00 PM
  }
  
  void _showMinutesPickerDialog({
    required int initialValue,
    required String title,
    required Function(int) onSelected,
  }) {
    final options = [5, 10, 15, 20, 30, 45, 60];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<int>(
              title: Text('$option minutes'),
              value: option,
              groupValue: initialValue,
              onChanged: (value) {
                if (value != null) {
                  onSelected(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showNumberPickerDialog({
    required int initialValue,
    required String title,
    required int minValue,
    required int maxValue,
    required Function(int) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxValue - minValue + 1, (index) {
            final value = minValue + index;
            return RadioListTile<int>(
              title: Text('$value ${value == 1 ? 'time' : 'times'}'),
              value: value,
              groupValue: initialValue,
              onChanged: (selected) {
                if (selected != null) {
                  onSelected(selected);
                  Navigator.pop(context);
                }
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _saveSettings(PillProvider provider) {
    provider.updateReminderSettings(
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderTime,
      preAlarmEnabled: _preAlarmEnabled,
      preAlarmMinutes: _preAlarmMinutes,
      autoSnoozeEnabled: _autoSnoozeEnabled,
      autoSnoozeMinutes: _autoSnoozeMinutes,
      autoSnoozeRepeat: _autoSnoozeRepeat,
    );
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder settings saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 