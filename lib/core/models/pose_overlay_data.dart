import 'dart:math';
import 'package:equatable/equatable.dart';

class PoseOverlayData extends Equatable {
  final double timestampSeconds;
  final Map<String, Point<double>> landmarks;

  const PoseOverlayData({
    required this.timestampSeconds,
    required this.landmarks,
  });

  @override
  List<Object?> get props => [timestampSeconds, landmarks];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> serializedLandmarks = {};
    landmarks.forEach((key, point) {
      serializedLandmarks[key] = {'x': point.x, 'y': point.y};
    });
    return {
      'timestampSeconds': timestampSeconds,
      'landmarks': serializedLandmarks,
    };
  }

  factory PoseOverlayData.fromJson(Map<String, dynamic> json) {
    final Map<String, Point<double>> parsedLandmarks = {};
    final rawLandmarks = json['landmarks'] as Map<String, dynamic>?;
    if (rawLandmarks != null) {
      rawLandmarks.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedLandmarks[key] = Point<double>(
            (value['x'] as num).toDouble(),
            (value['y'] as num).toDouble(),
          );
        }
      });
    }
    return PoseOverlayData(
      timestampSeconds: (json['timestampSeconds'] as num).toDouble(),
      landmarks: parsedLandmarks,
    );
  }
}
