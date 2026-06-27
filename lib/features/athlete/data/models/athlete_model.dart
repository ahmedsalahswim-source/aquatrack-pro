import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AthleteModel extends AthleteEntity {
  const AthleteModel({
    required super.id,
    required super.parentId,
    required super.name,
    required super.birthDate,
    required super.gender,
    super.swimLevel = SwimLevel.beginner,
    super.weightKg,
    super.heightCm,
    super.targetWeeklyHours = 6,
    super.restingHRBaseline,
    super.sleepBaseline,
    super.photoUrl,
    super.isActive = true,
    required super.createdAt,
  });

  factory AthleteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AthleteModel(
      id: doc.id,
      parentId: data['parentId'] as String,
      name: data['name'] as String,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      gender: Gender.values.firstWhere(
        (e) => e.name == (data['gender'] as String? ?? 'male'),
        orElse: () => Gender.male,
      ),
      swimLevel: SwimLevel.values.firstWhere(
        (e) => e.name == (data['swimLevel'] as String? ?? 'beginner'),
        orElse: () => SwimLevel.beginner,
      ),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      targetWeeklyHours: (data['targetWeeklyHours'] as num?)?.toDouble() ?? 6,
      restingHRBaseline: data['restingHRBaseline'] as int?,
      sleepBaseline: (data['sleepBaseline'] as num?)?.toDouble(),
      photoUrl: data['photoUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.name,
      'swimLevel': swimLevel.name,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'targetWeeklyHours': targetWeeklyHours,
      'restingHRBaseline': restingHRBaseline,
      'sleepBaseline': sleepBaseline,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
