import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/services/swim_physics_engine.dart';
import 'package:aquatrack_pro/core/services/ai_coaching_service.dart';
import 'package:aquatrack_pro/core/services/pose_analyzer_service.dart';
import 'package:aquatrack_pro/features/swim_vision/domain/entities/swim_analysis_result.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/analysis_result_screen.dart';

enum _ProcessingStep { compress, analyze, coaching, done }

class ProcessingScreen extends StatefulWidget {
  final File videoFile;
  final String userId;
  final String athleteId;

  const ProcessingScreen({
    super.key,
    required this.videoFile,
    required this.userId,
    required this.athleteId,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  _ProcessingStep _step = _ProcessingStep.compress;
  String _statusText = 'جاري ضغط الفيديو...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  @override
  void dispose() {
    VideoCompress.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    // Step 1: Compress
    setState(() {
      _step = _ProcessingStep.compress;
      _statusText = 'جاري ضغط الفيديو...';
    });
    try {
      await VideoCompress.compressVideo(
        widget.videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {}

    if (!mounted) return;

    // Step 2: Pose analysis
    setState(() {
      _step = _ProcessingStep.analyze;
      _statusText = 'الذكاء الاصطناعي يحلل تقنية السباح...';
      _progress = 0.3;
    });

    final poseAnalyzer = PoseAnalyzerService();
    await poseAnalyzer.initialize();
    final poseMetrics = await poseAnalyzer.analyzeVideo(widget.videoFile);

    if (!mounted) return;

    // Step 3: Physics engine with real metrics
    final engine = SwimPhysicsEngine();
    final physics = engine.analyze(poseMetrics: poseMetrics);

    if (!mounted) return;

    // Step 4: AI Coaching
    setState(() {
      _step = _ProcessingStep.coaching;
      _statusText = 'جاري إنشاء التقرير التدريبي...';
      _progress = 0.6;
    });

    late AiCoachingResult coaching;
    try {
      final coachingService = AiCoachingService();
      coaching = await coachingService.getCoachingReport(
        userId: widget.userId,
        athleteId: widget.athleteId,
        physics: physics,
      );
    } catch (_) {
      coaching = AiCoachingResult(
        report: 'عذراً، لم يتمكن المساعد من إنشاء تقرير تدريبي.',
      );
    }

    if (!mounted) return;

    // Build result
    final result = SwimAnalysisResult(
      bodyAngle: physics.bodyAngle,
      bodyAngleScore: physics.bodyAngleScore,
      dragRating: physics.dragRating,
      dragMessage: physics.dragMessage,
      strokeEfficiency: physics.strokeEfficiency,
      fatigueIndex: physics.fatigueIndex,
      stabilityIndex: physics.stabilityIndex,
      symmetryScore: physics.symmetryScore,
      strokeRate: physics.strokeRate,
      strokeLength: physics.strokeLength,
      strokeIndex: physics.strokeIndex,
      coordinationIndex: physics.coordinationIndex,
      bodyRollAngle: physics.bodyRollAngle,
      rollSymmetry: physics.rollSymmetry,
      headLift: physics.headLift,
      handVelocity: physics.handVelocity,
      strouhalNumber: physics.strouhalNumber,
      kickFrequency: physics.kickFrequency,
      kickAmplitude: physics.kickAmplitude,
      phaseDuration: physics.phaseDuration,
      aiCoachingReport: coaching.report,
      scientificReferences: physics.scientificReferences,
      warnings: physics.warnings,
      videoDurationSeconds: 15.0,
      frameCountAnalyzed: poseMetrics?.frameCount ?? 0,
      videoPath: widget.videoFile.path,
      poseDataList: poseMetrics?.poseData ?? [],
    );

    setState(() {
      _step = _ProcessingStep.done;
      _progress = 1.0;
    });

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          result: result,
          userId: widget.userId,
          athleteId: widget.athleteId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: const Icon(
                        Icons.pool_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _step == _ProcessingStep.compress
                      ? null
                      : _progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _step == _ProcessingStep.compress
                    ? 'ضغط الفيديو...'
                    : _step == _ProcessingStep.analyze
                        ? 'تحليل الحركة...'
                        : _step == _ProcessingStep.coaching
                            ? 'إنشاء التقرير...'
                            : 'اكتمل!',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
