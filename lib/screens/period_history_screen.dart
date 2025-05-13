import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/screens/add_period_screen.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PeriodHistoryScreen extends StatelessWidget {
  const PeriodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, child) {
          // Filter out intimacy-only records
          final periodRecords = cycleProvider.periodRecords
              .where((record) => record.flowIntensity.isNotEmpty)
              .toList();
          
          // Sort by start date (most recent first)
          periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
          
          if (periodRecords.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: periodRecords.length,
            itemBuilder: (context, index) {
              final record = periodRecords[index];
              return _buildPeriodCard(context, record, cycleProvider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPeriodScreen(
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No period data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first period',
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPeriodScreen(
                    selectedDate: DateTime.now(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Period'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPeriodCard(BuildContext context, PeriodData record, CycleProvider provider) {
    final dateFormat = DateFormat.yMMMd();
    final startDate = dateFormat.format(record.startDate);
    final endDate = record.endDate != null ? dateFormat.format(record.endDate!) : 'Not specified';
    final duration = record.durationInDays > 0 ? '${record.durationInDays} days' : 'Ongoing';
    
    // Create color based on flow intensity
    Color intensityColor;
    switch(record.flowIntensity) {
      case 'light':
        intensityColor = AppColors.primary.withOpacity(0.3);
        break;
      case 'heavy':
        intensityColor = AppColors.accent;
        break;
      case 'medium':
      default:
        intensityColor = AppColors.primary;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showDetailDialog(context, record, provider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: intensityColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: intensityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: $duration',
                          style: TextStyle(
                            color: AppColors.textMedium,
                          ),
                        ),
                        if (record.endDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'End date: $endDate',
                            style: TextStyle(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPeriodScreen(
                              selectedDate: record.startDate,
                              existingData: record,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, record, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (record.symptoms.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: record.symptoms.map((symptom) {
                    return Chip(
                      label: Text(symptom),
                      backgroundColor: AppColors.secondary.withOpacity(0.2),
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDetailDialog(BuildContext context, PeriodData record, CycleProvider provider) {
    final dateFormat = DateFormat.yMMMd();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Period Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddPeriodScreen(
                                      selectedDate: record.startDate,
                                      existingData: record,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(context, record, provider);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDetailItem('Start Date', dateFormat.format(record.startDate)),
                    record.endDate != null
                        ? _buildDetailItem('End Date', dateFormat.format(record.endDate!))
                        : _buildDetailItem('End Date', 'Not specified'),
                    _buildDetailItem('Duration', record.durationInDays > 0 
                        ? '${record.durationInDays} days' 
                        : 'Ongoing'),
                    _buildDetailItem('Flow Intensity', record.flowIntensity.toUpperCase()),
                    _buildDetailItem('Mood', record.mood),
                    if (record.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Symptoms',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: record.symptoms.map((symptom) {
                          return Chip(
                            label: Text(symptom),
                            backgroundColor: AppColors.secondary.withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(record.notes),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, PeriodData record, CycleProvider provider) {
    final dateFormat = DateFormat.yMMMd();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Period Entry'),
        content: Text('Are you sure you want to delete this period entry from ${dateFormat.format(record.startDate)}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              provider.deletePeriodRecord(record.key, forceDelete: true);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Period entry deleted'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // This is a simplified undo that just adds the record back
                      // A complete implementation would save the old key too
                      provider.addPeriodRecord(record);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Period History Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('On this screen, you can:'),
            SizedBox(height: 8),
            Text('• View all your recorded periods'),
            Text('• Tap any period to see full details'),
            Text('• Edit incorrect information'),
            Text('• Delete accidental entries'),
            SizedBox(height: 16),
            Text('If you made a mistake, use the menu (three dots) to edit or delete an entry.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 