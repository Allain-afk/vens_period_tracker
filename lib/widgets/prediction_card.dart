import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd();
    
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        // Get pill provider to check if using hormonal birth control
        final pillProvider = Provider.of<PillProvider>(context, listen: false);
        final isUsingHormonalBC = pillProvider.isUsingHormonalBirthControl;
        
        // Pass context to the methods so they can access pill provider
        final nextPeriod = cycleProvider.getNextPeriodDate(context: context);
        final fertilityWindow = cycleProvider.getFertilityWindow(context: context);
        
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
                  
                  // Next period prediction - with appropriate label for BC users
                  _buildPredictionItem(
                    icon: Icons.opacity,
                    title: isUsingHormonalBC ? 'Next Withdrawal Bleeding' : 'Next Period',
                    date: '${dateFormat.format(nextPeriod)} - ${dateFormat.format(nextPeriodEnd)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  
                  // Only show fertility window for non-hormonal BC users
                  if (fertilityWindow != null && !isUsingHormonalBC) ...[
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
                  
                  // For hormonal BC users, show pill pack info
                  if (isUsingHormonalBC && pillProvider.hasPillData) ...[
                    const SizedBox(height: 12),
                    _buildPredictionItem(
                      icon: Icons.medication_outlined,
                      title: 'Birth Control Info',
                      date: 'Predictions based on your pill pack schedule',
                      color: AppColors.pillActive,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Only show prediction confidence for natural cycles
                  if (!isUsingHormonalBC) ...[
                    _buildConfidenceIndicator(cycleProvider),
                    
                    if (cycleProvider.hasPatternDetected || cycleProvider.isHighlyIrregular) ...[
                      const SizedBox(height: 10),
                      _buildPatternInfo(cycleProvider),
                    ],
                  ] else ...[
                    // Show hormonal BC info instead
                    _buildHormonalBCInfo(pillProvider),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHormonalBCInfo(PillProvider pillProvider) {
    if (!pillProvider.hasPillData) return const SizedBox.shrink();
    
    final pillData = pillProvider.pillData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.pillActive,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hormonal Birth Control',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your pack has ${pillData.activePillCount} active pills and ${pillData.placeboPillCount} placebo pills. ' +
          'While using hormonal birth control, you will not have a natural menstrual cycle. ' +
          'Any bleeding during placebo days is withdrawal bleeding, not a true period.',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
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
                style: const TextStyle(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildConfidenceIndicator(CycleProvider cycleProvider) {
    final confidence = cycleProvider.getPredictionConfidence();
    
    Color confidenceColor;
    if (confidence < 50) {
      confidenceColor = AppColors.warning;
    } else if (confidence < 75) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = AppColors.success;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Prediction Confidence:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '$confidence%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: confidenceColor,
              ),
            ),
            const Spacer(),
            Icon(
              _getConfidenceIcon(confidence),
              color: confidenceColor,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: Colors.grey.shade200,
            color: confidenceColor,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cycleProvider.getPredictionAccuracy(),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPatternInfo(CycleProvider cycleProvider) {
    String patternText;
    IconData patternIcon;
    
    if (cycleProvider.hasPatternDetected) {
      patternText = 'Pattern detected: Your cycles appear to alternate between longer and shorter lengths';
      patternIcon = Icons.insights;
    } else if (cycleProvider.isHighlyIrregular) {
      patternText = 'Your cycles are irregular. Predictions are based on your most recent cycles.';
      patternIcon = Icons.shuffle;
    } else {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        Icon(
          patternIcon,
          color: AppColors.accent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            patternText,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getConfidenceIcon(int confidence) {
    if (confidence < 50) {
      return Icons.sentiment_dissatisfied;
    } else if (confidence < 75) {
      return Icons.sentiment_neutral;
    } else {
      return Icons.sentiment_very_satisfied;
    }
  }
} 