import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/core/constants/app_constants.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final SubscriptionPlan subscriptionPlan;
  final List<String> athleteIds;
  final bool hasConsented;
  final DateTime? consentTimestamp;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = UserRole.parent,
    this.subscriptionPlan = SubscriptionPlan.free,
    this.athleteIds = const [],
    this.hasConsented = false,
    this.consentTimestamp,
    required this.createdAt,
    this.lastActiveAt,
  });

  bool get isPro => subscriptionPlan == SubscriptionPlan.pro;
  bool get canAddMoreAthletes {
    return isPro
        ? athleteIds.length < AppConstants.maxAthletesPro
        : athleteIds.length < AppConstants.maxAthletesFree;
  }

  @override
  List<Object?> get props => [
    uid, email, displayName, photoUrl, role, subscriptionPlan,
    athleteIds, hasConsented, consentTimestamp, createdAt, lastActiveAt,
  ];
}
