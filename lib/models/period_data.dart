import 'package:hive/hive.dart';

part 'period_data.g.dart';

@HiveType(typeId: 0)
class PeriodData extends HiveObject {
  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime? endDate;

  @HiveField(2)
  final String flowIntensity; // 'light', 'medium', 'heavy'

  @HiveField(3)
  final List<String> symptoms; // List of symptoms experienced

  @HiveField(4)
  final String mood; // 'happy', 'sad', 'irritable', 'neutral', etc.

  @HiveField(5)
  final String notes; // Any additional notes
  
  @HiveField(6)
  final List<IntimacyData>? intimacyData; // List of intimacy entries

  PeriodData({
    required this.startDate,
    this.endDate,
    this.flowIntensity = 'medium',
    this.symptoms = const [],
    this.mood = 'neutral',
    this.notes = '',
    this.intimacyData,
  });

  int get durationInDays {
    if (endDate == null) return 0;
    return endDate!.difference(startDate).inDays + 1; // Include both start and end days
  }

  // Create a copy of this PeriodData with optional parameter changes
  PeriodData copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? flowIntensity,
    List<String>? symptoms,
    String? mood,
    String? notes,
    List<IntimacyData>? intimacyData,
  }) {
    return PeriodData(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      symptoms: symptoms ?? List<String>.from(this.symptoms),
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      intimacyData: intimacyData ?? this.intimacyData,
    );
  }
}

// New class for intimacy data
@HiveType(typeId: 1)
class IntimacyData extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final bool hadIntimacy;
  
  @HiveField(2)
  final bool wasProtected;
  
  @HiveField(3)
  final String notes;
  
  IntimacyData({
    required this.date,
    required this.hadIntimacy,
    this.wasProtected = false,
    this.notes = '',
  });
}

// Enum Classes for better type safety
class FlowIntensity {
  static const String light = 'light';
  static const String medium = 'medium';
  static const String heavy = 'heavy';
  
  static List<String> values = [light, medium, heavy];
}

class MoodType {
  static const String happy = 'happy';
  static const String sad = 'sad';
  static const String neutral = 'neutral';
  static const String irritable = 'irritable';
  static const String anxious = 'anxious';
  static const String energetic = 'energetic';
  static const String tired = 'tired';
  
  static List<String> values = [
    happy, sad, neutral, irritable, anxious, energetic, tired
  ];
}

class SymptomType {
  static const String cramps = 'cramps';
  static const String headache = 'headache';
  static const String backache = 'backache';
  static const String bloating = 'bloating';
  static const String acne = 'acne';
  static const String fatigue = 'fatigue';
  static const String breastTenderness = 'breast tenderness';
  static const String nausea = 'nausea';
  static const String cravings = 'cravings';
  
  static List<String> values = [
    cramps, headache, backache, bloating, acne, 
    fatigue, breastTenderness, nausea, cravings
  ];
} 