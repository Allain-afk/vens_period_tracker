import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vens_period_tracker/models/pill_data.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/utils/constants.dart';

class PillCalendarScreen extends StatefulWidget {
  const PillCalendarScreen({super.key});

  @override
  State<PillCalendarScreen> createState() => _PillCalendarScreenState();
}

class _PillCalendarScreenState extends State<PillCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pill Calendar'),
      ),
      body: Consumer<PillProvider>(
        builder: (context, provider, child) {
          if (!provider.hasPillData) {
            return const Center(
              child: Text('No birth control method set up yet'),
            );
          }
          
          return Column(
            children: [
              _buildCalendar(provider),
              const Divider(height: 1),
              Expanded(
                child: _buildLogDetails(provider),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCalendar(PillProvider provider) {
    final pillData = provider.pillData!;
    
    // Determine the first day for the calendar range
    final firstDay = pillData.startDate.isBefore(DateTime.now().subtract(const Duration(days: 365))) 
        ? DateTime.now().subtract(const Duration(days: 365)) 
        : pillData.startDate;
    
    return TableCalendar(
      firstDay: firstDay,
      lastDay: DateTime.now().add(const Duration(days: 30)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        markersMaxCount: 3,
        markersAnchor: 0.7,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return _buildCalendarCell(date, provider);
        },
        selectedBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: _buildCalendarCell(date, provider),
          );
        },
        todayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              shape: BoxShape.circle,
            ),
            child: _buildCalendarCell(date, provider),
          );
        },
      ),
    );
  }
  
  Widget _buildCalendarCell(DateTime date, PillProvider provider) {
    final pillData = provider.pillData!;
    
    // Check if this date is within the pill tracking period
    if (date.isBefore(pillData.startDate)) {
      return Center(
        child: Text(
          date.day.toString(),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    
    // Find pill log for this date
    final logs = pillData.pillLogs;
    final logForDate = logs.where((log) => 
      log.date.year == date.year && 
      log.date.month == date.month && 
      log.date.day == date.day
    );
    
    // Calculate if this was an active or placebo pill day
    final daysSinceStart = date.difference(pillData.startDate).inDays;
    final totalDays = pillData.activePillCount + pillData.placeboPillCount;
    final dayInCycle = (daysSinceStart % totalDays) + 1;
    final isActivePillDay = dayInCycle <= pillData.activePillCount;
    
    Color backgroundColor;
    Color textColor = Colors.black;
    IconData? icon;
    
    if (logForDate.isNotEmpty) {
      final log = logForDate.first;
      
      if (log.taken) {
        backgroundColor = AppColors.pillTaken;
        textColor = Colors.white;
        icon = Icons.check;
      } else {
        backgroundColor = AppColors.pillMissed;
        textColor = Colors.white;
        icon = Icons.close;
      }
    } else if (date.isAfter(DateTime.now())) {
      // Future dates
      backgroundColor = isActivePillDay ? AppColors.pillActive.withOpacity(0.3) : AppColors.pillPlacebo.withOpacity(0.3);
    } else {
      // Past dates without logs (potentially missed)
      backgroundColor = isActivePillDay ? AppColors.error.withOpacity(0.3) : AppColors.pillPlacebo.withOpacity(0.3);
    }
    
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
          ? Icon(icon, color: textColor, size: 16)
          : Text(
              date.day.toString(),
              style: TextStyle(color: textColor),
            ),
      ),
    );
  }
  
  Widget _buildLogDetails(PillProvider provider) {
    final pillData = provider.pillData!;
    
    // Get log entry for selected day if exists
    final logs = pillData.pillLogs;
    final logForSelectedDay = logs.where((log) => 
      log.date.year == _selectedDay.year && 
      log.date.month == _selectedDay.month && 
      log.date.day == _selectedDay.day
    );
    
    // Calculate if this was an active or placebo pill day
    final daysSinceStart = _selectedDay.difference(pillData.startDate).inDays;
    final totalDays = pillData.activePillCount + pillData.placeboPillCount;
    final dayInCycle = (daysSinceStart % totalDays) + 1;
    final isActivePillDay = dayInCycle <= pillData.activePillCount;
    final pillType = isActivePillDay ? 'Active Pill' : 'Placebo Pill';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat.yMMMMd().format(_selectedDay),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActivePillDay ? AppColors.pillActive.withOpacity(0.2) : AppColors.pillPlacebo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Day $dayInCycle - $pillType',
                  style: TextStyle(
                    color: isActivePillDay ? AppColors.pillActive : AppColors.pillPlacebo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (logForSelectedDay.isNotEmpty) ...[
            _buildLogEntry(logForSelectedDay.first, isActivePillDay),
          ] else if (_selectedDay.isAfter(DateTime.now())) ...[
            // Future date
            _buildFutureDate(),
          ] else ...[
            // Past date with no log
            _buildMissingLogEntry(provider, isActivePillDay),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLogEntry(PillLogEntry log, bool isActivePill) {
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
                  log.taken ? Icons.check_circle : Icons.cancel,
                  color: log.taken ? AppColors.pillTaken : AppColors.pillMissed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  log.taken ? 'Pill Taken' : 'Pill Missed',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (log.taken && log.takenTime != null) ...[
              _infoRow('Time taken', DateFormat.jm().format(log.takenTime!)),
            ],
            _infoRow('Status', _formatPillStatus(log.status)),
            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(log.notes),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFutureDate() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Future Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This date is in the future. You\'ll be able to log your pill intake on this day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMissingLogEntry(PillProvider provider, bool isActivePill) {
    final isToday = _selectedDay.year == DateTime.now().year && 
                    _selectedDay.month == DateTime.now().month && 
                    _selectedDay.day == DateTime.now().day;
    
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
                  isActivePill ? Icons.error_outline : Icons.info_outline,
                  color: isActivePill ? AppColors.warning : AppColors.textMedium,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isActivePill ? 'No Log Found' : 'Placebo Day',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isActivePill 
                ? 'There\'s no record of you taking or missing your pill on this day.'
                : 'This was a placebo pill day in your cycle.',
              style: const TextStyle(
                color: AppColors.textMedium,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.logPillTaken(
                          _selectedDay, 
                          isActivePill ? PillStatus.onTime : PillStatus.placebo
                        );
                        setState(() {}); // Refresh UI
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pillTaken,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (isActivePill) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.logPillMissed(_selectedDay);
                          setState(() {}); // Refresh UI
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Mark as Missed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pillMissed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (isActivePill) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.logPillTaken(
                          _selectedDay, 
                          isActivePill ? PillStatus.onTime : PillStatus.placebo
                        );
                        setState(() {}); // Refresh UI
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Log Retroactively'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
  
  String _formatPillStatus(String status) {
    switch (status) {
      case PillStatus.onTime:
        return 'On Time';
      case PillStatus.late:
        return 'Late';
      case PillStatus.missed:
        return 'Missed';
      case PillStatus.placebo:
        return 'Placebo';
      default:
        return status;
    }
  }
} 