import '../entities/exercise.dart';
import '../entities/digital_twin.dart';

class AutoProgramGenerator {
  /// Generates a personalized 4-week training program.
  List<Exercise> generateProgram({
    required AthleteDigitalTwin twin,
    required String targetSwimStroke,
    required List<Exercise> allExercises,
  }) {
    List<Exercise> program = [];

    // 1. Prioritize Weaknesses
    if (twin.currentWeaknesses.contains('Pull Phase') || twin.currentWeaknesses.contains('Stroke Length')) {
      // Find Lat/Back exercises
      program.addAll(allExercises.where((e) => e.targetMuscleIds.contains('lats') || e.targetMuscleIds.contains('back')).take(2));
    }

    if (twin.currentWeaknesses.contains('Start') || twin.currentWeaknesses.contains('Turn')) {
      // Find Explosive Leg/Core exercises
      program.addAll(allExercises.where((e) => e.targetMuscleIds.contains('legs') || e.targetMuscleIds.contains('core')).take(2));
    }

    // 2. Adjust for Injury Risk
    if (twin.injuryRiskScore > 70) {
      // High risk: Filter out advanced/elite exercises, focus on rehab/mobility
      program = program.where((e) => e.difficulty == DifficultyLevel.beginner || e.difficulty == DifficultyLevel.intermediate).toList();
      // Add mobility exercises explicitly...
    }

    // 3. Ensure full body coverage (add basic core and shoulder stability for swimmers)
    if (!program.any((e) => e.targetMuscleIds.contains('shoulders'))) {
      final shoulderEx = allExercises.firstWhere((e) => e.targetMuscleIds.contains('shoulders'), orElse: () => allExercises.first);
      program.add(shoulderEx);
    }

    // Return a subset tailored for a session (e.g., 5-6 exercises)
    return program.take(6).toList();
  }
}
