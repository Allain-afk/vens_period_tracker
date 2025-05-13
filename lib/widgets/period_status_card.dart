import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PeriodStatusCard extends StatelessWidget {
  const PeriodStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        // Get reference to pill provider to check if user is using hormonal birth control
        final pillProvider = Provider.of<PillProvider>(context, listen: false);
        final isUsingHormonalBC = pillProvider.isUsingHormonalBirthControl;

        // Status determination
        String statusTitle;
        String statusMessage;
        Color statusColor;
        IconData statusIcon;
        
        // Sort records by date (most recent first)
        final records = [...cycleProvider.periodRecords];
        records.sort((a, b) => b.startDate.compareTo(a.startDate));
        
        final today = DateTime.now();
        
        // Check if currently on period (only check recent periods)
        bool isOnPeriod = false;
        if (records.isNotEmpty) {
          // Only check the most recent period records
          for (final record in records.take(3)) {
            // Skip "intimacy-only" records (those without flow intensity)
            if (record.flowIntensity.isEmpty) {
              continue;
            }
            
            if (record.endDate == null) {
              // Only start date recorded - period is ongoing if it started within last 7 days
              if (today.difference(record.startDate).inDays <= 7 && 
                  !today.isBefore(record.startDate)) {
                isOnPeriod = true;
                break;
              }
            } else {
              // Check if today is between start and end date
              if (today.isAfter(record.startDate.subtract(const Duration(days: 1))) && 
                  today.isBefore(record.endDate!.add(const Duration(days: 1)))) {
                isOnPeriod = true;
                break;
              }
            }
          }
        }
        
        // Get next period date - pass context for BC awareness
        final nextPeriodDate = cycleProvider.getNextPeriodDate(context: context);
        
        // Get fertility window - pass context for BC awareness
        final fertilityWindow = cycleProvider.getFertilityWindow(context: context);
        bool isDuringFertileWindow = false;
        bool isOvulationDay = false;
        
        if (fertilityWindow != null) {
          final fertileStart = fertilityWindow['start']!;
          final fertileEnd = fertilityWindow['end']!;
          final ovulationDate = fertilityWindow['ovulation']!;
          
          isDuringFertileWindow = today.isAfter(fertileStart.subtract(const Duration(days: 1))) && 
                                  today.isBefore(fertileEnd.add(const Duration(days: 1)));
          
          isOvulationDay = isSameDay(today, ovulationDate);
        }
        
        // Set status message based on current state
        if (isOnPeriod) {
          statusTitle = 'Period in Progress';
          statusMessage = isUsingHormonalBC 
              ? 'You are currently having withdrawal bleeding.'
              : 'You are currently on your period.';
          statusColor = AppColors.accent;
          statusIcon = Icons.opacity;
        } else if (isOvulationDay) {
          statusTitle = 'Ovulation Day';
          statusMessage = 'Today is your estimated ovulation day.';
          statusColor = AppColors.success;
          statusIcon = Icons.egg_alt;
        } else if (isDuringFertileWindow) {
          statusTitle = 'Fertile Window';
          statusMessage = 'You are in your fertile window.';
          statusColor = AppColors.success.withOpacity(0.7);
          statusIcon = Icons.favorite;
        } else if (nextPeriodDate != null) {
          final daysUntil = nextPeriodDate.difference(today).inDays;
          
          if (daysUntil <= 3 && daysUntil > 0) {
            statusTitle = isUsingHormonalBC ? 'Withdrawal Bleeding Soon' : 'Period Coming Soon';
            statusMessage = isUsingHormonalBC
                ? 'Your withdrawal bleeding is expected to start in $daysUntil days.'
                : 'Your period is expected to start in $daysUntil days.';
            statusColor = AppColors.primary;
            statusIcon = Icons.event_available;
          } else if (daysUntil == 0) {
            statusTitle = isUsingHormonalBC ? 'Withdrawal Bleeding Expected' : 'Period Expected Today';
            statusMessage = isUsingHormonalBC
                ? 'Your withdrawal bleeding is expected to start today.'
                : 'Your period is expected to start today.';
            statusColor = AppColors.primary;
            statusIcon = Icons.event;
          } else {
            statusTitle = isUsingHormonalBC ? 'Next Withdrawal Bleeding' : 'Next Period';
            final dateFormat = DateFormat.MMMd();
            statusMessage = isUsingHormonalBC
                ? 'Your next withdrawal bleeding is expected on ${dateFormat.format(nextPeriodDate)}.'
                : 'Your next period is expected on ${dateFormat.format(nextPeriodDate)}.';
            statusColor = AppColors.secondary;
            statusIcon = Icons.calendar_today;
          }
        } else {
          statusTitle = 'Welcome!';
          statusMessage = 'Add your period data to see predictions.';
          statusColor = AppColors.textLight;
          statusIcon = Icons.waving_hand;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.8),
                    statusColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        statusTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (cycleProvider.periodRecords.isEmpty)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_period');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: statusColor,
                      ),
                      child: const Text('Add Period Data'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 