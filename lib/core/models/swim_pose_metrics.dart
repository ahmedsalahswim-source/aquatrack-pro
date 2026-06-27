import 'package:aquatrack_pro/core/models/pose_overlay_data.dart';

class SwimPoseMetrics {
  final double bodyAngle;
  final double bodyRollAngle;
  final double rollSymmetry;
  final double headLift;
  final double strokeRate;
  final double strokeLength;
  final double strokeIndex;
  final double coordinationIndex;
  final double handVelocity;
  final double propulsiveDrag;
  final double strouhalNumber;
  final double kickFrequency;
  final double kickAmplitude;
  final double symmetryScore;
  final double propulsiveEfficiency;
  final double normalizedStrokeLength;
  final double armSweepAngle;
  final Map<String, double> phaseDuration;
  final List<SwimStrokePhase> detectedPhases;
  final int frameCount;
  final List<PoseOverlayData> poseData;

  const SwimPoseMetrics({
    required this.bodyAngle,
    required this.bodyRollAngle,
    required this.rollSymmetry,
    required this.headLift,
    required this.strokeRate,
    required this.strokeLength,
    required this.strokeIndex,
    required this.coordinationIndex,
    required this.handVelocity,
    required this.propulsiveDrag,
    required this.strouhalNumber,
    required this.kickFrequency,
    required this.kickAmplitude,
    required this.symmetryScore,
    this.propulsiveEfficiency = 0.0,
    this.normalizedStrokeLength = 0.0,
    this.armSweepAngle = 0.0,
    required this.phaseDuration,
    required this.detectedPhases,
    required this.frameCount,
    this.poseData = const [],
  });
}

enum SwimStrokePhase { catch_, pull, push, recovery }
