import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

enum MetricType { sleep, heartRate, training, nutrition, stress }

class MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<DailyLogEntity>? trendData;
  final double? trendValue;
  final MetricType? metricType;

  const MiniMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.trendData,
    this.trendValue,
    this.metricType,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:  0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (trendValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendValue! >= 0
                        ? AppColors.success.withValues(alpha:  0.1)
                        : AppColors.danger.withValues(alpha:  0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${trendValue! >= 0 ? '+' : ''}${trendValue!.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trendValue! >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          if (trendData != null && trendData!.length >= 7) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        trendData!.length,
                        (i) => FlSpot(i.toDouble(), _getMetricValue(trendData![i])),
                      ),
                      isCurved: true,
                      color: color,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha:  0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getMetricValue(DailyLogEntity log) {
    if (metricType != null) {
      switch (metricType!) {
        case MetricType.sleep:
          return log.sleepHours ?? 0;
        case MetricType.heartRate:
          return log.restingHR?.toDouble() ?? 0;
        case MetricType.training:
          return (log.training?.durationMinutes ?? 0).toDouble();
        case MetricType.nutrition:
          return log.nutrition?.mealsPercentage.toDouble() ?? 0;
        case MetricType.stress:
          return log.stressScore?.toDouble() ?? 0;
      }
    }
    return 0;
  }
}
