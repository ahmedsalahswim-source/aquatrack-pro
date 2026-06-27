import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class AthleteEntity extends Equatable {
  final String id;
  final String parentId;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final SwimLevel swimLevel;
  final double? weightKg;
  final double? heightCm;
  final double targetWeeklyHours;
  final int? restingHRBaseline;
  final double? sleepBaseline;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  const AthleteEntity({
    required this.id,
    required this.parentId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.swimLevel = SwimLevel.beginner,
    this.weightKg,
    this.heightCm,
    this.targetWeeklyHours = 6,
    this.restingHRBaseline,
    this.sleepBaseline,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get canCalculateBaseline => restingHRBaseline != null && sleepBaseline != null;

  @override
  List<Object?> get props => [
    id, parentId, name, birthDate, gender, swimLevel, weightKg, heightCm,
    targetWeeklyHours, restingHRBaseline, sleepBaseline, photoUrl, isActive, createdAt,
  ];
}
