import 'package:intl/intl.dart';

class DateHelpers {
  DateHelpers._();

  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static bool isInAgeRange(DateTime birthDate) {
    final age = calculateAge(birthDate);
    return age >= 6 && age <= 18;
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateArabic(DateTime date) {
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'ar');
    return formatter.format(date);
  }

  static DateTime getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  static String getDayNameArabic(DateTime date) {
    final formatter = DateFormat('EEEE', 'ar');
    return formatter.format(date);
  }

  static (double min, double max) sleepRecommendationByAge(int age) {
    if (age >= 6 && age <= 12) return (9.0, 12.0);
    if (age >= 13 && age <= 18) return (8.0, 10.0);
    return (7.0, 9.0);
  }

  static (int min, int max) hrNormalRangeByAge(int age) {
    if (age >= 6 && age <= 12) return (70, 110);
    if (age >= 13 && age <= 18) return (60, 100);
    return (60, 100);
  }
}
