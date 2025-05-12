import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Statistics'),
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, child) {
          final hasData = cycleProvider.periodRecords.isNotEmpty;
          
          if (!hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No data available yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your period data to see insights',
                    style: TextStyle(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Calculate statistics
          final cycleStats = _calculateCycleStats(cycleProvider.periodRecords);
          final symptomStats = _calculateSymptomStats(cycleProvider.periodRecords);
          final moodStats = _calculateMoodStats(cycleProvider.periodRecords);
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cycle length stats
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
                            'Cycle Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            'Average Cycle Length', 
                            '${cycleProvider.averageCycleLength} days'
                          ),
                          const Divider(),
                          _buildStatRow(
                            'Shortest Cycle', 
                            '${cycleStats['minCycle']} days'
                          ),
                          const Divider(),
                          _buildStatRow(
                            'Longest Cycle', 
                            '${cycleStats['maxCycle']} days'
                          ),
                          const Divider(),
                          _buildStatRow(
                            'Average Period Length', 
                            '${cycleProvider.averagePeriodLength} days'
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (cycleProvider.averagePeriodLength / cycleProvider.averageCycleLength),
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your period typically lasts about ${(cycleProvider.averagePeriodLength / cycleProvider.averageCycleLength * 100).round()}% of your cycle',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Common symptoms
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
                            'Most Common Symptoms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          symptomStats.isEmpty
                              ? const Text(
                                  'No symptom data recorded yet',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Column(
                                  children: symptomStats.entries.take(5).map((entry) {
                                    final percentage = entry.value / cycleProvider.periodRecords.length * 100;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${entry.key} (${percentage.round()}%)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: percentage / 100,
                                            backgroundColor: Colors.grey.shade200,
                                            color: AppColors.accent,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mood patterns
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
                            'Mood Patterns',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          moodStats.isEmpty
                              ? const Text(
                                  'No mood data recorded yet',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Column(
                                  children: moodStats.entries.map((entry) {
                                    final percentage = entry.value / cycleProvider.periodRecords.length * 100;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getMoodIcon(entry.key),
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${entry.key} (${percentage.round()}%)',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                LinearProgressIndicator(
                                                  value: percentage / 100,
                                                  backgroundColor: Colors.grey.shade200,
                                                  color: AppColors.secondary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Your history section
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
                            'Your History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...cycleProvider.periodRecords
                              .take(10)
                              .map((record) => _buildHistoryItem(record))
                              .toList(),
                          if (cycleProvider.periodRecords.length > 10)
                            const Center(
                              child: Text(
                                'Showing 10 most recent entries',
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
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PeriodData record) {
    final dateFormat = DateFormat.yMMMd();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFlowColor(record.flowIntensity).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateFormat.format(record.startDate),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getFlowColor(record.flowIntensity),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.endDate != null
                      ? 'Duration: ${record.durationInDays} days'
                      : 'Start date only',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (record.symptoms.isNotEmpty)
                  Text(
                    'Symptoms: ${record.symptoms.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                if (record.mood.isNotEmpty && record.mood != MoodType.neutral)
                  Text(
                    'Mood: ${record.mood}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
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
  
  Color _getFlowColor(String flow) {
    switch (flow) {
      case FlowIntensity.light:
        return AppColors.flowLight;
      case FlowIntensity.medium:
        return AppColors.flowMedium;
      case FlowIntensity.heavy:
        return AppColors.flowHeavy;
      default:
        return AppColors.flowMedium;
    }
  }
  
  // Calculate cycle statistics
  Map<String, int> _calculateCycleStats(List<PeriodData> records) {
    if (records.length < 2) {
      return {
        'minCycle': 0,
        'maxCycle': 0,
      };
    }
    
    List<int> cycleLengths = [];
    // Sort records by date
    final sortedRecords = List<PeriodData>.from(records)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    
    for (int i = 1; i < sortedRecords.length; i++) {
      final daysBetween = sortedRecords[i].startDate
          .difference(sortedRecords[i-1].startDate)
          .inDays;
      
      if (daysBetween >= AppConstants.minCycleLength && 
          daysBetween <= AppConstants.maxCycleLength) {
        cycleLengths.add(daysBetween);
      }
    }
    
    if (cycleLengths.isEmpty) {
      return {
        'minCycle': 0,
        'maxCycle': 0,
      };
    }
    
    return {
      'minCycle': cycleLengths.reduce((a, b) => a < b ? a : b),
      'maxCycle': cycleLengths.reduce((a, b) => a > b ? a : b),
    };
  }
  
  // Calculate symptom statistics
  Map<String, int> _calculateSymptomStats(List<PeriodData> records) {
    final Map<String, int> symptomCounts = {};
    
    for (final record in records) {
      for (final symptom in record.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }
    
    // Sort by frequency
    final sortedEntries = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }
  
  // Calculate mood statistics
  Map<String, int> _calculateMoodStats(List<PeriodData> records) {
    final Map<String, int> moodCounts = {};
    
    for (final record in records) {
      if (record.mood.isNotEmpty) {
        moodCounts[record.mood] = (moodCounts[record.mood] ?? 0) + 1;
      }
    }
    
    // Sort by frequency
    final sortedEntries = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }
} 