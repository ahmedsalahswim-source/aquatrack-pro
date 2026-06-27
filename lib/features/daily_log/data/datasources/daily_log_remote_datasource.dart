import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aquatrack_pro/core/constants/firebase_constants.dart';
import 'package:aquatrack_pro/features/daily_log/data/models/daily_log_model.dart';

abstract class DailyLogRemoteDataSource {
  Stream<List<DailyLogModel>> watchLogs(String athleteId);
  Future<DailyLogModel?> getLogByDate(String athleteId, String date);
  Future<DailyLogModel> saveLog(DailyLogModel log);
  Future<List<DailyLogModel>> getLogsInRange(String athleteId, int days);
}

class DailyLogRemoteDataSourceImpl implements DailyLogRemoteDataSource {
  final FirebaseFirestore firestore;

  DailyLogRemoteDataSourceImpl({required this.firestore});

  /// Requires Firestore composite index on [athleteId, date DESC] for the
  /// where + orderBy query below.
  @override
  Stream<List<DailyLogModel>> watchLogs(String athleteId) {
    return firestore
        .collection(FirebaseCollections.dailyLogs)
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyLogModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<DailyLogModel?> getLogByDate(String athleteId, String date) async {
    final query = await firestore
        .collection(FirebaseCollections.dailyLogs)
        .where('athleteId', isEqualTo: athleteId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return DailyLogModel.fromFirestore(query.docs.first);
  }

  @override
  Future<DailyLogModel> saveLog(DailyLogModel log) async {
    await firestore
        .collection(FirebaseCollections.dailyLogs)
        .doc(log.id)
        .set(log.toFirestore());
    return log;
  }

  /// Requires Firestore composite index on [athleteId, date DESC] for the
  /// where + orderBy query below.
  @override
  Future<List<DailyLogModel>> getLogsInRange(String athleteId, int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final query = await firestore
        .collection(FirebaseCollections.dailyLogs)
        .where('athleteId', isEqualTo: athleteId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String().substring(0, 10))
        .orderBy('date', descending: true)
        .get();
    return query.docs.map((doc) => DailyLogModel.fromFirestore(doc)).toList();
  }
}
