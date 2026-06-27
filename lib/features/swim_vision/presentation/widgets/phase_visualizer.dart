import 'package:flutter/material.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';

class PhaseVisualizer extends StatelessWidget {
  final Map<String, double> phaseDuration;
  final double strokeRate;
  final double? coordinationIndex;

  const PhaseVisualizer({
    super.key,
    required this.phaseDuration,
    required this.strokeRate,
    this.coordinationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final phases = _parsePhases();
    if (phases.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع مراحل الضربة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: phases.map((p) => Expanded(
                  flex: (p.percentage * 100).round(),
                  child: Container(
                    color: p.color,
                    alignment: Alignment.center,
                    child: p.percentage > 0.12
                        ? Text(
                            p.label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: phases.map((p) => Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.label} ${p.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )).toList(),
          ),
          if (coordinationIndex != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sync_alt_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  _coordDescription(coordinationIndex!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'زمن الدورة الكاملة: ${_cycleTime()} ث',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _coordDescription(double idx) {
    if (idx > 5) return 'تنسيق تعاقبي (Opposition) — مثالي للسرعة القصوى';
    if (idx < -5) return 'تنسيق انتظاري (Catch-up) — مناسب لسباقات المسافات الطويلة';
    return 'تنسيق تراكبي (Superposition) — توازن بين السرعة والتحمل';
  }

  double _cycleTime() {
    if (strokeRate <= 0) return 0;
    return 60.0 / strokeRate;
  }

  List<_PhaseData> _parsePhases() {
    final map = <String, double>{};
    double total = 0;
    for (final entry in phaseDuration.entries) {
      final v = entry.value.clamp(0.0, 100.0);
      map[entry.key] = v;
      total += v;
    }
    if (total <= 0) return [];

    return [
      _PhaseData('Catch', map['catch_'] ?? map['catch'] ?? 25, AppColors.primary),
      _PhaseData('Pull', map['pull'] ?? 30, AppColors.accent),
      _PhaseData('Push', map['push'] ?? 20, AppColors.success),
      _PhaseData('Recovery', map['recovery'] ?? 25, const Color(0xFFFF8A65)),
    ];
  }
}

class _PhaseData {
  final String label;
  final double percentage;
  final Color color;
  _PhaseData(this.label, this.percentage, this.color);
}
