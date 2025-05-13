import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/pill_data.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class SetupPillScreen extends StatefulWidget {
  final PillData? existingData;
  
  const SetupPillScreen({
    super.key,
    this.existingData,
  });

  @override
  State<SetupPillScreen> createState() => _SetupPillScreenState();
}

class _SetupPillScreenState extends State<SetupPillScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _contraceptiveMethod = ContraceptiveMethod.pill;
  String _brandName = '';
  int _activePillCount = AppConstants.defaultActivePillCount;
  int _placeboPillCount = AppConstants.defaultPlaceboPillCount;
  DateTime _startDate = DateTime.now();
  String _reminderTime = AppConstants.defaultReminderTime;
  bool _reminderEnabled = true;
  
  bool get _isEditing => widget.existingData != null;
  
  @override
  void initState() {
    super.initState();
    
    // If editing existing data, load values
    if (_isEditing) {
      _contraceptiveMethod = widget.existingData!.contraceptiveMethod;
      _brandName = widget.existingData!.brandName;
      _activePillCount = widget.existingData!.activePillCount;
      _placeboPillCount = widget.existingData!.placeboPillCount;
      _startDate = widget.existingData!.startDate;
      _reminderTime = widget.existingData!.reminderTime;
      _reminderEnabled = widget.existingData!.reminderEnabled;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Birth Control' : 'Set Up Birth Control'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Contraceptive Method'),
              _buildMethodDropdown(),
              
              const SizedBox(height: 16),
              _buildSectionHeader('Brand (Optional)'),
              _buildBrandInput(),
              
              const SizedBox(height: 16),
              _buildSectionHeader('Pack Configuration'),
              _buildPillCountInputs(),
              
              const SizedBox(height: 16),
              _buildSectionHeader('Start Date'),
              _buildStartDatePicker(),
              
              const SizedBox(height: 16),
              _buildSectionHeader('Reminder Settings'),
              _buildReminderSettings(),
              
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _contraceptiveMethod,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select method',
      ),
      items: List.generate(
        ContraceptiveMethod.values.length,
        (index) => DropdownMenuItem(
          value: ContraceptiveMethod.values[index],
          child: Text(ContraceptiveMethod.displayNames[index]),
        ),
      ),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _contraceptiveMethod = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a contraceptive method';
        }
        return null;
      },
    );
  }
  
  Widget _buildBrandInput() {
    return TextFormField(
      initialValue: _brandName,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter brand name (optional)',
      ),
      onChanged: (value) {
        setState(() {
          _brandName = value;
        });
      },
    );
  }
  
  Widget _buildPillCountInputs() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _activePillCount.toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Active Pills',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _activePillCount = int.tryParse(value) ?? AppConstants.defaultActivePillCount;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final count = int.tryParse(value);
              if (count == null || count <= 0) {
                return 'Invalid';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: _placeboPillCount.toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Placebo Pills',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _placeboPillCount = int.tryParse(value) ?? AppConstants.defaultPlaceboPillCount;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final count = int.tryParse(value);
              if (count == null || count < 0) {
                return 'Invalid';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStartDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime.now().subtract(const Duration(days: 100)),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        
        if (picked != null && picked != _startDate) {
          setState(() {
            _startDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Text(
              DateFormat.yMMMd().format(_startDate),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReminderSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Daily Reminder'),
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
          InkWell(
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeString(_reminderTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can set up additional reminder options after completing the initial setup.',
            style: TextStyle(
              color: AppColors.textMedium,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          _isEditing ? 'Save Changes' : 'Complete Setup',
          style: const TextStyle(fontSize: 16),
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
  
  void _saveData() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PillProvider>(context, listen: false);
      
      // Calculate next refill date (7 days before pack ends)
      final totalDays = _activePillCount + _placeboPillCount;
      final nextRefillDate = _startDate.add(Duration(days: totalDays - 7));
      
      final pillData = PillData(
        contraceptiveMethod: _contraceptiveMethod,
        activePillCount: _activePillCount,
        placeboPillCount: _placeboPillCount,
        startDate: _startDate,
        nextRefillDate: nextRefillDate,
        reminderTime: _reminderTime,
        reminderEnabled: _reminderEnabled,
        brandName: _brandName,
        pillLogs: _isEditing ? widget.existingData!.pillLogs : [],
        preAlarmEnabled: _isEditing ? widget.existingData!.preAlarmEnabled : false,
        preAlarmMinutes: _isEditing ? widget.existingData!.preAlarmMinutes : AppConstants.defaultPreAlarmMinutes,
        autoSnoozeEnabled: _isEditing ? widget.existingData!.autoSnoozeEnabled : false,
        autoSnoozeMinutes: _isEditing ? widget.existingData!.autoSnoozeMinutes : AppConstants.defaultAutoSnoozeMinutes,
        autoSnoozeRepeat: _isEditing ? widget.existingData!.autoSnoozeRepeat : AppConstants.defaultAutoSnoozeRepeat,
      );
      
      if (_isEditing) {
        provider.updatePillData(pillData);
      } else {
        provider.setupPillData(pillData);
      }
      
      Navigator.pop(context);
    }
  }
} 