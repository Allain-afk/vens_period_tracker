import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/pill_data.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';
import 'package:vens_period_tracker/screens/setup_pill_screen.dart';
import 'package:vens_period_tracker/screens/pill_reminder_settings_screen.dart';
import 'package:vens_period_tracker/screens/pill_calendar_screen.dart';

class PillTrackingScreen extends StatelessWidget {
  const PillTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showEducationalInfo(context);
            },
          ),
        ],
      ),
      body: Consumer<PillProvider>(
        builder: (context, pillProvider, child) {
          if (!pillProvider.hasPillData) {
            return _buildEmptyState(context);
          }
          
          return _buildPillTrackingContent(context, pillProvider);
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No birth control method set up yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your contraceptive method to track and get reminders',
            style: TextStyle(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupPillScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Set Up Birth Control'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPillTrackingContent(BuildContext context, PillProvider provider) {
    final pillData = provider.pillData!;
    final currentDay = pillData.getCurrentPillDay();
    final totalDays = pillData.activePillCount + pillData.placeboPillCount;
    final isActivePill = pillData.isActivePillDay();
    final isPillTaken = pillData.isPillTakenToday();
    final remainingPills = pillData.getRemainingPills();
    final showRefillAlert = pillData.shouldShowRefillAlert();
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status card
            _buildStatusCard(context, pillData, currentDay, totalDays, isActivePill, isPillTaken),
            
            const SizedBox(height: 16),
            
            // Refill alert if needed
            if (showRefillAlert)
              _buildRefillAlert(context, provider, remainingPills),
            
            const SizedBox(height: 16),
            
            // Daily tracking card
            _buildDailyTrackingCard(context, provider, isPillTaken, isActivePill),
            
            const SizedBox(height: 16),
            
            // Quick actions
            _buildQuickActions(context, provider),
            
            const SizedBox(height: 16),
            
            // Pill information
            _buildPillInfo(context, pillData),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard(
    BuildContext context, 
    PillData pillData, 
    int currentDay, 
    int totalDays, 
    bool isActivePill,
    bool isPillTaken
  ) {
    final pillPhase = isActivePill ? 'Active Pill' : 'Placebo Pill';
    final phaseColor = isActivePill ? AppColors.pillActive : AppColors.pillPlacebo;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: phaseColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Day $currentDay of $totalDays',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pillPhase,
                    style: TextStyle(
                      color: phaseColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: currentDay / totalDays,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s pill: ${isPillTaken ? 'Taken ✓' : 'Not taken yet'}',
                  style: TextStyle(
                    color: isPillTaken ? AppColors.success : AppColors.textMedium,
                  ),
                ),
                Text(
                  'Pills left: ${pillData.getRemainingPills()}',
                  style: const TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRefillAlert(BuildContext context, PillProvider provider, int remainingPills) {
    final formattedDate = DateFormat.yMMMd().format(provider.pillData!.nextRefillDate);
    
    return Card(
      elevation: 2,
      color: AppColors.warning.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: AppColors.warning,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time to refill your prescription',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only $remainingPills pills left in your current pack. Next refill date: $formattedDate.',
                    style: const TextStyle(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyTrackingCard(
    BuildContext context, 
    PillProvider provider, 
    bool isPillTaken, 
    bool isActivePill
  ) {
    final today = DateTime.now();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Tracking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isPillTaken) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.logPillTaken(
                          today, 
                          isActivePill ? PillStatus.onTime : PillStatus.placebo
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pillActive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _showTakenWithNotesDialog(context, provider, today, isActivePill);
                    },
                    icon: const Icon(Icons.note_add),
                    tooltip: 'Add notes when marking as taken',
                  ),
                ],
              ),
              if (isActivePill) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showMissedPillDialog(context, provider, today);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Mark as Missed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ] else ...[
              // Pill already taken today
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'You\'ve taken your pill today',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _showEditPillLogDialog(context, provider, today);
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context, PillProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _actionButton(
                  context,
                  title: 'View Calendar',
                  icon: Icons.calendar_today,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PillCalendarScreen(),
                      ),
                    );
                  },
                ),
                _actionButton(
                  context,
                  title: 'Reminder Settings',
                  icon: Icons.notifications_outlined,
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PillReminderSettingsScreen(),
                      ),
                    );
                  },
                ),
                _actionButton(
                  context,
                  title: 'Start New Pack',
                  icon: Icons.restart_alt,
                  color: AppColors.success,
                  onTap: () {
                    _showStartNewPackDialog(context, provider);
                  },
                ),
                _actionButton(
                  context,
                  title: 'Edit BC Method',
                  icon: Icons.settings,
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupPillScreen(
                          existingData: provider.pillData,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _actionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPillInfo(BuildContext context, PillData pillData) {
    final dateFormat = DateFormat.yMMMd();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Birth Control Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Method', pillData.contraceptiveMethod),
            if (pillData.brandName.isNotEmpty)
              _infoRow('Brand', pillData.brandName),
            _infoRow('Pack Structure', 
                '${pillData.activePillCount} active + ${pillData.placeboPillCount} placebo'),
            _infoRow('Pack Started', dateFormat.format(pillData.startDate)),
            _infoRow('Next Refill', dateFormat.format(pillData.nextRefillDate)),
            if (pillData.reminderEnabled)
              _infoRow('Daily Reminder', pillData.reminderTime),
          ],
        ),
      ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void _showTakenWithNotesDialog(
    BuildContext context, 
    PillProvider provider, 
    DateTime date, 
    bool isActivePill
  ) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Add any notes about today\'s pill',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.logPillTaken(
                date, 
                isActivePill ? PillStatus.onTime : PillStatus.placebo,
                notes: notesController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showMissedPillDialog(
    BuildContext context, 
    PillProvider provider, 
    DateTime date
  ) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missed Pill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Missing a pill can reduce effectiveness. Follow your pill pack instructions for what to do next.',
              style: TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            onPressed: () {
              provider.logPillMissed(
                date,
                notes: notesController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Mark as Missed'),
          ),
        ],
      ),
    );
  }
  
  void _showEditPillLogDialog(
    BuildContext context, 
    PillProvider provider, 
    DateTime date
  ) {
    // Find the entry for today
    final logs = provider.pillData!.pillLogs;
    final todayLog = logs.firstWhere(
      (log) => log.date.year == date.year && 
               log.date.month == date.month && 
               log.date.day == date.day,
      orElse: () => PillLogEntry(
        date: date, 
        taken: true, 
        status: provider.pillData!.isActivePillDay() 
            ? PillStatus.onTime 
            : PillStatus.placebo,
      ),
    );
    
    final isActive = provider.pillData!.isActivePillDay();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pill Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Taken'),
              leading: Radio<bool>(
                value: true,
                groupValue: todayLog.taken,
                onChanged: (value) {
                  Navigator.pop(context);
                  provider.logPillTaken(
                    date, 
                    isActive ? PillStatus.onTime : PillStatus.placebo,
                    notes: todayLog.notes,
                  );
                },
              ),
            ),
            if (isActive) // Only show "Missed" option for active pills
              ListTile(
                title: const Text('Missed'),
                leading: Radio<bool>(
                  value: false,
                  groupValue: todayLog.taken,
                  onChanged: (value) {
                    Navigator.pop(context);
                    provider.logPillMissed(
                      date,
                      notes: todayLog.notes,
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showStartNewPackDialog(BuildContext context, PillProvider provider) {
    final now = DateTime.now();
    DateTime selectedDate = now;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Pack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the date you started or will start your new pack:',
              style: TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year, now.month - 1, now.day),
                  lastDate: DateTime(now.year, now.month + 1, now.day),
                );
                
                if (pickedDate != null) {
                  selectedDate = pickedDate;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(DateFormat.yMMMd().format(selectedDate)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.startNewPack(selectedDate);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New pack started successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Start New Pack'),
          ),
        ],
      ),
    );
  }
  
  void _showEducationalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Hormonal Birth Control'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppConstants.pillEffectsInfo),
              const SizedBox(height: 16),
              const Text(
                'Important Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• When using hormonal birth control, you don\'t have a natural ovulatory cycle'),
              const Text('• The bleeding you may experience during placebo pills is withdrawal bleeding, not a true period'),
              const Text('• For maximum effectiveness, take your pill at the same time every day'),
              const Text('• If you miss a pill, follow your pill packet instructions immediately'),
              const SizedBox(height: 16),
              const Text(
                'This app helps you keep track of your pills, but always follow your healthcare provider\'s specific guidance.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
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