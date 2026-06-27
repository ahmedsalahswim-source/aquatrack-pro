import 'package:flutter/material.dart';
import 'package:aquatrack_pro/core/models/pose_overlay_data.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class PoseOverlayPainter extends CustomPainter {
  final PoseOverlayData? poseData;
  final Size originalVideoSize;

  PoseOverlayPainter({
    required this.poseData,
    required this.originalVideoSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poseData == null || originalVideoSize.isEmpty || size.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final paintPointBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final landmarks = poseData!.landmarks;

    // Helper to get scaled point
    Offset? getScaledPoint(String key) {
      final point = landmarks[key];
      if (point == null) return null;
      
      final scaleX = size.width / originalVideoSize.width;
      final scaleY = size.height / originalVideoSize.height;
      
      return Offset(point.x * scaleX, point.y * scaleY);
    }

    // Helper to draw a line between two landmarks
    void drawLine(String startKey, String endKey) {
      final start = getScaledPoint(startKey);
      final end = getScaledPoint(endKey);
      if (start != null && end != null) {
        canvas.drawLine(start, end, paintLine);
      }
    }

    // Draw the skeleton lines
    // Torso
    drawLine('leftShoulder', 'rightShoulder');
    drawLine('leftShoulder', 'leftHip');
    drawLine('rightShoulder', 'rightHip');
    drawLine('leftHip', 'rightHip');

    // Arms
    drawLine('leftShoulder', 'leftElbow');
    drawLine('leftElbow', 'leftWrist');
    drawLine('rightShoulder', 'rightElbow');
    drawLine('rightElbow', 'rightWrist');

    // Legs
    drawLine('leftHip', 'leftKnee');
    drawLine('leftKnee', 'leftAnkle');
    drawLine('rightHip', 'rightKnee');
    drawLine('rightKnee', 'rightAnkle');

    // Draw points on all landmarks
    for (var key in landmarks.keys) {
      final point = getScaledPoint(key);
      if (point != null) {
        canvas.drawCircle(point, 4, paintPoint);
        canvas.drawCircle(point, 4, paintPointBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.poseData != poseData ||
           oldDelegate.originalVideoSize != originalVideoSize;
  }
}
