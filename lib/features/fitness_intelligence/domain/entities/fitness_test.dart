import 'package:equatable/equatable.dart';

class FitnessTest extends Equatable {
  final String id;
  final String name;
  final String description;
  final String unit; // e.g. "reps", "cm", "seconds"
  final double expectedStandard; // The average benchmark
  final String? lottieUrl;

  const FitnessTest({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.expectedStandard,
    this.lottieUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        unit,
        expectedStandard,
        lottieUrl,
      ];
}

class TestResult extends Equatable {
  final String id;
  final String testId;
  final String athleteId;
  final DateTime date;
  final double value;

  const TestResult({
    required this.id,
    required this.testId,
    required this.athleteId,
    required this.date,
    required this.value,
  });

  @override
  List<Object?> get props => [id, testId, athleteId, date, value];
}
