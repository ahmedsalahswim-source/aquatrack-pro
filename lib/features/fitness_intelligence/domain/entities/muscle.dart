import 'package:equatable/equatable.dart';

enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  core,
  legs,
}

enum ActivationLevel {
  none,
  low,
  medium,
  high,
  veryHigh,
}

class Muscle extends Equatable {
  final String id;
  final String name; // e.g., Latissimus Dorsi
  final String commonName; // e.g., Lats
  final MuscleGroup group;
  final String function;
  final String roleInSwimming;
  final List<String> relatedSkills; // e.g., ['Pull Phase', 'Start']
  final List<String> commonInjuries;
  
  const Muscle({
    required this.id,
    required this.name,
    required this.commonName,
    required this.group,
    required this.function,
    required this.roleInSwimming,
    required this.relatedSkills,
    required this.commonInjuries,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        commonName,
        group,
        function,
        roleInSwimming,
        relatedSkills,
        commonInjuries,
      ];
}
