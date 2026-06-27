import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aquatrack_pro/core/constants/firebase_constants.dart';
import 'package:aquatrack_pro/core/errors/exceptions.dart';
import 'package:aquatrack_pro/features/athlete/data/models/athlete_model.dart';

abstract class AthleteRemoteDataSource {
  Stream<List<AthleteModel>> watchAthletes(String parentId);
  Future<AthleteModel> getAthlete(String athleteId);
  Future<AthleteModel> addAthlete(AthleteModel athlete);
  Future<AthleteModel> updateAthlete(AthleteModel athlete);
  Future<void> deleteAthlete(String athleteId);
}

class AthleteRemoteDataSourceImpl implements AthleteRemoteDataSource {
  final FirebaseFirestore firestore;

  AthleteRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<AthleteModel>> watchAthletes(String parentId) {
    return firestore
        .collection(FirebaseCollections.athletes)
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AthleteModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<AthleteModel> getAthlete(String athleteId) async {
    final doc = await firestore
        .collection(FirebaseCollections.athletes)
        .doc(athleteId)
        .get();
    if (!doc.exists) {
      throw ServerException(message: 'المتدرب غير موجود');
    }
    return AthleteModel.fromFirestore(doc);
  }

  @override
  Future<AthleteModel> addAthlete(AthleteModel athlete) async {
    final docRef = firestore
        .collection(FirebaseCollections.athletes)
        .doc(athlete.id);
    await docRef.set(athlete.toFirestore());
    return athlete;
  }

  @override
  Future<AthleteModel> updateAthlete(AthleteModel athlete) async {
    await firestore
        .collection(FirebaseCollections.athletes)
        .doc(athlete.id)
        .update(athlete.toFirestore());
    return athlete;
  }

  @override
  Future<void> deleteAthlete(String athleteId) async {
    await firestore
        .collection(FirebaseCollections.athletes)
        .doc(athleteId)
        .update({'isActive': false});
  }
}
