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
  late DateTime _selectedDate;
  PeriodData? _lastActivePeriod;
  bool _isPeriodStart = true;
  bool _isPeriodEnd = false;
  bool _isContinuingPeriod = false;
  String _flowIntensity = FlowIntensity.medium;
  List<String> _selectedSymptoms = [];
  String _mood = MoodType.neutral;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    
    if (widget.existingData != null) {
      // If we're editing an existing record
      _flowIntensity = widget.existingData!.flowIntensity;
      _selectedSymptoms = List<String>.from(widget.existingData!.symptoms);
      _mood = widget.existingData!.mood;
      _notesController.text = widget.existingData!.notes;
      _isPeriodEnd = widget.existingData!.endDate != null;
      print('Editing existing record: ${widget.existingData!.key}');
    } else {
      // Check if there's an ongoing period
      _checkForActivePeriod();
    }
  }

  void _checkForActivePeriod() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
      
      // Find the most recent period without an end date
      final periods = cycleProvider.periodRecords;
      print('Checking for active period. Total records: ${periods.length}');
      
      if (periods.isNotEmpty) {
        // Sort by start date, newest first
        final sortedPeriods = List<PeriodData>.from(periods);
        sortedPeriods.sort((a, b) => b.startDate.compareTo(a.startDate));
        
        PeriodData? activePeriod;
        for (final period in sortedPeriods) {
          print('Period record: ${period.key}, Start: ${period.startDate}, End: ${period.endDate}');
          // Check if this period is active (has no end date)
          if (period.endDate == null) {
            activePeriod = period;
            break;
          }
        }
        
        if (activePeriod != null) {
          print('Found active period: ${activePeriod.key}, Started: ${activePeriod.startDate}');
          
          // Check if selected date is the same as the start date of active period
          final isSameStartDate = cycleProvider.isSameDay(_selectedDate, activePeriod.startDate);
          
          // Check if selected date is after the start date of active period
          final isAfterStartDate = _selectedDate.isAfter(activePeriod.startDate) && 
                                  !isSameStartDate;
          
          // Update state based on selected date relationship to active period
          setState(() {
            _lastActivePeriod = activePeriod;
            
            if (isAfterStartDate) {
              print('Selected date is after active period start. Setting as continuing period');
              _isPeriodStart = false;
              _isContinuingPeriod = true;
              _isPeriodEnd = false;
            } else if (isSameStartDate) {
              print('Selected date is same as period start date');
              _isPeriodStart = true;
              _isContinuingPeriod = false;
              _isPeriodEnd = false;
            } else {
              print('Selected date is before active period start');
              _isPeriodStart = true;
              _isContinuingPeriod = false;
              _isPeriodEnd = false;
            }
          });
        } else {
          print('No active period found (all periods have end dates)');
          setState(() {
            _isPeriodStart = true;
            _isContinuingPeriod = false;
            _isPeriodEnd = false;
          });
        }
      } else {
        print('No period records found');
      }
    });
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
          widget.existingData != null ? 'Edit Period Entry' : 'Add Period Entry',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date display
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
                        'Date',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        value: _selectedDate,
                        onTap: _selectDate,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Period status section
              if (widget.existingData == null || 
                  !widget.existingData!.startDate.isAtSameMomentAs(_selectedDate)) ...[
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
                          'Period Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_lastActivePeriod != null && 
                            _selectedDate.isAfter(_lastActivePeriod!.startDate) &&
                            !Provider.of<CycleProvider>(context, listen: false).isSameDay(
                              _selectedDate, _lastActivePeriod!.startDate)) ...[
                          // Show continuing period option for active periods
                          _buildPeriodStatusOption(
                            label: 'Continuing period from ${DateFormat.yMMMd().format(_lastActivePeriod!.startDate)}',
                            value: true,
                            groupValue: _isContinuingPeriod,
                            onChanged: (value) {
                              setState(() {
                                _isContinuingPeriod = value!;
                                _isPeriodStart = false;
                                _isPeriodEnd = false;
                              });
                            },
                          ),
                          _buildPeriodStatusOption(
                            label: 'End of period',
                            value: true,
                            groupValue: _isPeriodEnd,
                            onChanged: (value) {
                              setState(() {
                                _isPeriodEnd = value!;
                                _isContinuingPeriod = !value;
                              });
                            },
                          ),
                        ] else ...[
                          // Show options for new period
                          _buildPeriodStatusOption(
                            label: 'First day of period',
                            value: true,
                            groupValue: _isPeriodStart,
                            onChanged: (value) {
                              setState(() {
                                _isPeriodStart = value!;
                                _isPeriodEnd = false;
                                _isContinuingPeriod = false;
                              });
                            },
                          ),
                          if (_lastActivePeriod == null) ...[
                            _buildPeriodStatusOption(
                              label: 'Last day of period',
                              value: true,
                              groupValue: _isPeriodEnd,
                              onChanged: (value) {
                                setState(() {
                                  _isPeriodEnd = value!;
                                  _isPeriodStart = !value;
                                  _isContinuingPeriod = false;
                                });
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
              
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
    required DateTime value,
    required Function() onTap,
  }) {
    final dateFormat = DateFormat.yMMMEd();
    
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
                dateFormat.format(value),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Period status option
  Widget _buildPeriodStatusOption({
    required String label,
    required bool value,
    required bool groupValue,
    required Function(bool?) onChanged,
  }) {
    return RadioListTile<bool>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
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
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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
        _selectedDate = pickedDate;
        _checkForActivePeriod(); // Recheck for active period with the new date
      });
    }
  }

  // Save period data
  void _savePeriodData() {
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    
    print('Saving period data:');
    print('- isPeriodStart: $_isPeriodStart');
    print('- isPeriodEnd: $_isPeriodEnd');
    print('- isContinuingPeriod: $_isContinuingPeriod');
    print('- hasActivePeriod: ${_lastActivePeriod != null}');
    if (_lastActivePeriod != null) {
      print('- activePeriodKey: ${_lastActivePeriod!.key}');
    }
    
    if (widget.existingData != null) {
      // Updating existing record
      print('Updating existing record: ${widget.existingData!.key}');
      final periodData = PeriodData(
        startDate: widget.existingData!.startDate,
        endDate: _isPeriodEnd ? _selectedDate : widget.existingData!.endDate,
        flowIntensity: _flowIntensity,
        symptoms: _selectedSymptoms,
        mood: _mood,
        notes: _notesController.text,
        intimacyData: widget.existingData!.intimacyData,
      );
      
      cycleProvider.updatePeriodRecord(widget.existingData!.key.toString(), periodData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period data updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_lastActivePeriod != null && (_isContinuingPeriod || _isPeriodEnd)) {
      // Continuing an existing period or marking end date
      print('Continuing/ending active period: ${_lastActivePeriod!.key}');
      print('- Original start date: ${_lastActivePeriod!.startDate}');
      print('- Setting end date: ${_isPeriodEnd ? _selectedDate : "none"}');
      
      final updatedPeriod = PeriodData(
        startDate: _lastActivePeriod!.startDate,
        endDate: _isPeriodEnd ? _selectedDate : null,
        flowIntensity: _flowIntensity,
        symptoms: [..._lastActivePeriod!.symptoms, ..._selectedSymptoms].toSet().toList(),
        mood: _mood,
        notes: _notesController.text.isNotEmpty ? 
              "${_lastActivePeriod!.notes}\n${_notesController.text}" : 
              _lastActivePeriod!.notes,
        intimacyData: _lastActivePeriod!.intimacyData,
      );
      
      cycleProvider.updatePeriodRecord(_lastActivePeriod!.key.toString(), updatedPeriod);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPeriodEnd ? 
                      'Period end date set to ${DateFormat.yMMMd().format(_selectedDate)}' : 
                      'Period entry continued'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // New period start
      print('Creating new period record with start date: $_selectedDate');
      final periodData = PeriodData(
        startDate: _selectedDate,
        endDate: _isPeriodEnd ? _selectedDate : null, // If it's both start and end, set end date
        flowIntensity: _flowIntensity,
        symptoms: _selectedSymptoms,
        mood: _mood,
        notes: _notesController.text,
      );
      
      cycleProvider.addPeriodRecord(periodData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New period entry added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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