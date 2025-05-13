import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vens_period_tracker/models/period_data.dart';
import 'package:vens_period_tracker/utils/constants.dart';
import 'package:vens_period_tracker/utils/notification_service.dart';
import 'dart:math' as math;
import 'package:vens_period_tracker/providers/pill_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CycleProvider with ChangeNotifier {
  List<PeriodData> _periodRecords = [];
  String _username = '';
  int _averageCycleLength = AppConstants.defaultCycleLength;
  int _averagePeriodLength = AppConstants.defaultPeriodLength;
  final _notificationService = NotificationService();
  
  // Add variables for advanced prediction
  List<int> _recentCycleLengths = [];
  bool _hasPatternDetected = false;
  bool _isHighlyIrregular = false;

  // Getters
  List<PeriodData> get periodRecords => _periodRecords;
  String get username => _username;
  int get averageCycleLength => _averageCycleLength;
  int get averagePeriodLength => _averagePeriodLength;
  bool get hasPatternDetected => _hasPatternDetected;
  bool get isHighlyIrregular => _isHighlyIrregular;
  List<int> get recentCycleLengths => _recentCycleLengths;
  
  CycleProvider() {
    _loadPeriodData();
    _loadUserPreferences();
  }
  
  // Load period data from Hive storage
  Future<void> _loadPeriodData() async {
    final box = Hive.box<PeriodData>('period_data');
    _periodRecords = box.values.toList();
    _calculateAverageCycleLength();
    _detectCyclePatterns();
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
    _detectCyclePatterns();
    _schedulePredictionsNotifications();
    notifyListeners();
  }
  
  // Helper method to get a valid Hive key
  dynamic _getValidHiveKey(String keyString) {
    // Check if the key is already a valid format
    if (keyString.startsWith('0:')) {
      // This is already in Hive format, extract the numeric part
      final parts = keyString.split(':');
      if (parts.length >= 2) {
        try {
          return int.parse(parts[1]);
        } catch (e) {
          print('Error parsing key: $e');
          return keyString; // Return original if parsing fails
        }
      }
    }
    
    // Try to interpret as an integer key
    try {
      return int.parse(keyString);
    } catch (e) {
      // If not parseable as int, return as is
      return keyString;
    }
  }

  // Update an existing period record
  Future<void> updatePeriodRecord(String keyString, PeriodData updatedRecord) async {
    final box = Hive.box<PeriodData>('period_data');
    final index = _periodRecords.indexWhere((element) => element.key.toString() == keyString);
    
    print('Updating period record:');
    print('- Record key string: $keyString');
    print('- Found in records? ${index != -1}');
    print('- Start date: ${updatedRecord.startDate}');
    print('- End date: ${updatedRecord.endDate}');
    
    // Convert keyString to a valid Hive key
    final key = _getValidHiveKey(keyString);
    print('- Converted key: $key (${key.runtimeType})');
    
    if (index != -1) {
      try {
        // Get existing record to debug
        final existingRecord = _periodRecords[index];
        print('- Existing start date: ${existingRecord.startDate}');
        print('- Existing end date: ${existingRecord.endDate}');
        print('- Existing key: ${existingRecord.key}');
        
        // Update in Hive
        await box.put(existingRecord.key, updatedRecord);
        
        // Update in memory
        _periodRecords[index] = updatedRecord;
        
        // Recalculate cycle data
        _calculateAverageCycleLength();
        _detectCyclePatterns();
        _schedulePredictionsNotifications();
        notifyListeners();
        
        print('Period record updated successfully');
      } catch (e) {
        print('Error updating period record: $e');
        // Try again with the converted key
        try {
          await box.put(key, updatedRecord);
          
          // Reload to ensure we have the latest data
          _periodRecords = box.values.toList();
          _calculateAverageCycleLength();
          _detectCyclePatterns();
          notifyListeners();
          print('Period record updated using converted key');
        } catch (e) {
          print('Failed to update period record: $e');
        }
      }
    } else {
      print('WARNING: Period record not found in memory for key: $keyString');
      try {
        // Try to update by key directly in Hive
        await box.put(key, updatedRecord);
        
        // Reload records to get fresh data
        _periodRecords = box.values.toList();
        _calculateAverageCycleLength();
        _detectCyclePatterns();
        notifyListeners();
        print('Period record updated by direct Hive access');
      } catch (e) {
        print('Failed to update period record by key: $e');
        
        // Last resort: add as a new record if we can't update
        print('Attempting to add as a new record');
        try {
          await addPeriodRecord(updatedRecord);
          print('Added as a new record instead of updating');
        } catch (e) {
          print('Failed to add as new record: $e');
        }
      }
    }
  }
  
  // Delete a period record
  Future<void> deletePeriodRecord(String key, {bool forceDelete = false}) async {
    final box = Hive.box<PeriodData>('period_data');
    
    try {
      // Simply delete the record without checking for intimacy data
      await box.delete(key);
      _periodRecords.removeWhere((element) => element.key == key);
      
      _calculateAverageCycleLength();
      _detectCyclePatterns();
      notifyListeners();
    } catch (e) {
      print('Error deleting period record: $e');
      
      // Fallback: just delete the record from Hive and memory
      await box.delete(key);
      _periodRecords.removeWhere((element) => element.key == key);
      _calculateAverageCycleLength();
      _detectCyclePatterns();
      notifyListeners();
    }
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
    
    // For weighted average
    double weightedTotal = 0;
    double weightSum = 0;
    _recentCycleLengths = [];
    
    for (int i = 1; i < _periodRecords.length; i++) {
      final daysBetween = _periodRecords[i].startDate.difference(_periodRecords[i-1].startDate).inDays;
      
      // Expanded range for irregular cycles
      if (daysBetween >= AppConstants.minExtendedCycleLength && 
          daysBetween <= AppConstants.maxExtendedCycleLength) {
        totalDays += daysBetween;
        cycles++;
        
        // Add to recent cycle lengths array
        _recentCycleLengths.add(daysBetween);
        
        // Apply higher weight to more recent cycles
        double weight = 1.0 + (i / _periodRecords.length);
        weightedTotal += daysBetween * weight;
        weightSum += weight;
      }
      
      // Calculate average period length
      if (_periodRecords[i].endDate != null) {
        totalPeriodDays += _periodRecords[i].durationInDays;
        periods++;
      }
    }
    
    if (cycles > 0) {
      // Use weighted average if we have enough data, otherwise use simple average
      if (cycles >= 3) {
        _averageCycleLength = (weightedTotal / weightSum).round();
      } else {
        _averageCycleLength = (totalDays / cycles).round();
      }
    }
    
    if (periods > 0) {
      _averagePeriodLength = (totalPeriodDays / periods).round();
    }
  }
  
  // Detect patterns in menstrual cycle (e.g., alternating short/long)
  void _detectCyclePatterns() {
    if (_recentCycleLengths.length < 4) {
      _hasPatternDetected = false;
      _isHighlyIrregular = false;
      return;
    }
    
    // Calculate standard deviation to measure irregularity
    double mean = _recentCycleLengths.fold(0, (sum, length) => sum + length) / _recentCycleLengths.length;
    double variance = _recentCycleLengths.fold(0.0, (double sum, length) => sum + math.pow((length - mean), 2)) / _recentCycleLengths.length;
    double stdDev = math.sqrt(variance);
    
    // If standard deviation is high, cycles are highly irregular
    _isHighlyIrregular = stdDev > 5.0;
    
    // Check for alternating pattern (short-long-short-long)
    bool hasAlternatingPattern = true;
    for (int i = 0; i < _recentCycleLengths.length - 2; i++) {
      // If a cycle is not shorter than the next and longer than the one after,
      // then it's not following the alternating pattern
      if (!(_recentCycleLengths[i] < _recentCycleLengths[i+1] && 
          _recentCycleLengths[i+1] > _recentCycleLengths[i+2])) {
        hasAlternatingPattern = false;
        break;
      }
    }
    
    _hasPatternDetected = hasAlternatingPattern;
  }
  
  // Helper method to calculate standard deviation
  double pow(double x, int power) {
    double result = 1.0;
    for (int i = 0; i < power; i++) {
      result *= x;
    }
    return result;
  }
  
  double sqrt(double x) {
    double y = x / 2;
    int i = 0;
    while (i < 10) {
      y = (y + x / y) / 2;
      i++;
    }
    return y;
  }
  
  // Get the next predicted period start date
  DateTime? getNextPeriodDate({BuildContext? context}) {
    if (_periodRecords.isEmpty) return null;
    
    // Check if user is using hormonal birth control - safely access if context provided
    bool isUsingHormonalBC = false;
    if (context != null) {
      final pillProvider = Provider.of<PillProvider>(context, listen: false);
      isUsingHormonalBC = pillProvider.isUsingHormonalBirthControl;
      
      if (isUsingHormonalBC && pillProvider.hasPillData) {
        final pillData = pillProvider.pillData!;
        final currentDay = pillData.getCurrentPillDay();
        final totalDays = pillData.activePillCount + pillData.placeboPillCount;
        
        // Calculate when the next placebo days will start
        final daysUntilPlacebo = pillData.activePillCount - currentDay;
        if (daysUntilPlacebo >= 0) {
          // User is in active pill phase
          return DateTime.now().add(Duration(days: daysUntilPlacebo + 1));
        } else {
          // User is already in placebo phase, next withdrawal bleed will be after
          // completing this pack and the active pills of the next pack
          return DateTime.now().add(Duration(days: (totalDays - currentDay) + pillData.activePillCount + 1));
        }
      }
    }
    
    // If not using hormonal birth control or context not available, use standard prediction
    _periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastPeriod = _periodRecords.first;
    
    // If we have detected a pattern or high irregularity, use smarter prediction
    if (_hasPatternDetected && _recentCycleLengths.length >= 3) {
      // For alternating patterns, use the cycle length from two cycles ago
      final patternIndex = _recentCycleLengths.length % 2;
      final patternCycleLength = _recentCycleLengths[patternIndex];
      return lastPeriod.startDate.add(Duration(days: patternCycleLength));
    } else if (_isHighlyIrregular && _recentCycleLengths.length >= 3) {
      // For highly irregular cycles, use the average of the last 3 cycles only
      final recentAverage = _recentCycleLengths
          .sublist(math.max(0, _recentCycleLengths.length - 3))
          .reduce((a, b) => a + b) / 
          math.min(3, _recentCycleLengths.length);
      return lastPeriod.startDate.add(Duration(days: recentAverage.round()));
    } else {
      // Otherwise use the weighted average cycle length
      return lastPeriod.startDate.add(Duration(days: _averageCycleLength));
    }
  }
  
  // Get predicted ovulation date
  DateTime? getOvulationDate({BuildContext? context}) {
    // Check if user is using hormonal birth control
    bool isUsingHormonalBC = false;
    if (context != null) {
      final pillProvider = Provider.of<PillProvider>(context, listen: false);
      isUsingHormonalBC = pillProvider.isUsingHormonalBirthControl;
      
      if (isUsingHormonalBC) {
        // No ovulation occurs with hormonal birth control
        return null;
      }
    }
    
    // If not using hormonal birth control or context not available
    final nextPeriod = getNextPeriodDate(context: context);
    if (nextPeriod == null) return null;
    
    return nextPeriod.subtract(const Duration(days: AppConstants.ovulationDayOffset));
  }
  
  // Get fertility window (usually 5 days before and 1 day after ovulation)
  Map<String, DateTime?>? getFertilityWindow({BuildContext? context}) {
    // Check if user is using hormonal birth control
    bool isUsingHormonalBC = false;
    if (context != null) {
      final pillProvider = Provider.of<PillProvider>(context, listen: false);
      isUsingHormonalBC = pillProvider.isUsingHormonalBirthControl;
      
      if (isUsingHormonalBC) {
        // No fertility window with hormonal birth control
        return null;
      }
    }
    
    // If not using hormonal birth control or context not available
    final ovulationDate = getOvulationDate(context: context);
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
    } else if (_isHighlyIrregular) {
      return AppConstants.irregularCycleMessage;
    } else {
      return AppConstants.highAccuracy;
    }
  }
  
  // Update notifications based on user preferences
  Future<void> updateNotifications() async {
    // Cancel all existing notifications first
    await _notificationService.cancelAllNotifications();
    
    // Get user preferences
    final prefs = await SharedPreferences.getInstance();
    final periodNotifications = prefs.getBool('period_notifications') ?? true;
    final ovulationNotifications = prefs.getBool('ovulation_notifications') ?? true;
    final fertileDaysNotifications = prefs.getBool('fertile_days_notifications') ?? true;
    
    // If all notifications are disabled, we can return early
    if (!periodNotifications && !ovulationNotifications && !fertileDaysNotifications) {
      return;
    }
    
    // Schedule notifications based on preferences - not actually implemented in the notification service
    // This is just a placeholder that would schedule the appropriate notifications
    await _schedulePredictionsNotifications();
  }
  
  // Get prediction confidence level (as a percentage)
  int getPredictionConfidence() {
    if (_periodRecords.length < 2) {
      return 0;
    } else if (_isHighlyIrregular) {
      return 40 + (math.min(10, _periodRecords.length) * 2);
    } else if (_hasPatternDetected) {
      return 70 + (math.min(6, _periodRecords.length) * 5);
    } else {
      return 50 + (math.min(10, _periodRecords.length) * 5);
    }
  }
  
  // Get all intimacy data entries across all period records
  List<IntimacyData> getAllIntimacyData() {
    List<IntimacyData> allEntries = [];
    
    for (final record in _periodRecords) {
      if (record.intimacyData != null && record.intimacyData!.isNotEmpty) {
        allEntries.addAll(record.intimacyData!);
      }
    }
    
    return allEntries;
  }
  
  // Add an intimacy data entry
  Future<void> addIntimacyData(IntimacyData newEntry) async {
    // Find period record that contains this date, or use the most recent one
    PeriodData? targetRecord;
    
    // Sort by start date, newest first
    _periodRecords.sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Try to find a period that contains this date
    for (final record in _periodRecords) {
      if (record.endDate != null) {
        // If the date is within this period's range
        if (!newEntry.date.isBefore(record.startDate) && 
            !newEntry.date.isAfter(record.endDate!)) {
          targetRecord = record;
          break;
        }
      } else {
        // If only start date is recorded, just check if it's the same day
        if (isSameDay(record.startDate, newEntry.date)) {
          targetRecord = record;
          break;
        }
      }
    }
    
    // If no matching period found, create a new intimacy-only record
    if (targetRecord == null) {
      // Create a new "intimacy-only" record for this date
      final box = Hive.box<PeriodData>('period_data');
      final newRecord = PeriodData(
        startDate: newEntry.date,
        flowIntensity: "", // Empty string to mark as intimacy-only record
        intimacyData: [newEntry],
      );
      await box.add(newRecord);
      _periodRecords.add(newRecord);
      notifyListeners();
      return;
    }
    
    // Update the target record with the new intimacy data
    final box = Hive.box<PeriodData>('period_data');
    final updatedIntimacyData = List<IntimacyData>.from(targetRecord.intimacyData ?? []);
    
    // Check if an entry for this date already exists
    final existingIndex = updatedIntimacyData.indexWhere(
      (entry) => isSameDay(entry.date, newEntry.date)
    );
    
    if (existingIndex >= 0) {
      // Replace existing entry
      updatedIntimacyData[existingIndex] = newEntry;
    } else {
      // Add new entry
      updatedIntimacyData.add(newEntry);
    }
    
    // Create updated record
    final updatedRecord = targetRecord.copyWith(
      intimacyData: updatedIntimacyData,
    );
    
    // Update in Hive
    await box.put(targetRecord.key, updatedRecord);
    
    // Update in memory
    final index = _periodRecords.indexWhere((r) => r.key == targetRecord!.key);
    if (index >= 0) {
      _periodRecords[index] = updatedRecord;
    }
    
    notifyListeners();
  }
  
  // Delete an intimacy data entry
  Future<void> deleteIntimacyData(IntimacyData entryToDelete) async {
    // Find which period record contains this intimacy entry
    for (final record in _periodRecords) {
      if (record.intimacyData == null) continue;
      
      final entryIndex = record.intimacyData!.indexWhere(
        (entry) => isSameDay(entry.date, entryToDelete.date) && 
                  entry.hadIntimacy == entryToDelete.hadIntimacy &&
                  entry.wasProtected == entryToDelete.wasProtected
      );
      
      if (entryIndex >= 0) {
        // Found the record containing this entry
        final box = Hive.box<PeriodData>('period_data');
        
        // Create a new list without the entry to delete
        final updatedIntimacyData = List<IntimacyData>.from(record.intimacyData!);
        updatedIntimacyData.removeAt(entryIndex);
        
        // Create updated record
        final updatedRecord = record.copyWith(
          intimacyData: updatedIntimacyData,
        );
        
        // Update in Hive
        await box.put(record.key, updatedRecord);
        
        // Update in memory
        final recordIndex = _periodRecords.indexWhere((r) => r.key == record.key);
        if (recordIndex >= 0) {
          _periodRecords[recordIndex] = updatedRecord;
        }
        
        notifyListeners();
        return;
      }
    }
  }
  
  // Helper to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Reset all data (used for clearing all app data)
  void resetData() {
    _periodRecords = [];
    _username = 'Guest';
    _averageCycleLength = AppConstants.defaultCycleLength;
    _averagePeriodLength = AppConstants.defaultPeriodLength;
    _recentCycleLengths = [];
    _hasPatternDetected = false;
    _isHighlyIrregular = false;
    _loadPeriodData(); // Reload from Hive (which should now be empty)
    notifyListeners();
  }
} 