import '../entities/pain_report.dart';

class InjuryPredictionEngine {
  /// Calculates the Injury Risk Score (0-100) based on training load, recovery, and pain reports.
  /// 0 = No Risk, 100 = Imminent Injury
  double calculateInjuryRisk({
    required double acwr, // Acute:Chronic Workload Ratio
    required double sleepQualityScore, // 0-100
    required List<PainReport> recentPains,
  }) {
    double riskScore = 10.0; // Base risk

    // 1. ACWR Impact (Sweet spot is 0.8 - 1.3)
    if (acwr > 1.5) {
      riskScore += 30.0; // Danger Zone
    } else if (acwr > 1.3) {
      riskScore += 15.0; // Caution Zone
    } else if (acwr < 0.8) {
      riskScore += 10.0; // Undertraining increases risk when spikes happen
    }

    // 2. Sleep Impact
    if (sleepQualityScore < 50) {
      riskScore += 20.0;
    } else if (sleepQualityScore < 70) {
      riskScore += 10.0;
    }

    // 3. Pain Impact
    for (var pain in recentPains) {
      if (pain.severity == PainSeverity.severe) riskScore += 40.0;
      if (pain.severity == PainSeverity.high) riskScore += 25.0;
      if (pain.severity == PainSeverity.moderate) riskScore += 10.0;
      
      if (pain.type == PainType.sharp) riskScore += 15.0;
      if (pain.duringSwimming) riskScore += 20.0; // Pain during action is worse than after
    }

    return riskScore.clamp(0.0, 100.0);
  }

  /// Calculates Fitness Readiness Score (0-100)
  double calculateReadinessScore({
    required double injuryRiskScore,
    required double recoveryScore,
    required double physicalTestAverage,
  }) {
    // Inverse injury risk
    double injuryFactor = 100 - injuryRiskScore;
    
    // Weighted formula: Recovery is 40%, Physical Condition is 30%, Safety(Injury) is 30%
    double readiness = (recoveryScore * 0.4) + (physicalTestAverage * 0.3) + (injuryFactor * 0.3);
    
    return readiness.clamp(0.0, 100.0);
  }
}
