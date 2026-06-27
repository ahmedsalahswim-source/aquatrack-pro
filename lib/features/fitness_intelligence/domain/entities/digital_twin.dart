import 'package:equatable/equatable.dart';

class AthleteDigitalTwin extends Equatable {
  final String athleteId;
  final DateTime lastUpdated;
  
  // Scores out of 100
  final double recoveryScore;
  final double fitnessScore;
  final double injuryRiskScore;
  final double techniqueScore;
  final double readinessScore;
  final double nutritionScore;
  final double overallScore; // Aggregate

  final List<String> currentWeaknesses;
  final List<String> activePainAreas;

  const AthleteDigitalTwin({
    required this.athleteId,
    required this.lastUpdated,
    required this.recoveryScore,
    required this.fitnessScore,
    required this.injuryRiskScore,
    required this.techniqueScore,
    required this.readinessScore,
    required this.nutritionScore,
    required this.overallScore,
    required this.currentWeaknesses,
    required this.activePainAreas,
  });

  @override
  List<Object?> get props => [
        athleteId,
        lastUpdated,
        recoveryScore,
        fitnessScore,
        injuryRiskScore,
        techniqueScore,
        readinessScore,
        nutritionScore,
        overallScore,
        currentWeaknesses,
        activePainAreas,
      ];
}
