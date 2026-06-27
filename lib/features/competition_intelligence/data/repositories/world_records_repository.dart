import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class WorldRecord {
  final String event;
  final String pool;
  final String gender;
  final double timeSeconds;
  final String athleteName;
  final String country;
  final int year;

  WorldRecord({
    required this.event,
    required this.pool,
    required this.gender,
    required this.timeSeconds,
    required this.athleteName,
    required this.country,
    required this.year,
  });

  factory WorldRecord.fromJson(Map<String, dynamic> json) {
    return WorldRecord(
      event: json['event'],
      pool: json['pool'],
      gender: json['gender'],
      timeSeconds: (json['time_seconds'] as num).toDouble(),
      athleteName: json['athlete_name'],
      country: json['country'],
      year: json['year'],
    );
  }
}

class WorldRecordsRepository {
  List<WorldRecord> _records = [];
  Map<String, double> _motivationalMultipliers = {};
  bool _isLoaded = false;

  Future<void> loadRecords() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/data/world_records.json');
      final data = await json.decode(response);
      
      _records = (data['records'] as List)
          .map((item) => WorldRecord.fromJson(item))
          .toList();
          
      _motivationalMultipliers = Map<String, double>.from(
        data['motivational_standards'].map((key, value) => MapEntry(key, (value as num).toDouble()))
      );
      
      _isLoaded = true;
    } catch (e) {
      debugPrint("Failed to load world records: $e");
    }
  }

  WorldRecord? getRecordForEvent(String eventName, String poolType, String gender) {
    try {
      return _records.firstWhere(
        (r) => r.event.toLowerCase() == eventName.toLowerCase() && 
               r.pool.toLowerCase() == poolType.toLowerCase() &&
               r.gender.toLowerCase() == gender.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  String evaluateTimeStandard(double timeSeconds, WorldRecord record) {
    final wrTime = record.timeSeconds;
    
    if (timeSeconds <= wrTime) return 'WORLD RECORD';
    if (timeSeconds <= wrTime * _motivationalMultipliers['AAAA_multiplier']!) return 'AAAA (Elite)';
    if (timeSeconds <= wrTime * _motivationalMultipliers['AAA_multiplier']!) return 'AAA (Expert)';
    if (timeSeconds <= wrTime * _motivationalMultipliers['AA_multiplier']!) return 'AA (Advanced)';
    if (timeSeconds <= wrTime * _motivationalMultipliers['A_multiplier']!) return 'A (Intermediate)';
    if (timeSeconds <= wrTime * _motivationalMultipliers['BB_multiplier']!) return 'BB (Novice)';
    
    return 'B (Beginner)';
  }
}
