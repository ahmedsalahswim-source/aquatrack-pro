import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/helpers.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

class StressGauge extends StatelessWidget {
  final int score;

  const StressGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final color = AppColors.stressColor(score);
    final label = StressCalculator.getStressLabel(score);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(score: score, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('stress_score'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _stressBar(t.translate('sleep'), 30, score),
                _stressBar(t.translate('heart_rate'), 25, score),
                _stressBar('RPE', 30, score),
                _stressBar('Wellness', 15, score),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stressBar(String label, double weight, int score) {
    final contribution = (weight / 100) * score;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: contribution / 100,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.stressColor(contribution.round())),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${contribution.round()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color color;

  const _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Background arc
    paint.color = AppColors.border;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 1.5,
      pi * 2,
      false,
      paint,
    );

    // Score arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 1.5,
      pi * 2 * (score / 100),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.score != score;
}
