class AppConstants {
  AppConstants._();

  static const String appName = 'AquaTrack Pro';
  static const String appVersion = '1.0.0';

  static const int minAgeYears = 6;
  static const int maxAgeYears = 18;

  static const double minWeightKg = 15.0;
  static const double maxWeightKg = 120.0;
  static const double minHeightCm = 100.0;
  static const double maxHeightCm = 220.0;
  static const double minWeeklyHours = 1.0;
  static const double maxWeeklyHours = 40.0;

  static const int minRestingHR = 30;
  static const int maxRestingHR = 200;
  static const int minSleepHours = 0;
  static const int maxSleepHours = 16;
  static const double sleepStep = 0.5;
  static const double minWaterLiters = 0.0;
  static const double maxWaterLiters = 3.0;
  static const double waterStep = 0.25;
  static const int maxRPE = 10;
  static const int minTrainingMinutes = 15;
  static const int maxTrainingMinutes = 180;

  static const int freeMessagesPerDay = 20;
  static const int maxAthletesFree = 1;
  static const int maxAthletesPro = 5;

  static const String proMonthlyPrice = '49';
  static const String proYearlyPrice = '399';
}
