import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class IntimacyLogScreen extends StatefulWidget {
  final DateTime? initialDate;
  
  const IntimacyLogScreen({
    super.key, 
    this.initialDate,
  });

  @override
  State<IntimacyLogScreen> createState() => _IntimacyLogScreenState();
}

class _IntimacyLogScreenState extends State<IntimacyLogScreen> {
  late DateTime _selectedDate;
  bool _hadIntimacy = true;
  bool _wasProtected = true;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Intimacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date picker
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_month, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Intimacy toggle
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Had intimacy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _hadIntimacy,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _hadIntimacy = value;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Protected toggle - only show if had intimacy
                    if (_hadIntimacy)
                      Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Protected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _wasProtected,
                            activeColor: AppColors.accent,
                            onChanged: (value) {
                              setState(() {
                                _wasProtected = value;
                              });
                            },
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Notes field
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Center(
              child: ElevatedButton(
                onPressed: _saveIntimacyData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveIntimacyData() {
    // Create the intimacy data entry
    final intimacyEntry = IntimacyData(
      date: _selectedDate,
      hadIntimacy: _hadIntimacy,
      wasProtected: _wasProtected,
      notes: _notesController.text,
    );
    
    // Get the cycle provider
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    
    // Add the intimacy data to the appropriate period record or create a new one
    cycleProvider.addIntimacyData(intimacyEntry);
    
    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Intimacy data saved successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
    
    // Navigate back
    Navigator.pop(context);
  }
} 