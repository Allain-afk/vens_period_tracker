import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class AddPeriodScreen extends StatefulWidget {
  final DateTime selectedDate;
  final PeriodData? existingData;

  const AddPeriodScreen({
    super.key,
    required this.selectedDate,
    this.existingData,
  });

  @override
  State<AddPeriodScreen> createState() => _AddPeriodScreenState();
}

class _AddPeriodScreenState extends State<AddPeriodScreen> {
  late DateTime _startDate;
  DateTime? _endDate;
  String _flowIntensity = FlowIntensity.medium;
  List<String> _selectedSymptoms = [];
  String _mood = MoodType.neutral;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _startDate = widget.existingData!.startDate;
      _endDate = widget.existingData!.endDate;
      _flowIntensity = widget.existingData!.flowIntensity;
      _selectedSymptoms = List<String>.from(widget.existingData!.symptoms);
      _mood = widget.existingData!.mood;
      _notesController.text = widget.existingData!.notes;
    } else {
      _startDate = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null ? 'Edit Period Data' : 'Add Period Data',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selection section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Period Dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Start date picker
                      _buildDateField(
                        label: 'Start Date',
                        value: _startDate,
                        onTap: () => _selectDate(context, true),
                      ),
                      const SizedBox(height: 16),
                      // End date picker
                      _buildDateField(
                        label: 'End Date (Optional)',
                        value: _endDate,
                        onTap: () => _selectDate(context, false),
                        showClear: _endDate != null,
                        onClear: () => setState(() => _endDate = null),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Flow intensity section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flow Intensity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFlowIntensitySelector(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Symptoms section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Symptoms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SymptomType.values.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return FilterChip(
                            label: Text(symptom),
                            selected: isSelected,
                            selectedColor: AppColors.secondary,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mood section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMoodSelector(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any additional notes here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePeriodData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.existingData != null ? 'Update' : 'Save',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              if (widget.existingData != null) ...[
                const SizedBox(height: 16),
                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Date selection field
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function() onTap,
    bool showClear = false,
    Function()? onClear,
  }) {
    final dateFormat = DateFormat.yMMMd();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null ? dateFormat.format(value) : 'Select Date',
                style: TextStyle(
                  color: value != null
                      ? Colors.black87
                      : Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ),
            if (showClear)
              IconButton(
                icon: const Icon(
                  Icons.clear,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }

  // Flow intensity selector
  Widget _buildFlowIntensitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFlowIntensityOption(
          label: 'Light',
          value: FlowIntensity.light,
          color: AppColors.flowLight,
        ),
        _buildFlowIntensityOption(
          label: 'Medium',
          value: FlowIntensity.medium,
          color: AppColors.flowMedium,
        ),
        _buildFlowIntensityOption(
          label: 'Heavy',
          value: FlowIntensity.heavy,
          color: AppColors.flowHeavy,
        ),
      ],
    );
  }

  // Flow intensity option button
  Widget _buildFlowIntensityOption({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _flowIntensity == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _flowIntensity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Mood selector
  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: MoodType.values.map((mood) {
        final isSelected = _mood == mood;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _mood = mood;
            });
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getMoodIcon(mood),
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Get icon for mood
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case MoodType.happy:
        return Icons.sentiment_very_satisfied;
      case MoodType.sad:
        return Icons.sentiment_very_dissatisfied;
      case MoodType.irritable:
        return Icons.sentiment_dissatisfied;
      case MoodType.anxious:
        return Icons.psychology;
      case MoodType.energetic:
        return Icons.bolt;
      case MoodType.tired:
        return Icons.bedtime;
      case MoodType.neutral:
      default:
        return Icons.sentiment_neutral;
    }
  }

  // Date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? _startDate);
    final firstDate = isStartDate
        ? DateTime(2020)
        : _startDate; // End date must be after start date
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 1)), // Allow selecting today
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Adjust end date if it's before the new start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  // Save period data
  void _savePeriodData() {
    final periodData = PeriodData(
      startDate: _startDate,
      endDate: _endDate,
      flowIntensity: _flowIntensity,
      symptoms: _selectedSymptoms,
      mood: _mood,
      notes: _notesController.text,
    );
    
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    
    if (widget.existingData != null) {
      cycleProvider.updatePeriodRecord(widget.existingData!.key.toString(), periodData);
    } else {
      cycleProvider.addPeriodRecord(periodData);
    }
    
    Navigator.pop(context);
  }

  // Confirm delete dialog
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Period Record'),
          content: const Text(
            'Are you sure you want to delete this period record? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                
                // Delete the record
                final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
                cycleProvider.deletePeriodRecord(widget.existingData!.key.toString());
                
                // Return to previous screen
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 