import 'package:aquatrack_pro/core/utils/enums.dart';

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive
}

class NutritionCalculator {
  /// Calculates Basal Metabolic Rate using the Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required Gender gender,
  }) {
    if (gender == Gender.male) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) - 161;
    }
  }

  /// Calculates Total Daily Energy Expenditure (TDEE) based on activity level
  static double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.2;
      case ActivityLevel.lightlyActive:
        return bmr * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.55;
      case ActivityLevel.veryActive: // Normal Swimmer (1-2 hours)
        return bmr * 1.725;
      case ActivityLevel.extraActive: // Elite Swimmer (2+ hours)
        return bmr * 1.9;
    }
  }

  /// Recommends macros for a swimmer based on standard sports nutrition
  /// Carbohydrates: 55-65%
  /// Protein: 15-20%
  /// Fat: 20-30%
  static Map<String, double> calculateMacros(double tdee) {
    // 60% Carbs, 20% Protein, 20% Fat
    final carbCalories = tdee * 0.60;
    final proteinCalories = tdee * 0.20;
    final fatCalories = tdee * 0.20;

    return {
      'carbsG': carbCalories / 4.0,   // 4 kcal per gram of carb
      'proteinG': proteinCalories / 4.0, // 4 kcal per gram of protein
      'fatG': fatCalories / 9.0,      // 9 kcal per gram of fat
    };
  }
}
