import 'package:equatable/equatable.dart';

enum PainSeverity {
  low, // 1-3
  moderate, // 4-6
  high, // 7-8
  severe, // 9-10
}

enum PainType {
  sharp,
  dull,
  throbbing,
  burning,
  aching,
}

class PainReport extends Equatable {
  final String id;
  final String athleteId;
  final String muscleId;
  final DateTime date;
  final PainSeverity severity;
  final PainType type;
  final bool duringSwimming;
  final bool afterSwimming;
  final bool duringFitness;

  const PainReport({
    required this.id,
    required this.athleteId,
    required this.muscleId,
    required this.date,
    required this.severity,
    required this.type,
    required this.duringSwimming,
    required this.afterSwimming,
    required this.duringFitness,
  });

  @override
  List<Object?> get props => [
        id,
        athleteId,
        muscleId,
        date,
        severity,
        type,
        duringSwimming,
        afterSwimming,
        duringFitness,
      ];
}
