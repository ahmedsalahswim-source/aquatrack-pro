import 'package:flutter/material.dart';

class ReadinessBadge extends StatelessWidget {
  final double readinessScore; // 0 to 100

  const ReadinessBadge({super.key, required this.readinessScore});

  Color get _color {
    if (readinessScore >= 90) return Colors.green;
    if (readinessScore >= 75) return Colors.lightGreen;
    if (readinessScore >= 60) return Colors.yellow.shade700;
    if (readinessScore >= 40) return Colors.orange;
    return Colors.red;
  }

  String get _statusText {
    if (readinessScore >= 90) return 'جاهز للحمل العالي';
    if (readinessScore >= 75) return 'تدريب طبيعي';
    if (readinessScore >= 60) return 'يحتاج مراقبة';
    if (readinessScore >= 40) return 'خفض الحمل';
    return 'خطر مرتفع';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        border: Border.all(color: _color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: _color, size: 16),
          const SizedBox(width: 8),
          Text(
            'Readiness ${readinessScore.toInt()}',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _statusText,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
