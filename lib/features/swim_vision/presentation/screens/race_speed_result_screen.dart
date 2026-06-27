import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/services/universal_speed_dynamics_module.dart';

class RaceSpeedResultScreen extends StatefulWidget {
  final double totalDistance;
  final List<double> cumulativeSplits;

  const RaceSpeedResultScreen({
    super.key,
    required this.totalDistance,
    required this.cumulativeSplits,
  });

  @override
  State<RaceSpeedResultScreen> createState() => _RaceSpeedResultScreenState();
}

class _RaceSpeedResultScreenState extends State<RaceSpeedResultScreen> {
  late UniversalSpeedAnalysisResult _result;

  @override
  void initState() {
    super.initState();
    final module = UniversalSpeedDynamicsModule();
    _result = module.analyzeRace(
      totalDistance: widget.totalDistance,
      cumulativeSplits: widget.cumulativeSplits,
    );
  }

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'stable_pacer':
        return Colors.green;
      case 'positive_split':
        return Colors.blue;
      case 'negative_split_fatigue':
        return Colors.orange;
      case 'sprint_drop':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getClassificationIcon(String classification) {
    switch (classification) {
      case 'stable_pacer':
        return Icons.trending_flat;
      case 'positive_split':
        return Icons.trending_up;
      case 'negative_split_fatigue':
        return Icons.trending_down;
      case 'sprint_drop':
        return Icons.flash_off;
      default:
        return Icons.help_outline;
    }
  }

  String _getClassificationTitle(String classification) {
    switch (classification) {
      case 'stable_pacer':
        return 'تنظيم سرعة مستقر';
      case 'positive_split':
        return 'تقسيم إيجابي (زيادة سرعة)';
      case 'negative_split_fatigue':
        return 'تدهور وتعب مبكر';
      case 'sprint_drop':
        return 'انطلاقة انفجارية وهبوط حاد';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة هبوط السرعة'),
      ),
      body: _result.classification == 'insufficient_data'
          ? const Center(child: Text('البيانات غير كافية للتحليل'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildMetricsRow(),
                const SizedBox(height: 24),
                const Text(
                  'منحنى السرعة التفاعلي (متر/ثانية)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSpeedChart(),
                const SizedBox(height: 24),
                const Text(
                  'التوصيات البيوميكانيكية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._result.insights.map((insight) => _buildInsightItem(insight)),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    final color = _getClassificationColor(_result.classification);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(_getClassificationIcon(_result.classification), color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getClassificationTitle(_result.classification),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'تصنيف نمط تقسيم الجهد خلال السباق',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetricBox('أقصى سرعة', '${_result.metrics.maxSpeed} م/ث'),
        const SizedBox(width: 8),
        _buildMetricBox('نسبة الهبوط', '${_result.metrics.totalSpeedDropPercent}%', isRed: _result.metrics.totalSpeedDropPercent > 15),
        const SizedBox(width: 8),
        _buildMetricBox('مؤشر التعب', '${_result.metrics.fatigueIndex}'),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, {bool isRed = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRed ? Colors.red : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedChart() {
    final segments = _result.segments;
    if (segments.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    for (int i = 0; i < segments.length; i++) {
      spots.add(FlSpot(i.toDouble(), segments[i].speed));
    }

    double minY = segments.map((e) => e.speed).reduce((a, b) => a < b ? a : b) - 0.2;
    double maxY = segments.map((e) => e.speed).reduce((a, b) => a > b ? a : b) + 0.2;
    if (minY < 0) minY = 0;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < segments.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          segments[index].range,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (segments.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
