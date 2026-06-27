import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import '../entities/muscle.dart';
import '../entities/exercise.dart';
import '../entities/pain_report.dart';
import '../entities/fitness_test.dart';
import '../entities/digital_twin.dart';

abstract class FitnessRepository {
  Future<Either<Failure, List<Muscle>>> getMuscles();
  Future<Either<Failure, List<Exercise>>> getExercisesByMuscle(String muscleId);
  Future<Either<Failure, List<FitnessTest>>> getFitnessTests();
  
  Future<Either<Failure, void>> savePainReport(PainReport report);
  Future<Either<Failure, List<PainReport>>> getPainReports(String athleteId);
  
  Future<Either<Failure, void>> saveTestResult(TestResult result);
  Future<Either<Failure, List<TestResult>>> getTestResults(String athleteId);

  Future<Either<Failure, AthleteDigitalTwin>> getDigitalTwin(String athleteId);
}
