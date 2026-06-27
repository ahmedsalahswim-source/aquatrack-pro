import 'package:equatable/equatable.dart';

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  elite,
}

class Exercise extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> targetMuscleIds;
  final DifficultyLevel difficulty;
  final String recommendedAge;
  final String trainingGoal; // e.g. "Power", "Endurance", "Hypertrophy"
  final String setsAndReps; // e.g. "3 sets of 10-12 reps"
  final String restPeriod;
  final String? videoUrl; // Nullable for when using lottie instead
  final String? lottieUrl; // URL or local asset path to Lottie
  final List<String> commonMistakes;
  final List<String> safetyInstructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMuscleIds,
    required this.difficulty,
    required this.recommendedAge,
    required this.trainingGoal,
    required this.setsAndReps,
    required this.restPeriod,
    this.videoUrl,
    this.lottieUrl,
    required this.commonMistakes,
    required this.safetyInstructions,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        targetMuscleIds,
        difficulty,
        recommendedAge,
        trainingGoal,
        setsAndReps,
        restPeriod,
        videoUrl,
        lottieUrl,
        commonMistakes,
        safetyInstructions,
      ];
}
