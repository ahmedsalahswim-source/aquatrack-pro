import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/swim_vision/domain/entities/swim_analysis_result.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/widgets/analysis_result_card.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/widgets/phase_visualizer.dart';
import 'package:aquatrack_pro/features/swim_vision/data/repositories/swim_vision_repository.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/swim_vision_screen.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/widgets/pose_video_player.dart';

class AnalysisResultScreen extends StatelessWidget {
  final SwimAnalysisResult result;
  final String userId;
  final String athleteId;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.userId,
    required this.athleteId,
  });

  Color _scoreColor(String score) {
    switch (score) {
      case 'ممتاز':
        return AppColors.success;
      case 'جيد':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  String _dragLabel(double drag) {
    if (drag < 80) return 'منخفضة';
    if (drag < 140) return 'متوسطة';
    return 'عالية';
  }

  Color _dragColor(double drag) {
    if (drag < 80) return AppColors.success;
    if (drag < 140) return AppColors.warning;
    return AppColors.danger;
  }

  String _effLabel(double eff) {
    if (eff >= 80) return 'ممتاز';
    if (eff >= 60) return 'جيد';
    return 'يحتاج تحسين';
  }

  Color _effColor(double eff) {
    if (eff >= 80) return AppColors.success;
    if (eff >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  String _fatigueLabel(double f) {
    if (f < 15) return 'طاقة جيدة';
    if (f < 30) return 'إجهاد متوسط';
    return 'إجهاد مرتفع';
  }

  Color _fatigueColor(double f) {
    if (f < 15) return AppColors.success;
    if (f < 30) return AppColors.warning;
    return AppColors.danger;
  }

  String _srLabel(double sr) {
    if (sr >= 35 && sr <= 50) return 'مثالي';
    if (sr >= 25 && sr <= 55) return 'جيد';
    return 'معدل غير طبيعي';
  }

  Color _srColor(double sr) {
    if (sr >= 35 && sr <= 50) return AppColors.success;
    if (sr >= 25 && sr <= 55) return AppColors.warning;
    return AppColors.danger;
  }

  String _slLabel(double sl) {
    if (sl >= 2.0) return 'ممتاز';
    if (sl >= 1.5) return 'جيد';
    return 'قصير';
  }

  Color _slColor(double sl) {
    if (sl >= 2.0) return AppColors.success;
    if (sl >= 1.5) return AppColors.warning;
    return AppColors.danger;
  }

  String _siLabel(double si) {
    if (si >= 3.5) return 'نخبة';
    if (si >= 2.5) return 'جيد';
    return 'يحتاج تحسين';
  }

  Color _siColor(double si) {
    if (si >= 3.5) return AppColors.success;
    if (si >= 2.5) return AppColors.warning;
    return AppColors.danger;
  }

  String _rollLabel(double roll) {
    if (roll >= 35 && roll <= 55) return 'مثالي';
    if (roll >= 25 && roll <= 65) return 'جيد';
    return 'مفرط';
  }

  Color _rollColor(double roll) {
    if (roll >= 35 && roll <= 55) return AppColors.success;
    if (roll >= 25 && roll <= 65) return AppColors.warning;
    return AppColors.danger;
  }

  String _kickLabel(double kf) {
    if (kf >= 40 && kf <= 60) return 'مثالي';
    if (kf >= 30 && kf <= 70) return 'جيد';
    return 'غير طبيعي';
  }

  Color _kickColor(double kf) {
    if (kf >= 40 && kf <= 60) return AppColors.success;
    if (kf >= 30 && kf <= 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج التحليل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة',
            onPressed: () => _shareResult(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.videoPath != null && result.videoPath!.isNotEmpty) ...[
              const Text(
                'تحليل الحركة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              PoseVideoPlayer(
                videoPath: result.videoPath!,
                poseDataList: result.poseDataList,
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'قياسات الأداء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Metric cards
            AnalysisResultCard(
              title: 'زاوية الجسم',
              value: '${result.bodyAngle.toStringAsFixed(1)}°',
              scoreLabel: result.bodyAngleScore,
              color: _scoreColor(result.bodyAngleScore),
              icon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 8),

            AnalysisResultCard(
              title: 'مقاومة الماء',
              value: '${result.dragRating.toStringAsFixed(0)} N',
              scoreLabel: _dragLabel(result.dragRating),
              color: _dragColor(result.dragRating),
              icon: Icons.air_rounded,
            ),
            const SizedBox(height: 8),

            AnalysisResultCard(
              title: 'كفاءة الضربة',
              value: '${result.strokeEfficiency.toStringAsFixed(1)}%',
              scoreLabel: _effLabel(result.strokeEfficiency),
              color: _effColor(result.strokeEfficiency),
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 8),

            AnalysisResultCard(
              title: 'مؤشر الإجهاد',
              value: '${result.fatigueIndex.toStringAsFixed(1)}%',
              scoreLabel: _fatigueLabel(result.fatigueIndex),
              color: _fatigueColor(result.fatigueIndex),
              icon: Icons.battery_alert_rounded,
            ),
            const SizedBox(height: 16),

            // Stroke Mechanics section
            if (result.strokeRate > 0 || result.strokeLength > 0) ...[
              const Text(
                'ميكانيكية الضربة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (result.strokeRate > 0)
                AnalysisResultCard(
                  title: 'تردد الضربات',
                  value: '${result.strokeRate.toStringAsFixed(1)} ض/د',
                  scoreLabel: _srLabel(result.strokeRate),
                  color: _srColor(result.strokeRate),
                  icon: Icons.timer_rounded,
                ),
              const SizedBox(height: 8),
              if (result.strokeLength > 0)
                AnalysisResultCard(
                  title: 'طول الشدة',
                  value: '${result.strokeLength.toStringAsFixed(2)} م',
                  scoreLabel: _slLabel(result.strokeLength),
                  color: _slColor(result.strokeLength),
                  icon: Icons.straighten_rounded,
                ),
              const SizedBox(height: 8),
              if (result.strokeIndex > 0)
                AnalysisResultCard(
                  title: 'مؤشر الشد (SI)',
                  value: result.strokeIndex.toStringAsFixed(2),
                  scoreLabel: _siLabel(result.strokeIndex),
                  color: _siColor(result.strokeIndex),
                  icon: Icons.speed_rounded,
                ),
              const SizedBox(height: 8),
              if (result.coordinationIndex != 0)
                AnalysisResultCard(
                  title: 'تنسيق الذراعين (IdC)',
                  value: result.coordinationIndex.toStringAsFixed(1),
                  scoreLabel: result.coordinationIndex > 0
                      ? 'تعاقبي'
                      : result.coordinationIndex < 0
                          ? 'انتظاري'
                          : 'تراكبي',
                  color: result.coordinationIndex > 0
                      ? AppColors.success
                      : result.coordinationIndex < -10
                          ? AppColors.danger
                          : AppColors.warning,
                  icon: Icons.sync_alt_rounded,
                ),
              const SizedBox(height: 8),
              if (result.bodyRollAngle > 0)
                AnalysisResultCard(
                  title: 'دوران الجسم',
                  value: '${result.bodyRollAngle.toStringAsFixed(1)}°',
                  scoreLabel: _rollLabel(result.bodyRollAngle),
                  color: _rollColor(result.bodyRollAngle),
                  icon: Icons.rotate_right_rounded,
                ),
              const SizedBox(height: 8),
              if (result.kickFrequency > 0)
                AnalysisResultCard(
                  title: 'تردد الركلة',
                  value: '${result.kickFrequency.toStringAsFixed(1)} ر/د',
                  scoreLabel: _kickLabel(result.kickFrequency),
                  color: _kickColor(result.kickFrequency),
                  icon: Icons.accessibility_new_rounded,
                ),
              if (result.headLift > 0) ...[
                const SizedBox(height: 8),
                AnalysisResultCard(
                  title: 'ارتفاع الرأس',
                  value: result.headLift.toStringAsFixed(1),
                  scoreLabel: result.headLift < 15 ? 'جيد' : 'مرتفع',
                  color: result.headLift < 15
                      ? AppColors.success
                      : AppColors.danger,
                  icon: Icons.height_rounded,
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Phase Visualizer
            if (result.phaseDuration.isNotEmpty && result.strokeRate > 0) ...[
              PhaseVisualizer(
                phaseDuration: result.phaseDuration,
                strokeRate: result.strokeRate,
                coordinationIndex: result.coordinationIndex,
              ),
              const SizedBox(height: 16),
            ],

            // AI Coaching Report
            const Text(
              'تقرير التدريب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: SelectableText(
                result.aiCoachingReport.isNotEmpty
                    ? result.aiCoachingReport
                    : 'عذراً، لم يتمكن المساعد من إنشاء تقرير تدريبي.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

            // Scientific References
            if (result.scientificReferences.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'المراجع العلمية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...result.scientificReferences.map(
                (ref) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📚 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          ref,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Warnings
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'ملاحظات تحسينية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 8),
              ...result.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saveResult(context),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ التقرير'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _newAnalysis(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحليل جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveResult(BuildContext context) async {
    final repo = SwimVisionRepository();
    await repo.saveResult(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ التقرير بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    final extras = StringBuffer();
    if (result.strokeRate > 0) extras.writeln('تردد الضربات: ${result.strokeRate.toStringAsFixed(1)} ض/د');
    if (result.strokeLength > 0) extras.writeln('طول الشدة: ${result.strokeLength.toStringAsFixed(2)} م');
    if (result.strokeIndex > 0) extras.writeln('مؤشر الشد (SI): ${result.strokeIndex.toStringAsFixed(2)}');
    if (result.coordinationIndex != 0) extras.writeln('تنسيق الذراعين (IdC): ${result.coordinationIndex.toStringAsFixed(1)}');
    if (result.bodyRollAngle > 0) extras.writeln('دوران الجسم: ${result.bodyRollAngle.toStringAsFixed(1)}°');
    if (result.kickFrequency > 0) extras.writeln('تردد الركلة: ${result.kickFrequency.toStringAsFixed(1)} ر/د');
    if (result.headLift > 0) extras.writeln('ارتفاع الرأس: ${result.headLift.toStringAsFixed(1)}');
    final extrasStr = extras.toString();

    final text = '''
نتائج تحليل السباحة
═══════════════════
زاوية الجسم: ${result.bodyAngle.toStringAsFixed(1)}° — ${result.bodyAngleScore}
المقاومة: ${result.dragRating.toStringAsFixed(0)} N
كفاءة الضربة: ${result.strokeEfficiency.toStringAsFixed(1)}%
مؤشر الإجهاد: ${result.fatigueIndex.toStringAsFixed(1)}%
مؤشر الاستقرار: ${result.stabilityIndex.toStringAsFixed(2)}
درجة التماثل: ${result.symmetryScore.toStringAsFixed(1)}%
$extrasStr
${result.aiCoachingReport}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 تم نسخ التقرير — يمكنك لصقه في أي تطبيق'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _newAnalysis(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SwimVisionScreen(
          userId: userId,
          athleteId: athleteId,
        ),
      ),
      (route) => route.isFirst,
    );
  }
}
