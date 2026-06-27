import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.role = UserRole.parent,
    super.subscriptionPlan = SubscriptionPlan.free,
    super.athleteIds = const [],
    super.hasConsented = false,
    super.consentTimestamp,
    required super.createdAt,
    super.lastActiveAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: (data['uid'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'parent'),
        orElse: () => UserRole.parent,
      ),
      subscriptionPlan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == (data['subscriptionPlan'] as String? ?? 'free'),
        orElse: () => SubscriptionPlan.free,
      ),
      athleteIds: List<String>.from(data['athleteIds'] ?? []),
      hasConsented: data['hasConsented'] as bool? ?? false,
      consentTimestamp: (data['consentTimestamp'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'subscriptionPlan': subscriptionPlan.name,
      'athleteIds': athleteIds,
      'hasConsented': hasConsented,
      'consentTimestamp': consentTimestamp != null ? Timestamp.fromDate(consentTimestamp!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }
}
