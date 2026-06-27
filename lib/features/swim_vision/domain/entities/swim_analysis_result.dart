import 'package:aquatrack_pro/core/models/pose_overlay_data.dart';

class SwimAnalysisResult {
  final double bodyAngle;
  final String bodyAngleScore;
  final double dragRating;
  final String dragMessage;
  final double strokeEfficiency;
  final double fatigueIndex;
  final double stabilityIndex;
  final double symmetryScore;
  final double strokeRate;
  final double strokeLength;
  final double strokeIndex;
  final double coordinationIndex;
  final double bodyRollAngle;
  final double rollSymmetry;
  final double headLift;
  final double handVelocity;
  final double strouhalNumber;
  final double kickFrequency;
  final double kickAmplitude;
  final Map<String, double> phaseDuration;
  final String aiCoachingReport;
  final List<String> scientificReferences;
  final List<String> warnings;
  final int frameCountAnalyzed;
  final double videoDurationSeconds;
  final String? videoPath;
  final List<PoseOverlayData> poseDataList;
  final DateTime analyzedAt;

  SwimAnalysisResult({
    required this.bodyAngle,
    required this.bodyAngleScore,
    required this.dragRating,
    required this.dragMessage,
    required this.strokeEfficiency,
    required this.fatigueIndex,
    required this.stabilityIndex,
    required this.symmetryScore,
    this.strokeRate = 0,
    this.strokeLength = 0,
    this.strokeIndex = 0,
    this.coordinationIndex = 0,
    this.bodyRollAngle = 0,
    this.rollSymmetry = 0,
    this.headLift = 0,
    this.handVelocity = 0,
    this.strouhalNumber = 0,
    this.kickFrequency = 0,
    this.kickAmplitude = 0,
    this.phaseDuration = const {},
    this.aiCoachingReport = '',
    this.scientificReferences = const [],
    this.warnings = const [],
    this.frameCountAnalyzed = 0,
    this.videoDurationSeconds = 0,
    this.videoPath,
    this.poseDataList = const [],
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'bodyAngle': bodyAngle,
        'bodyAngleScore': bodyAngleScore,
        'dragRating': dragRating,
        'dragMessage': dragMessage,
        'strokeEfficiency': strokeEfficiency,
        'fatigueIndex': fatigueIndex,
        'stabilityIndex': stabilityIndex,
        'symmetryScore': symmetryScore,
        'strokeRate': strokeRate,
        'strokeLength': strokeLength,
        'strokeIndex': strokeIndex,
        'coordinationIndex': coordinationIndex,
        'bodyRollAngle': bodyRollAngle,
        'rollSymmetry': rollSymmetry,
        'headLift': headLift,
        'handVelocity': handVelocity,
        'strouhalNumber': strouhalNumber,
        'kickFrequency': kickFrequency,
        'kickAmplitude': kickAmplitude,
        'phaseDuration': phaseDuration,
        'aiCoachingReport': aiCoachingReport,
        'scientificReferences': scientificReferences,
        'warnings': warnings,
        'frameCountAnalyzed': frameCountAnalyzed,
        'videoDurationSeconds': videoDurationSeconds,
        'videoPath': videoPath,
        'poseDataList': poseDataList.map((p) => p.toJson()).toList(),
        'analyzedAt': analyzedAt.toIso8601String(),
      };

  factory SwimAnalysisResult.fromJson(Map<String, dynamic> json) =>
      SwimAnalysisResult(
        bodyAngle: (json['bodyAngle'] as num?)?.toDouble() ?? 0.0,
        bodyAngleScore: json['bodyAngleScore'] as String? ?? '',
        dragRating: (json['dragRating'] as num?)?.toDouble() ?? 0.0,
        dragMessage: json['dragMessage'] as String? ?? '',
        strokeEfficiency: (json['strokeEfficiency'] as num?)?.toDouble() ?? 0.0,
        fatigueIndex: (json['fatigueIndex'] as num?)?.toDouble() ?? 0.0,
        stabilityIndex: (json['stabilityIndex'] as num?)?.toDouble() ?? 0.0,
        symmetryScore: (json['symmetryScore'] as num?)?.toDouble() ?? 0.0,
        strokeRate: (json['strokeRate'] as num?)?.toDouble() ?? 0.0,
        strokeLength: (json['strokeLength'] as num?)?.toDouble() ?? 0.0,
        strokeIndex: (json['strokeIndex'] as num?)?.toDouble() ?? 0.0,
        coordinationIndex:
            (json['coordinationIndex'] as num?)?.toDouble() ?? 0.0,
        bodyRollAngle: (json['bodyRollAngle'] as num?)?.toDouble() ?? 0.0,
        rollSymmetry: (json['rollSymmetry'] as num?)?.toDouble() ?? 0.0,
        headLift: (json['headLift'] as num?)?.toDouble() ?? 0.0,
        handVelocity: (json['handVelocity'] as num?)?.toDouble() ?? 0.0,
        strouhalNumber: (json['strouhalNumber'] as num?)?.toDouble() ?? 0.0,
        kickFrequency: (json['kickFrequency'] as num?)?.toDouble() ?? 0.0,
        kickAmplitude: (json['kickAmplitude'] as num?)?.toDouble() ?? 0.0,
        phaseDuration: (json['phaseDuration'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
        aiCoachingReport: json['aiCoachingReport'] as String? ?? '',
        scientificReferences:
            (json['scientificReferences'] as List<dynamic>?)?.cast<String>() ??
                [],
        warnings: (json['warnings'] as List<dynamic>?)?.cast<String>() ?? [],
        frameCountAnalyzed: json['frameCountAnalyzed'] as int? ?? 0,
        videoDurationSeconds:
            (json['videoDurationSeconds'] as num?)?.toDouble() ?? 0.0,
        videoPath: json['videoPath'] as String?,
        poseDataList: (json['poseDataList'] as List<dynamic>?)
                ?.map((e) => PoseOverlayData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        analyzedAt: json['analyzedAt'] != null
            ? DateTime.parse(json['analyzedAt'] as String)
            : null,
      );
}
