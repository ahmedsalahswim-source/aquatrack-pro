import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/nutrition/domain/entities/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator Tests', () {
    test('Calculates BMR correctly for Male', () {
      // Mifflin-St Jeor: (10 * 70) + (6.25 * 175) - (5 * 25) + 5
      // 700 + 1093.75 - 125 + 5 = 1673.75
      final bmr = NutritionCalculator.calculateBMR(
        weightKg: 70,
        heightCm: 175,
        ageYears: 25,
        gender: Gender.male,
      );

      expect(bmr, closeTo(1673.75, 0.1));
    });

    test('Calculates BMR correctly for Female', () {
      // Mifflin-St Jeor: (10 * 60) + (6.25 * 165) - (5 * 22) - 161
      // 600 + 1031.25 - 110 - 161 = 1360.25
      final bmr = NutritionCalculator.calculateBMR(
        weightKg: 60,
        heightCm: 165,
        ageYears: 22,
        gender: Gender.female,
      );

      expect(bmr, closeTo(1360.25, 0.1));
    });

    test('Calculates TDEE correctly for Elite Swimmer', () {
      final tdee = NutritionCalculator.calculateTDEE(
        bmr: 1500,
        activityLevel: ActivityLevel.extraActive, // Multiplier 1.9
      );

      expect(tdee, closeTo(1500 * 1.9, 0.1)); // 2850
    });

    test('Calculates Macros correctly based on 60/20/20 ratio', () {
      final tdee = 3000.0;
      final macros = NutritionCalculator.calculateMacros(tdee);

      // Carbs: 60% of 3000 = 1800 kcal / 4 = 450g
      // Protein: 20% of 3000 = 600 kcal / 4 = 150g
      // Fat: 20% of 3000 = 600 kcal / 9 = 66.66g

      expect(macros['carbsG'], closeTo(450.0, 0.1));
      expect(macros['proteinG'], closeTo(150.0, 0.1));
      expect(macros['fatG'], closeTo(66.66, 0.1));
    });
  });
}
