import 'package:hive/hive.dart';

part 'pill_data.g.dart';

@HiveType(typeId: 2)
class PillData extends HiveObject {
  @HiveField(0)
  final String contraceptiveMethod; // 'pill', 'patch', 'ring', etc.

  @HiveField(1)
  final int activePillCount; // Number of active pills in pack

  @HiveField(2)
  final int placeboPillCount; // Number of placebo pills in pack

  @HiveField(3)
  final DateTime startDate; // Date user started current pack

  @HiveField(4)
  final DateTime nextRefillDate; // Date to get next refill

  @HiveField(5)
  final String reminderTime; // Daily reminder time (HH:MM format)

  @HiveField(6)
  final bool reminderEnabled; // Whether daily reminder is enabled

  @HiveField(7)
  final List<PillLogEntry> pillLogs; // History of pill intake logs

  @HiveField(8)
  final String brandName; // Brand name of contraceptive

  @HiveField(9)
  final bool preAlarmEnabled; // Whether pre-alarm is enabled

  @HiveField(10)
  final int preAlarmMinutes; // Minutes before main alarm

  @HiveField(11)
  final bool autoSnoozeEnabled; // Whether auto-snooze is enabled
  
  @HiveField(12)
  final int autoSnoozeMinutes; // Minutes between auto-snooze

  @HiveField(13)
  final int autoSnoozeRepeat; // Number of times to auto-snooze

  PillData({
    required this.contraceptiveMethod,
    required this.activePillCount,
    required this.placeboPillCount,
    required this.startDate,
    required this.nextRefillDate,
    required this.reminderTime,
    this.reminderEnabled = true,
    this.pillLogs = const [],
    this.brandName = '',
    this.preAlarmEnabled = false,
    this.preAlarmMinutes = 30,
    this.autoSnoozeEnabled = false,
    this.autoSnoozeMinutes = 10,
    this.autoSnoozeRepeat = 3,
  });

  // Create a copy of this PillData with optional parameter changes
  PillData copyWith({
    String? contraceptiveMethod,
    int? activePillCount,
    int? placeboPillCount,
    DateTime? startDate,
    DateTime? nextRefillDate,
    String? reminderTime,
    bool? reminderEnabled,
    List<PillLogEntry>? pillLogs,
    String? brandName,
    bool? preAlarmEnabled,
    int? preAlarmMinutes,
    bool? autoSnoozeEnabled,
    int? autoSnoozeMinutes,
    int? autoSnoozeRepeat,
  }) {
    return PillData(
      contraceptiveMethod: contraceptiveMethod ?? this.contraceptiveMethod,
      activePillCount: activePillCount ?? this.activePillCount,
      placeboPillCount: placeboPillCount ?? this.placeboPillCount,
      startDate: startDate ?? this.startDate,
      nextRefillDate: nextRefillDate ?? this.nextRefillDate,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      pillLogs: pillLogs ?? List<PillLogEntry>.from(this.pillLogs),
      brandName: brandName ?? this.brandName,
      preAlarmEnabled: preAlarmEnabled ?? this.preAlarmEnabled,
      preAlarmMinutes: preAlarmMinutes ?? this.preAlarmMinutes,
      autoSnoozeEnabled: autoSnoozeEnabled ?? this.autoSnoozeEnabled,
      autoSnoozeMinutes: autoSnoozeMinutes ?? this.autoSnoozeMinutes,
      autoSnoozeRepeat: autoSnoozeRepeat ?? this.autoSnoozeRepeat,
    );
  }

  // Calculate current pill day in cycle
  int getCurrentPillDay() {
    final today = DateTime.now();
    final difference = today.difference(startDate).inDays;
    final totalDays = activePillCount + placeboPillCount;
    
    // Handle case when we're beyond the current pack
    if (difference >= totalDays) {
      // Calculate day in current pack based on cycle length
      return (difference % totalDays) + 1;
    }
    
    // Within current pack
    return difference + 1;
  }

  // Check if current day is active pill day
  bool isActivePillDay() {
    final currentDay = getCurrentPillDay();
    return currentDay <= activePillCount;
  }

  // Check if pill was taken today
  bool isPillTakenToday() {
    final today = DateTime.now();
    return pillLogs.any((log) => 
      log.date.year == today.year && 
      log.date.month == today.month && 
      log.date.day == today.day && 
      log.taken
    );
  }

  // Get remaining pills in current pack
  int getRemainingPills() {
    final totalDays = activePillCount + placeboPillCount;
    final currentDay = getCurrentPillDay();
    
    if (currentDay > totalDays) return 0;
    return totalDays - currentDay + 1;
  }

  // Check if refill alert should be shown (when less than 7 pills remaining)
  bool shouldShowRefillAlert() {
    return getRemainingPills() <= 7;
  }
}

@HiveType(typeId: 3)
class PillLogEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final bool taken;
  
  @HiveField(2)
  final String status; // 'on-time', 'late', 'missed', 'placebo'
  
  @HiveField(3)
  final DateTime? takenTime; // Time when pill was taken
  
  @HiveField(4)
  final String notes;
  
  PillLogEntry({
    required this.date,
    required this.taken,
    required this.status,
    this.takenTime,
    this.notes = '',
  });
}

// Enum Classes for better type safety
class ContraceptiveMethod {
  static const String pill = 'pill';
  static const String patch = 'patch';
  static const String ring = 'ring';
  static const String implant = 'implant';
  static const String iud = 'iud';
  static const String injection = 'injection';
  
  static List<String> values = [pill, patch, ring, implant, iud, injection];
  
  static List<String> displayNames = [
    'Pill',
    'Patch',
    'Ring',
    'Implant',
    'IUD',
    'Injection'
  ];
}

class PillStatus {
  static const String onTime = 'on-time';
  static const String late = 'late';
  static const String missed = 'missed';
  static const String placebo = 'placebo';
  
  static List<String> values = [onTime, late, missed, placebo];
} 