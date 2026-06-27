import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';

abstract class DailyLogRepository {
  Stream<Either<Failure, List<DailyLogEntity>>> watchLogs(String athleteId);
  Future<Either<Failure, DailyLogEntity?>> getLogByDate(
    String athleteId, String date);
  Future<Either<Failure, DailyLogEntity>> saveLog(DailyLogEntity log);
  Future<Either<Failure, List<DailyLogEntity>>> getLogsInRange(
    String athleteId, int days);
}
