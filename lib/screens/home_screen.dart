import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/providers/cycle_provider.dart';
import 'package:vens_period_tracker/screens/add_period_screen.dart';
import 'package:vens_period_tracker/screens/profile_screen.dart';
import 'package:vens_period_tracker/screens/insights_screen.dart';
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
                            final isPeriodDay = cycleProvider.periodRecords.any((record) {
                              if (record.endDate == null) {
                                return isSameDay(record.startDate, date);
                              }
                              
                              final difference = record.endDate!.difference(record.startDate).inDays;
                              for (int i = 0; i <= difference; i++) {
                                if (isSameDay(record.startDate.add(Duration(days: i)), date)) {
                                  return true;
                                }
                              }
                              return false;
                            });
                            
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
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPeriodDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (isPredictedPeriodDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (isOvulationDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (isFertileDay && !isOvulationDay)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
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
                            "Period Days", 
                            AppColors.accent
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
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPeriodScreen(
                selectedDate: _selectedDay ?? DateTime.now(),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InsightsScreen(),
              ),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
} 