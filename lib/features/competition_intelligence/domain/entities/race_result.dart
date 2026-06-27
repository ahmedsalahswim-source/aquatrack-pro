import 'package:equatable/equatable.dart';

class RaceResult extends Equatable {
  final String id;
  final String competitionId;
  final String athleteId;
  final String eventName; // e.g., "50m Freestyle"
  final Duration time;
  final int position;
  final int totalParticipants;
  final bool isPersonalBest;
  final bool isSeasonBest;

  const RaceResult({
    required this.id,
    required this.competitionId,
    required this.athleteId,
    required this.eventName,
    required this.time,
    required this.position,
    required this.totalParticipants,
    this.isPersonalBest = false,
    this.isSeasonBest = false,
  });

  @override
  List<Object?> get props => [
        id,
        competitionId,
        athleteId,
        eventName,
        time,
        position,
        totalParticipants,
        isPersonalBest,
        isSeasonBest,
      ];
}
