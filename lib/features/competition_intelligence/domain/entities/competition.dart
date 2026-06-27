import 'package:equatable/equatable.dart';

enum PoolLength {
  shortCourse25m,
  longCourse50m,
}

enum CompetitionLevel {
  local,
  national,
  international,
  olympic,
}

class Competition extends Equatable {
  final String id;
  final String name;
  final DateTime date;
  final String location;
  final PoolLength poolLength;
  final CompetitionLevel level;

  const Competition({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.poolLength,
    required this.level,
  });

  @override
  List<Object?> get props => [id, name, date, location, poolLength, level];
}
