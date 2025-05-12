import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/screens/intimacy/intimacy_log_screen.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class IntimacyHistoryScreen extends StatelessWidget {
  const IntimacyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intimacy History'),
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
          final allIntimacyData = cycleProvider.getAllIntimacyData();
          
          if (allIntimacyData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No intimacy data yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add your first entry',
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
                          builder: (context) => const IntimacyLogScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort intimacy data by date (most recent first)
          allIntimacyData.sort((a, b) => b.date.compareTo(a.date));
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Showing ${allIntimacyData.length} entries',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: allIntimacyData.length,
                  itemBuilder: (context, index) {
                    final entry = allIntimacyData[index];
                    return _buildIntimacyCard(context, entry);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IntimacyLogScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildIntimacyCard(BuildContext context, IntimacyData entry) {
    final dateFormat = DateFormat.yMMMd();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: entry.hadIntimacy 
                        ? AppColors.primary 
                        : AppColors.textLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(entry.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (entry.hadIntimacy) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.shield,
                              color: entry.wasProtected 
                                  ? AppColors.success 
                                  : AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.wasProtected 
                                  ? 'Protected' 
                                  : 'Unprotected',
                              style: TextStyle(
                                color: entry.wasProtected 
                                    ? AppColors.success 
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'No intimacy',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (entry.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.notes,
                          style: const TextStyle(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textLight,
                  ),
                  onPressed: () {
                    _showDeleteConfirmation(context, entry);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, IntimacyData entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this intimacy entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
              cycleProvider.deleteIntimacyData(entry);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intimacy History Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('On this screen, you can:'),
            SizedBox(height: 8),
            Text('• View all your intimacy records'),
            Text('• Delete entries if needed'),
            Text('• Add new intimacy records using the + button'),
            SizedBox(height: 16),
            Text('Intimacy data is color-coded:'),
            SizedBox(height: 8),
            Text('• Green: Protected intimacy'),
            Text('• Yellow: Unprotected intimacy'),
            SizedBox(height: 16),
            Text('This information helps with fertility tracking.'),
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