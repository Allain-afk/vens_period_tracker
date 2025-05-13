import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vens_period_tracker/models/pill_data.dart';
import 'package:vens_period_tracker/utils/notification_service.dart';

class PillProvider with ChangeNotifier {
  PillData? _pillData;
  final _notificationService = NotificationService();
  bool _isUsingHormonalBirthControl = false;

  // Getters
  PillData? get pillData => _pillData;
  bool get isUsingHormonalBirthControl => _isUsingHormonalBirthControl;
  bool get hasPillData => _pillData != null;
  
  PillProvider() {
    _loadPillData();
    _loadUserPreferences();
  }
  
  // Load pill data from Hive storage
  Future<void> _loadPillData() async {
    final box = Hive.box<PillData>('pill_data');
    if (box.isNotEmpty) {
      _pillData = box.getAt(0);
      _scheduleReminders();
    }
    notifyListeners();
  }
  
  // Load user preferences from Hive
  Future<void> _loadUserPreferences() async {
    final box = Hive.box('user_preferences');
    _isUsingHormonalBirthControl = box.get('using_hormonal_bc', defaultValue: false);
    notifyListeners();
  }
  
  // Set up initial pill data
  Future<void> setupPillData(PillData data) async {
    final box = Hive.box<PillData>('pill_data');
    
    // Clear any existing data
    await box.clear();
    
    // Add new data
    await box.add(data);
    _pillData = data;
    
    // Update user preference
    await _setHormonalBirthControlStatus(true);
    
    // Set reminders
    _scheduleReminders();
    
    notifyListeners();
  }
  
  // Update existing pill data
  Future<void> updatePillData(PillData updatedData) async {
    if (_pillData == null) return;
    
    final box = Hive.box<PillData>('pill_data');
    
    // Clear existing data
    await box.clear();
    
    // Add updated data
    await box.add(updatedData);
    _pillData = updatedData;
    
    // Reset reminders
    _scheduleReminders();
    
    notifyListeners();
  }
  
  // Delete pill data
  Future<void> deletePillData() async {
    final box = Hive.box<PillData>('pill_data');
    await box.clear();
    _pillData = null;
    
    // Update user preference
    await _setHormonalBirthControlStatus(false);
    
    // Cancel all reminders
    await _notificationService.cancelAllPillReminders();
    
    notifyListeners();
  }
  
  // Update hormonal birth control status
  Future<void> _setHormonalBirthControlStatus(bool value) async {
    final box = Hive.box('user_preferences');
    await box.put('using_hormonal_bc', value);
    _isUsingHormonalBirthControl = value;
    notifyListeners();
  }
  
  // Log pill taken
  Future<void> logPillTaken(DateTime date, String status, {String notes = ''}) async {
    if (_pillData == null) return;
    
    final now = DateTime.now();
    final newLogEntry = PillLogEntry(
      date: date,
      taken: true,
      status: status,
      takenTime: now,
      notes: notes,
    );
    
    // Add to logs
    final updatedLogs = List<PillLogEntry>.from(_pillData!.pillLogs);
    
    // Check if there's already an entry for this date
    final existingIndex = updatedLogs.indexWhere(
      (log) => log.date.year == date.year && 
               log.date.month == date.month && 
               log.date.day == date.day
    );
    
    if (existingIndex >= 0) {
      // Replace existing entry
      updatedLogs[existingIndex] = newLogEntry;
    } else {
      // Add new entry
      updatedLogs.add(newLogEntry);
    }
    
    // Create updated pill data
    final updatedPillData = _pillData!.copyWith(
      pillLogs: updatedLogs,
    );
    
    // Update in Hive
    await updatePillData(updatedPillData);
  }
  
  // Log pill missed
  Future<void> logPillMissed(DateTime date, {String notes = ''}) async {
    if (_pillData == null) return;
    
    final newLogEntry = PillLogEntry(
      date: date,
      taken: false,
      status: PillStatus.missed,
      notes: notes,
    );
    
    // Add to logs
    final updatedLogs = List<PillLogEntry>.from(_pillData!.pillLogs);
    
    // Check if there's already an entry for this date
    final existingIndex = updatedLogs.indexWhere(
      (log) => log.date.year == date.year && 
               log.date.month == date.month && 
               log.date.day == date.day
    );
    
    if (existingIndex >= 0) {
      // Replace existing entry
      updatedLogs[existingIndex] = newLogEntry;
    } else {
      // Add new entry
      updatedLogs.add(newLogEntry);
    }
    
    // Create updated pill data
    final updatedPillData = _pillData!.copyWith(
      pillLogs: updatedLogs,
    );
    
    // Update in Hive
    await updatePillData(updatedPillData);
  }
  
  // Get logs for a specific month
  List<PillLogEntry> getLogsForMonth(DateTime month) {
    if (_pillData == null) return [];
    
    return _pillData!.pillLogs.where((log) => 
      log.date.year == month.year && log.date.month == month.month
    ).toList();
  }
  
  // Get pill adherence rate (percentage of pills taken) for the last month
  double getPillAdherenceRate() {
    if (_pillData == null || _pillData!.pillLogs.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    final recentLogs = _pillData!.pillLogs.where((log) => 
      log.date.isAfter(oneMonthAgo) || log.date.isAtSameMomentAs(oneMonthAgo)
    ).toList();
    
    if (recentLogs.isEmpty) return 0.0;
    
    final takenCount = recentLogs.where((log) => log.taken).length;
    return takenCount / recentLogs.length;
  }
  
  // Calculate next pack start date
  DateTime calculateNextPackStartDate() {
    if (_pillData == null) return DateTime.now();
    
    final totalDays = _pillData!.activePillCount + _pillData!.placeboPillCount;
    return _pillData!.startDate.add(Duration(days: totalDays));
  }
  
  // Set up daily reminders based on pill data
  Future<void> _scheduleReminders() async {
    if (_pillData == null || !_pillData!.reminderEnabled) {
      await _notificationService.cancelAllPillReminders();
      return;
    }
    
    // Parse reminder time HH:MM
    final timeParts = _pillData!.reminderTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Schedule main reminder
    await _notificationService.scheduleDailyPillReminder(
      hour, 
      minute,
      _pillData!.isActivePillDay() ? 'Take your pill' : 'Take your placebo pill',
      _pillData!.isActivePillDay() 
        ? 'Time to take your daily contraceptive pill' 
        : 'Time to take your placebo pill to maintain routine',
    );
    
    // Schedule pre-alarm if enabled
    if (_pillData!.preAlarmEnabled) {
      // Calculate pre-alarm time
      final preAlarmTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      ).subtract(Duration(minutes: _pillData!.preAlarmMinutes));
      
      await _notificationService.scheduleDailyPillReminder(
        preAlarmTime.hour,
        preAlarmTime.minute,
        'Pill reminder coming up',
        'Your pill reminder will go off in ${_pillData!.preAlarmMinutes} minutes',
        id: 2001,
      );
    }
  }
  
  // Update reminder settings
  Future<void> updateReminderSettings({
    String? reminderTime,
    bool? reminderEnabled,
    bool? preAlarmEnabled,
    int? preAlarmMinutes,
    bool? autoSnoozeEnabled,
    int? autoSnoozeMinutes,
    int? autoSnoozeRepeat,
  }) async {
    if (_pillData == null) return;
    
    final updatedPillData = _pillData!.copyWith(
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      preAlarmEnabled: preAlarmEnabled,
      preAlarmMinutes: preAlarmMinutes,
      autoSnoozeEnabled: autoSnoozeEnabled,
      autoSnoozeMinutes: autoSnoozeMinutes,
      autoSnoozeRepeat: autoSnoozeRepeat,
    );
    
    await updatePillData(updatedPillData);
  }
  
  // Update next refill date
  Future<void> updateNextRefillDate(DateTime newDate) async {
    if (_pillData == null) return;
    
    final updatedPillData = _pillData!.copyWith(
      nextRefillDate: newDate,
    );
    
    await updatePillData(updatedPillData);
  }
  
  // Start new pack
  Future<void> startNewPack(DateTime startDate) async {
    if (_pillData == null) return;
    
    // Calculate next refill date based on pack length
    final totalDays = _pillData!.activePillCount + _pillData!.placeboPillCount;
    final nextRefillDate = startDate.add(Duration(days: totalDays - 7)); // 7 days before pack ends
    
    final updatedPillData = _pillData!.copyWith(
      startDate: startDate,
      nextRefillDate: nextRefillDate,
    );
    
    await updatePillData(updatedPillData);
  }
} 