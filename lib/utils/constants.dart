import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B99);     // Main pink
  static const Color secondary = Color(0xFFFF9EB9);   // Lighter pink
  static const Color accent = Color(0xFFFF4081);      // Accent pink
  static const Color background = Color(0xFFFFFAFB);  // Light pink-tinted white
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF424242);
  static const Color textMedium = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Functional colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFD54F);
  
  // Flow intensity colors
  static const Color flowLight = Color(0xFFFFCDD2);
  static const Color flowMedium = Color(0xFFFF80AB);
  static const Color flowHeavy = Color(0xFFE91E63);
}

class AppConstants {
  // Average cycle length for predictions
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 35;
  
  // Fertility window
  static const int ovulationDayOffset = 14;  // Days before next period
  static const int fertileDaysBeforeOvulation = 5;
  static const int fertileDaysAfterOvulation = 1;
  
  // Notification IDs
  static const int periodStartNotificationId = 1001;
  static const int fertileDaysNotificationId = 1002;
  static const int ovulationNotificationId = 1003;
  
  // Prediction accuracy text
  static const String lowAccuracy = "Low accuracy (fewer than 3 cycles recorded)";
  static const String mediumAccuracy = "Medium accuracy (3-6 cycles recorded)";
  static const String highAccuracy = "High accuracy (more than 6 cycles recorded)";
} 