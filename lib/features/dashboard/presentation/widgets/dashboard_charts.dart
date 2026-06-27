import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

String _shortDate(String isoDate) => isoDate.length >= 10 ? isoDate.substring(5) : isoDate;



Widget _emptyChart(BuildContext context) {
  final t = context.read<AppLocalizations>();
  return GlassContainer(
    height: 180,
    child: Center(child: Text(t.translate('no_data_enough'), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textMuted))),
  );
}

class StressChart extends StatelessWidget {
  final List<DailyLogEntity> logs;
  const StressChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final data = logs.where((l) => l.stressScore != null).toList();
    if (data.isEmpty) return _emptyChart(context);

    return RepaintBoundary(
      child: GlassContainer(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(_shortDate(data[idx].date), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              })),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].stressScore!.toDouble())),
                isCurved: true,
                color: AppColors.accent,
                barWidth: 2.5,
                dotData: FlDotData(show: true, getDotPainter: (spot, _, _, _) => FlDotCirclePainter(radius: 3, color: AppColors.accent, strokeWidth: 0)),
                belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha:  0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SleepChart extends StatelessWidget {
  final List<DailyLogEntity> logs;
  final AthleteEntity athlete;
  const SleepChart({super.key, required this.logs, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final data = logs.where((l) => l.sleepHours != null).toList();
    if (data.isEmpty) return _emptyChart(context);

    final recommended = DateHelpers.sleepRecommendationByAge(athlete.age).$1.toDouble();

    return RepaintBoundary(
      child: GlassContainer(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}س', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(_shortDate(data[idx].date), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              })),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: recommended + 4,
            barGroups: List.generate(data.length, (i) {
              final hours = data[i].sleepHours!;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: hours,
                  color: hours >= recommended ? AppColors.success : AppColors.danger,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

class HRChart extends StatelessWidget {
  final List<DailyLogEntity> logs;
  const HRChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final data = logs.where((l) => l.restingHR != null).toList();
    if (data.isEmpty) return _emptyChart(context);

    return RepaintBoundary(
      child: GlassContainer(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(_shortDate(data[idx].date), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              })),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].restingHR!.toDouble())),
                isCurved: true,
                color: AppColors.info,
                barWidth: 2.5,
                dotData: FlDotData(show: true, getDotPainter: (spot, _, _, _) => FlDotCirclePainter(radius: 3, color: AppColors.info, strokeWidth: 0)),
                belowBarData: BarAreaData(show: true, color: AppColors.info.withValues(alpha:  0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainingLoadChart extends StatelessWidget {
  final List<DailyLogEntity> logs;
  const TrainingLoadChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final data = logs.where((l) => l.training?.trainingLoad != null).toList();
    if (data.isEmpty) return _emptyChart(context);

    return RepaintBoundary(
      child: GlassContainer(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(_shortDate(data[idx].date), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              })),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (i) {
              final load = data[i].training!.trainingLoad!.toDouble();
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: load,
                  color: load > 600 ? AppColors.danger : load > 300 ? AppColors.warning : AppColors.success,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

class AcwrChart extends StatelessWidget {
  final List<DailyLogEntity> logs;
  const AcwrChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final data = logs.where((l) => l.training?.trainingLoad != null).toList();
    if (data.length < 14) return _emptyChart(context);

    final loads = data.map((l) => l.training!.trainingLoad!.toDouble()).toList();
    const int acuteWindow = 7;
    const int chronicWindow = 28;
    final acwrValues = <double>[];
    for (int i = acuteWindow - 1; i < loads.length; i++) {
      final startChronic = (i - chronicWindow + 1).clamp(0, i);
      final acuteSlice = loads.sublist(i - acuteWindow + 1, i + 1);
      final chronicSlice = loads.sublist(startChronic, i + 1);
      final acute = acuteSlice.fold<double>(0, (sum, load) => sum + load) / acuteSlice.length;
      final chronic = chronicSlice.fold<double>(0, (sum, load) => sum + load) / chronicSlice.length;
      acwrValues.add(chronic > 0 ? (acute / chronic).clamp(0, 3) : 0);
    }

    if (acwrValues.isEmpty) return _emptyChart(context);

    return RepaintBoundary(
      child: GlassContainer(
        height: 180,
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.5),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final idx = v.toInt() + 6;
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(_shortDate(data[idx].date), style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              })),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 3,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(acwrValues.length, (i) => FlSpot(i.toDouble(), acwrValues[i])),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha:  0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NutritionSummary extends StatelessWidget {
  final List<DailyLogEntity> logs;
  const NutritionSummary({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final withNutrition = logs.where((l) => l.nutrition != null).toList();
    if (withNutrition.isEmpty) return _emptyChart(context);

    final avgMeals = withNutrition.fold<double>(0, (s, l) => s + l.nutrition!.mealsCount) / withNutrition.length;
    final avgHydration = withNutrition.fold<double>(0, (s, l) => s + l.nutrition!.hydrationLiters) / withNutrition.length;
    final proteinDays = withNutrition.where((l) => l.nutrition!.proteinSufficient).length;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _NutRow(t.translate('meals'), '${avgMeals.toStringAsFixed(1)}/4', avgMeals / 4),
          const SizedBox(height: 12),
          _NutRow(t.translate('hydration'), '${avgHydration.toStringAsFixed(1)}L', avgHydration / 3),
          const SizedBox(height: 12),
          _NutRow(t.translate('protein'), '$proteinDays/${withNutrition.length}', proteinDays / withNutrition.length),
        ],
      ),
    );
  }
}

class _NutRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  const _NutRow(this.label, this.value, this.fraction);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              backgroundColor: AppColors.border,
              color: fraction >= 0.7 ? AppColors.success : AppColors.warning,
              minHeight: 10,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(value, textAlign: TextAlign.left, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
