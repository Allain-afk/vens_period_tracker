import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/utils/constants.dart';
import 'package:vens_period_tracker/utils/notification_service.dart';

class CycleProvider with ChangeNotifier {
  List<PeriodData> _periodRecords = [];
  String _username = '';
  int _averageCycleLength = AppConstants.defaultCycleLength;
  int _averagePeriodLength = AppConstants.defaultPeriodLength;
  final _notificationService = NotificationService();
  
  // Getters
  List<PeriodData> get periodRecords => _periodRecords;
  String get username => _username;
  int get averageCycleLength => _averageCycleLength;
  int get averagePeriodLength => _averagePeriodLength;
  
  CycleProvider() {
    _loadPeriodData();
    _loadUserPreferences();
  }
  
  // Load period data from Hive storage
  Future<void> _loadPeriodData() async {
    final box = Hive.box<PeriodData>('period_data');
    _periodRecords = box.values.toList();
    _calculateAverageCycleLength();
    notifyListeners();
  }
  
  // Load user preferences from Hive
  Future<void> _loadUserPreferences() async {
    final box = Hive.box('user_preferences');
    _username = box.get('username', defaultValue: 'Guest');
    notifyListeners();
  }
  
  // Add a new period record
  Future<void> addPeriodRecord(PeriodData record) async {
    final box = Hive.box<PeriodData>('period_data');
    await box.add(record);
    _periodRecords.add(record);
    _calculateAverageCycleLength();
    _schedulePredictionsNotifications();
    notifyListeners();
  }
  
  // Update an existing period record
  Future<void> updatePeriodRecord(String key, PeriodData updatedRecord) async {
    final box = Hive.box<PeriodData>('period_data');
    final index = _periodRecords.indexWhere((element) => element.key == key);
    
    if (index != -1) {
      await box.put(key, updatedRecord);
      _periodRecords[index] = updatedRecord;
      _calculateAverageCycleLength();
      _schedulePredictionsNotifications();
      notifyListeners();
    }
  }
  
  // Delete a period record
  Future<void> deletePeriodRecord(String key) async {
    final box = Hive.box<PeriodData>('period_data');
    await box.delete(key);
    _periodRecords.removeWhere((element) => element.key == key);
    _calculateAverageCycleLength();
    notifyListeners();
  }
  
  // Update username
  Future<void> updateUsername(String newName) async {
    final box = Hive.box('user_preferences');
    await box.put('username', newName);
    _username = newName;
    notifyListeners();
  }
  
  // Calculate average cycle length based on recorded periods
  void _calculateAverageCycleLength() {
    if (_periodRecords.length < 2) {
      return; // Not enough data to calculate average
    }
    
    // Sort periods by start date
    _periodRecords.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    int totalDays = 0;
    int totalPeriodDays = 0;
    int cycles = 0;
    int periods = 0;
    
    for (int i = 1; i < _periodRecords.length; i++) {
      final daysBetween = _periodRecords[i].startDate.difference(_periodRecords[i-1].startDate).inDays;
      
      // Only count if the difference is within reasonable range
      if (daysBetween >= AppConstants.minCycleLength && daysBetween <= AppConstants.maxCycleLength) {
        totalDays += daysBetween;
        cycles++;
      }
      
      // Calculate average period length
      if (_periodRecords[i].endDate != null) {
        totalPeriodDays += _periodRecords[i].durationInDays;
        periods++;
      }
    }
    
    if (cycles > 0) {
      _averageCycleLength = (totalDays / cycles).round();
    }
    
    if (periods > 0) {
      _averagePeriodLength = (totalPeriodDays / periods).round();
    }
  }
  
  // Get the next predicted period start date
  DateTime? getNextPeriodDate() {
    if (_periodRecords.isEmpty) return null;
    
    // Sort periods by start date to get the most recent one
    _periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastPeriod = _periodRecords.first;
    
    // Calculate next period based on average cycle length
    return lastPeriod.startDate.add(Duration(days: _averageCycleLength));
  }
  
  // Get predicted ovulation date
  DateTime? getOvulationDate() {
    final nextPeriod = getNextPeriodDate();
    if (nextPeriod == null) return null;
    
    // Ovulation typically occurs 14 days before the next period
    return nextPeriod.subtract(const Duration(days: AppConstants.ovulationDayOffset));
  }
  
  // Get fertility window (usually 5 days before and 1 day after ovulation)
  Map<String, DateTime?>? getFertilityWindow() {
    final ovulationDate = getOvulationDate();
    if (ovulationDate == null) return null;
    
    final fertilityStart = ovulationDate.subtract(
      Duration(days: AppConstants.fertileDaysBeforeOvulation)
    );
    
    final fertilityEnd = ovulationDate.add(
      Duration(days: AppConstants.fertileDaysAfterOvulation)
    );
    
    return {
      'start': fertilityStart,
      'end': fertilityEnd,
      'ovulation': ovulationDate,
    };
  }
  
  // Schedule notifications for upcoming events
  Future<void> _schedulePredictionsNotifications() async {
    // With the simplified notification service, we'll just show a test notification
    // instead of scheduling future notifications
    await _notificationService.showTestNotification();
  }
  
  // Calculate prediction accuracy based on cycles recorded
  String getPredictionAccuracy() {
    if (_periodRecords.length < 3) {
      return AppConstants.lowAccuracy;
    } else if (_periodRecords.length < 7) {
      return AppConstants.mediumAccuracy;
    } else {
      return AppConstants.highAccuracy;
    }
  }
} 