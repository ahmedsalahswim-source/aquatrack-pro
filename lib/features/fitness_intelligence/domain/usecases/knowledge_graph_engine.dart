import '../entities/muscle.dart';
import '../entities/exercise.dart';
import '../../../../core/models/swim_pose_metrics.dart';

class KnowledgeGraphEngine {
  // This engine acts as the central router between swimming technique, muscles, and exercises.
  // In a real database, these would be edge relations in a graph DB (like Neo4j).
  // Here we use an in-memory graph representation.

  /// Returns muscles required for a specific swimming stroke and phase
  List<Muscle> getMusclesForSwimPhase(String stroke, SwimStrokePhase phase, List<Muscle> allMuscles) {
    // Highly simplified graph relation mapping.
    // E.g., Freestyle Pull Phase -> Lats, Shoulders, Triceps
    if (stroke.toLowerCase() == 'freestyle') {
      if (phase == SwimStrokePhase.pull) {
        return allMuscles.where((m) => m.name.contains('Latissimus') || m.group == MuscleGroup.shoulders || m.group == MuscleGroup.arms).toList();
      }
      if (phase == SwimStrokePhase.push) {
        return allMuscles.where((m) => m.group == MuscleGroup.legs || m.group == MuscleGroup.core).toList();
      }
    }
    return [];
  }

  /// Suggests exercises based on a technique weakness (e.g., poor stroke length)
  List<Exercise> getExercisesForTechniqueWeakness(String weakness, List<Muscle> allMuscles, List<Exercise> allExercises) {
    List<Exercise> suggestions = [];
    
    if (weakness.toLowerCase().contains('stroke length') || weakness.toLowerCase().contains('pull')) {
      final lats = allMuscles.where((m) => m.name.contains('Latissimus') || m.name.contains('Back')).map((m) => m.id).toList();
      suggestions.addAll(allExercises.where((e) => e.targetMuscleIds.any((id) => lats.contains(id))));
    }
    
    if (weakness.toLowerCase().contains('kick') || weakness.toLowerCase().contains('start')) {
      final legs = allMuscles.where((m) => m.group == MuscleGroup.legs).map((m) => m.id).toList();
      suggestions.addAll(allExercises.where((e) => e.targetMuscleIds.any((id) => legs.contains(id))));
    }

    return suggestions;
  }

  /// Calculates an activation map (color coding) for the 3D/SVG body model
  Map<String, ActivationLevel> getMuscleActivationMap(String stroke) {
    final map = <String, ActivationLevel>{};
    final s = stroke.toLowerCase();
    
    if (s == 'freestyle') {
      map['Latissimus Dorsi'] = ActivationLevel.veryHigh;
      map['Deltoids'] = ActivationLevel.veryHigh;
      map['Triceps'] = ActivationLevel.veryHigh;
      map['Core'] = ActivationLevel.high;
      map['Glutes'] = ActivationLevel.high;
      map['Quadriceps'] = ActivationLevel.medium;
    } else if (s == 'butterfly') {
      map['Latissimus Dorsi'] = ActivationLevel.veryHigh;
      map['Core'] = ActivationLevel.veryHigh;
      map['Pectoralis Major'] = ActivationLevel.high;
      map['Glutes'] = ActivationLevel.high;
      map['Hamstrings'] = ActivationLevel.medium;
    } else if (s == 'breaststroke') {
      map['Pectoralis Major'] = ActivationLevel.veryHigh;
      map['Latissimus Dorsi'] = ActivationLevel.high;
      map['Quadriceps'] = ActivationLevel.veryHigh;
      map['Glutes'] = ActivationLevel.high;
      map['Adductors'] = ActivationLevel.veryHigh;
    } else if (s == 'backstroke') {
      map['Latissimus Dorsi'] = ActivationLevel.veryHigh;
      map['Deltoids'] = ActivationLevel.high;
      map['Quadriceps'] = ActivationLevel.veryHigh;
      map['Core'] = ActivationLevel.high;
      map['Hamstrings'] = ActivationLevel.medium;
    }
    return map;
  }
  
  /// Provides professional external resources (like YouTube links) for a specific exercise or drill
  List<String> getExternalResourcesForExercise(String exerciseName) {
    final Map<String, List<String>> resources = {
      'Pull-Ups': [
        'https://www.youtube.com/watch?v=eGo4IYtl4h0 (Perfect Pull-Up Form)',
        'https://www.youtube.com/watch?v=y5jwCGjsXbQ (Swimming Specific Pull-Ups)',
      ],
      'Squats': [
        'https://www.youtube.com/watch?v=gcNh17Ckjgg (Squat Mechanics)',
      ],
      'Plank': [
        'https://www.youtube.com/watch?v=ASdvN_XEl_c (Core Stability for Swimmers)',
      ],
      'Plyometric Jumps': [
        'https://www.youtube.com/watch?v=52TjLpGgP3Q (Explosive Starts for Swimming)',
      ]
    };
    
    // Fuzzy matching or direct lookup
    for (var key in resources.keys) {
      if (exerciseName.toLowerCase().contains(key.toLowerCase())) {
        return resources[key]!;
      }
    }
    
    // Fallback: Return a YouTube search query specifically tailored for swimming
    return ['https://www.youtube.com/results?search_query=${Uri.encodeComponent('$exerciseName for swimmers tutorial')}'];
  }
}
