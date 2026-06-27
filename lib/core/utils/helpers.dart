class StressCalculator {
  StressCalculator._();

  static int calculate({
    required double? sleepHours,
    required double? recommendedSleep,
    required int? restingHR,
    required int? baselineHR,
    required int? rpe,
    required int? wellnessScore,
  }) {
    double sleepScore = 0;
    if (sleepHours != null && recommendedSleep != null) {
      final deficit = recommendedSleep - sleepHours;
      if (deficit > 0) {
        sleepScore = (deficit * 10).clamp(0, 30);
      }
    }

    double hrScore = 0;
    if (restingHR != null && baselineHR != null) {
      final deviation = (restingHR - baselineHR).abs();
      if (deviation > 15) {
        hrScore = 25;
      } else if (deviation > 10) {
        hrScore = 15;
      } else if (deviation > 5) {
        hrScore = 5;
      }
    }

    double rpeScore = 0;
    if (rpe != null) {
      if (rpe >= 9) {
        rpeScore = 25;
      } else if (rpe >= 7) {
        rpeScore = 15;
      } else if (rpe >= 4) {
        rpeScore = 5;
      }
    }

    double wellnessScoreValue = 0;
    if (wellnessScore != null) {
      wellnessScoreValue = {
        1: 25.0,
        2: 18.0,
        3: 10.0,
        4: 5.0,
        5: 0.0,
      }[wellnessScore] ?? 0;
    }

    final total = (sleepScore * 0.3) + (hrScore * 0.25) + (rpeScore * 0.3) + (wellnessScoreValue * 0.15);
    return (total * 100).round().clamp(0, 100);
  }

  static String getStressLabel(int score) {
    if (score <= 30) return 'ممتاز';
    if (score <= 60) return 'طبيعي';
    if (score <= 80) return 'تحذير';
    return 'خطر';
  }
}

class AcwrCalculator {
  AcwrCalculator._();

  static double calculate({
    required List<double> acuteLoads,
    List<double>? chronicLoads,
  }) {
    if (acuteLoads.length < 7) return 0;
    final acute = acuteLoads.fold<double>(0, (sum, load) => sum + load) / acuteLoads.length;
    if (chronicLoads != null && chronicLoads.length >= 7) {
      final chronicAvg = chronicLoads.fold<double>(0, (sum, load) => sum + load) / chronicLoads.length;
      if (chronicAvg == 0) return 0;
      return (acute / chronicAvg).clamp(0, 3);
    }
    return 0;
  }

  static String getAcwrLabel(double acwr) {
    if (acwr < 0.8) return 'نشاط منخفض';
    if (acwr <= 1.3) return 'النطاق الآمن';
    if (acwr <= 1.5) return 'تحذير — الحمل يرتفع';
    return 'خطر — خطر الإصابة مرتفع';
  }
}
