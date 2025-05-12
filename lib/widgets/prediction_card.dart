import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd();
    
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        final nextPeriod = cycleProvider.getNextPeriodDate();
        final fertilityWindow = cycleProvider.getFertilityWindow();
        
        if (nextPeriod == null) {
          return const SizedBox.shrink(); // No data to show
        }
        
        // Determine next period end date
        final nextPeriodEnd = nextPeriod.add(
          Duration(days: cycleProvider.averagePeriodLength - 1),
        );
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Next period prediction
                  _buildPredictionItem(
                    icon: Icons.opacity,
                    title: 'Next Period',
                    date: '${dateFormat.format(nextPeriod)} - ${dateFormat.format(nextPeriodEnd)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  
                  // Fertility window
                  if (fertilityWindow != null) ...[
                    _buildPredictionItem(
                      icon: Icons.favorite,
                      title: 'Fertility Window',
                      date: '${dateFormat.format(fertilityWindow['start']!)} - ${dateFormat.format(fertilityWindow['end']!)}',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    
                    // Ovulation day
                    _buildPredictionItem(
                      icon: Icons.egg_alt,
                      title: 'Ovulation Day',
                      date: dateFormat.format(fertilityWindow['ovulation']!),
                      color: AppColors.success,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      cycleProvider.getPredictionAccuracy(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPredictionItem({
    required IconData icon,
    required String title,
    required String date,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 