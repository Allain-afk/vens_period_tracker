import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:vens_period_tracker/screens/add_period_screen.dart';
import 'package:vens_period_tracker/screens/profile_screen.dart';
import 'package:vens_period_tracker/screens/insights_screen.dart';
import 'package:vens_period_tracker/screens/intimacy/intimacy_history_screen.dart';
import 'package:vens_period_tracker/screens/intimacy/intimacy_log_screen.dart';
import 'package:vens_period_tracker/screens/period_history_screen.dart';
import 'package:vens_period_tracker/screens/pill_tracking_screen.dart';
import 'package:vens_period_tracker/screens/settings_screen.dart';
import 'package:vens_period_tracker/utils/constants.dart';
import 'package:vens_period_tracker/widgets/period_status_card.dart';
import 'package:vens_period_tracker/widgets/prediction_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Define const BoxDecoration objects
  static const BoxDecoration periodStartDecoration = BoxDecoration(
    color: AppColors.accent,
    shape: BoxShape.circle,
  );
  
  static const BoxDecoration continuingPeriodDecoration = BoxDecoration(
    color: AppColors.flowHeavy,
    shape: BoxShape.circle,
  );
  
  static const BoxDecoration predictedPeriodDecoration = BoxDecoration(
    color: Color(0xFFFF9EB9), // AppColors.primary with opacity 0.5
    shape: BoxShape.circle,
  );
  
  static const BoxDecoration ovulationDayDecoration = BoxDecoration(
    color: AppColors.success,
    shape: BoxShape.circle,
  );
  
  static const BoxDecoration fertileDayDecoration = BoxDecoration(
    color: Color(0xFFA5D6A7), // AppColors.success with opacity 0.5
    shape: BoxShape.circle,
  );
  
  static const BoxDecoration intimacyDecoration = BoxDecoration(
    color: Colors.pinkAccent,
    shape: BoxShape.circle,
  );
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ven's Period Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Hello, ${cycleProvider.username}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Status card
                const PeriodStatusCard(),
                
                // Calendar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2021, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          markersMaxCount: 3,
                          todayDecoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            // Mark period days
                            bool isPeriodDay = false;
                            bool isContinuingPeriodDay = false;
                            
                            // First, check if the date is a period start date in any record
                            for (final record in cycleProvider.periodRecords) {
                              if (cycleProvider.isSameDay(record.startDate, date)) {
                                isPeriodDay = true;
                                break;
                              }
                            }
                            
                            // If not a start date, check if it's a user-logged continuing day
                            if (!isPeriodDay) {
                              // Get all PeriodData entries that contain this date
                              for (final record in cycleProvider.periodRecords) {
                                // Skip if this is just an intimacy record (no flow data)
                                if (record.flowIntensity.isEmpty) continue;
                                
                                // If there's an end date, check if this date falls between start and end
                                if (record.endDate != null) {
                                  if (date.isAfter(record.startDate) && 
                                      (date.isBefore(record.endDate!) || cycleProvider.isSameDay(date, record.endDate!))) {
                                    isContinuingPeriodDay = true;
                                    break;
                                  }
                                }
                              }
                            }
                            
                            // Mark predicted period days
                            final nextPeriod = cycleProvider.getNextPeriodDate();
                            bool isPredictedPeriodDay = false;
                            
                            if (nextPeriod != null) {
                              final avgPeriodLength = cycleProvider.averagePeriodLength;
                              for (int i = 0; i < avgPeriodLength; i++) {
                                if (isSameDay(nextPeriod.add(Duration(days: i)), date)) {
                                  isPredictedPeriodDay = true;
                                  break;
                                }
                              }
                            }
                            
                            // Mark ovulation day
                            final ovulationDate = cycleProvider.getOvulationDate();
                            final isOvulationDay = ovulationDate != null && isSameDay(ovulationDate, date);
                            
                            // Mark fertility window
                            final fertilityWindow = cycleProvider.getFertilityWindow();
                            bool isFertileDay = false;
                            
                            if (fertilityWindow != null) {
                              final start = fertilityWindow['start']!;
                              final end = fertilityWindow['end']!;
                              if (date.isAfter(start.subtract(const Duration(days: 1))) && 
                                  date.isBefore(end.add(const Duration(days: 1)))) {
                                isFertileDay = true;
                              }
                            }
                            
                            // Mark intimacy days
                            final hasIntimacy = cycleProvider.getAllIntimacyData().any(
                              (entry) => entry.hadIntimacy && isSameDay(entry.date, date)
                            );
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPeriodDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: periodStartDecoration,
                                  ),
                                if (isContinuingPeriodDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: continuingPeriodDecoration,
                                  ),
                                if (isPredictedPeriodDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: predictedPeriodDecoration,
                                  ),
                                if (isOvulationDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: ovulationDayDecoration,
                                  ),
                                if (isFertileDay && !isOvulationDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: fertileDayDecoration,
                                  ),
                                if (hasIntimacy)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: intimacyDecoration,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Predictions section
                const PredictionCard(),
                
                // Calendar legend
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                            'Calendar Legend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            "Period Start", 
                            AppColors.accent
                          ),
                          _buildLegendItem(
                            "Continuing Period", 
                            AppColors.flowHeavy
                          ),
                          _buildLegendItem(
                            "Predicted Period", 
                            AppColors.primary.withOpacity(0.5)
                          ),
                          _buildLegendItem(
                            "Ovulation Day", 
                            AppColors.success
                          ),
                          _buildLegendItem(
                            "Fertile Window", 
                            AppColors.success.withOpacity(0.5)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Accuracy disclaimer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Prediction accuracy: ${cycleProvider.getPredictionAccuracy()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionOptions(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDark,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 8,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeriodHistoryScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InsightsScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PillTrackingScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IntimacyHistoryScreen()),
            );
          } else if (index == 5) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history, size: 28),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            activeIcon: Icon(Icons.insights, size: 28),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication_outlined, size: 28),
            label: 'Birth Control',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            activeIcon: Icon(Icons.favorite, size: 28),
            label: 'Intimacy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings, size: 28),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showActionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What would you like to log?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.water_drop, 
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Period'),
                subtitle: const Text('Log your period start/end dates and symptoms'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPeriodScreen(
                        selectedDate: _selectedDay!,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite, 
                    color: Colors.pink,
                  ),
                ),
                title: const Text('Intimacy'),
                subtitle: const Text('Log intimate moments, protected or unprotected'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IntimacyLogScreen(
                        initialDate: _selectedDay,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              Consumer<PillProvider>(
                builder: (context, pillProvider, child) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.pillActive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medication_outlined, 
                        color: AppColors.pillActive,
                      ),
                    ),
                    title: const Text('Birth Control'),
                    subtitle: Text(
                      pillProvider.hasPillData
                          ? 'Log today\'s pill intake'
                          : 'Set up your birth control tracking'
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PillTrackingScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 