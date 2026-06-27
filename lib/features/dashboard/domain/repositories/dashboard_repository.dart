import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

abstract class DashboardRepository {
  Stream<Either<Failure, DashboardData>> watchDashboard(AthleteEntity athlete);
}
