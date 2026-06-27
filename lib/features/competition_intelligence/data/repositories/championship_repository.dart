import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/race_result.dart';

class LocalRecord {
  final String event;
  final String gender;
  final String swimmerName;
  final double timeSeconds;
  final String championshipName;

  LocalRecord({
    required this.event,
    required this.gender,
    required this.swimmerName,
    required this.timeSeconds,
    required this.championshipName,
  });
}

class ChampionshipRepository {
  List<Map<String, dynamic>> _results = [];
  bool _isLoaded = false;

  Future<void> loadResults() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/data/championships_db.json');
      final data = await json.decode(response);
      _results = List<Map<String, dynamic>>.from(data['results']);
      _isLoaded = true;
    } catch (e) {
      // print("Failed to load championship DB: $e");
    }
  }

  /// Gets all results for a specific swimmer by name
  List<RaceResult> getSwimmerHistory(String swimmerName) {
    if (!_isLoaded) return [];
    
    List<RaceResult> history = [];
    final matchingRows = _results.where((r) => r['swimmer'].toString().contains(swimmerName));
    
    for (var row in matchingRows) {
      history.add(RaceResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
        competitionId: 'upper_egypt_2025',
        athleteId: swimmerName, // Using name as ID for demo
        eventName: row['event'],
        time: Duration(milliseconds: (row['time_seconds'] * 1000).toInt()),
        position: row['position'],
        totalParticipants: 0, // Unknown from basic PDF
        isPersonalBest: true, // Assuming championship result is PB
      ));
    }
    
    return history;
  }

  /// Gets the Upper Egypt Championship Record for an event
  LocalRecord? getLocalRecord(String eventName, String gender) {
    if (!_isLoaded) return null;
    
    final eventRows = _results.where((r) => 
      r['event'].toString().toLowerCase() == eventName.toLowerCase() &&
      r['gender'].toString().toLowerCase() == gender.toLowerCase()
    ).toList();
    
    if (eventRows.isEmpty) return null;
    
    // Sort by time to find the fastest
    eventRows.sort((a, b) => (a['time_seconds'] as num).compareTo(b['time_seconds'] as num));
    final fastest = eventRows.first;
    
    return LocalRecord(
      event: fastest['event'],
      gender: fastest['gender'],
      swimmerName: fastest['swimmer'],
      timeSeconds: (fastest['time_seconds'] as num).toDouble(),
      championshipName: 'Upper Egypt 2025',
    );
  }
}
