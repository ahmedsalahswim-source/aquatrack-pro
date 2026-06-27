import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class SwimmerContextBuilder {
  const SwimmerContextBuilder();

  String buildFullContext({
    required AthleteEntity athlete,
    required List<DailyLogEntity> recentLogs,
    DailyLogEntity? todayLog,
    double? acwr,
    int? stressScore,
  }) {
    final buf = StringBuffer();
    buf.writeln('=== الملف الشخصي للسباح ===');
    buf.writeln('الاسم: ${athlete.name}');
    buf.writeln('العمر: ${athlete.age} سنة');
    buf.writeln('الجنس: ${athlete.gender == Gender.male ? "ذكر" : "أنثى"}');
    buf.writeln('مستوى السباحة: ${_swimLevelLabel(athlete.swimLevel)}');
    if (athlete.weightKg != null) buf.writeln('الوزن: ${athlete.weightKg} كجم');
    if (athlete.heightCm != null) buf.writeln('الطول: ${athlete.heightCm} سم');
    buf.writeln('الهدف الأسبوعي: ${athlete.targetWeeklyHours} ساعة تدريب');
    buf.writeln('');

    buf.writeln('=== المؤشرات الحيوية (آخر 14 يوم) ===');
    if (recentLogs.isEmpty) {
      buf.writeln('لا توجد تسجيلات كافية بعد.');
    } else {
      final logs = recentLogs.take(14).toList();
      for (int i = 0; i < logs.length; i++) {
        final log = logs[i];
        buf.writeln('--- يوم ${i + 1}: ${log.date} ---');
        if (log.restingHR != null) buf.writeln('  نبض الراحة: ${log.restingHR} BPM');
        if (log.sleepHours != null) {
          buf.writeln('  النوم: ${log.sleepHours} ساعات ${log.sleepQuality != null ? "(${_sleepQualityLabel(log.sleepQuality!)})" : ""}');
        }
        if (log.wellnessScore != null) buf.writeln('  مؤشر النشاط: ${log.wellnessScore}/5');
        if (log.nutrition != null) {
          final n = log.nutrition!;
          buf.writeln('  التغذية: ${n.mealsCount}/4 وجبات | ماء: ${n.hydrationLiters}ل | بروتين كافٍ: ${n.proteinSufficient ? "نعم" : "لا"}');
        }
        if (log.training != null) {
          final t = log.training!;
          if (t.trained) {
            buf.writeln('  التدريب: ${t.durationMinutes ?? "?"} دقيقة ${t.type != null ? "(${_trainingTypeLabel(t.type!)})" : ""} | RPE: ${t.rpe ?? "?"}');
            if (t.trainingLoad != null) buf.writeln('  حمل التدريب: ${t.trainingLoad}');
            if (t.distanceMeters != null) buf.writeln('  المسافة: ${t.distanceMeters} م');
          } else {
            buf.writeln('  التدريب: راحة/لم يتدرب');
          }
        }
        if (log.stressScore != null) buf.writeln('  مؤشر الإجهاد: ${log.stressScore}/100');
        if (log.acwr != null) buf.writeln('  ACWR: ${log.acwr!.toStringAsFixed(2)}');
      }

      buf.writeln('');
      buf.writeln('=== الإحصائيات ===');
      _addStats(buf, logs);
    }
    buf.writeln('');

    if (todayLog != null) {
      buf.writeln('=== تسجيل اليوم ===');
      buf.writeln('التاريخ: ${todayLog.date}');
      if (todayLog.restingHR != null) buf.writeln('النبض: ${todayLog.restingHR} BPM');
      if (todayLog.sleepHours != null) buf.writeln('النوم: ${todayLog.sleepHours} ساعات');
      if (todayLog.stressScore != null) buf.writeln('الإجهاد: ${todayLog.stressScore}/100');
      if (todayLog.acwr != null) buf.writeln('ACWR: ${todayLog.acwr!.toStringAsFixed(2)}');
      buf.writeln('');
    }

    if (acwr != null) {
      buf.writeln('ACWR الحالي: ${acwr.toStringAsFixed(2)}');
      if (acwr < 0.8) {
        buf.writeln('التقييم: أقل من الموصى به — خطر قلة التدريب');
      } else if (acwr < 1.0) {
        buf.writeln('التقييم: منخفض — زيادة تدريجية');
      } else if (acwr < 1.3) {
        buf.writeln('التقييم: طبيعي — مثالي');
      } else if (acwr < 1.5) {
        buf.writeln('التقييم: مرتفع — انتبه للإجهاد');
      } else {
        buf.writeln('التقييم: خطر — احتمال إصابة مرتفع');
      }
    }
    if (stressScore != null) {
      buf.writeln('مؤشر الإجهاد: $stressScore/100');
    }

    return buf.toString();
  }

  void _addStats(StringBuffer buf, List<DailyLogEntity> logs) {
    final withSleep = logs.where((l) => l.sleepHours != null).toList();
    if (withSleep.isNotEmpty) {
      final avg = withSleep.map((l) => l.sleepHours!).fold<double>(0, (a, b) => a + b) / withSleep.length;
      buf.writeln('- متوسط النوم: ${avg.toStringAsFixed(1)} ساعات');
    }
    final withHR = logs.where((l) => l.restingHR != null).toList();
    if (withHR.isNotEmpty) {
      final avg = withHR.map((l) => l.restingHR!).fold<double>(0, (a, b) => a + b) / withHR.length;
      buf.writeln('- متوسط نبض الراحة: ${avg.toStringAsFixed(0)} BPM');
    }
    final withWellness = logs.where((l) => l.wellnessScore != null).toList();
    if (withWellness.isNotEmpty) {
      final avg = withWellness.map((l) => l.wellnessScore!).fold<double>(0, (a, b) => a + b) / withWellness.length;
      buf.writeln('- متوسط مؤشر النشاط: ${avg.toStringAsFixed(1)}/5');
    }
    final withStress = logs.where((l) => l.stressScore != null).toList();
    if (withStress.isNotEmpty) {
      final avg = withStress.map((l) => l.stressScore!).fold<double>(0, (a, b) => a + b) / withStress.length;
      buf.writeln('- متوسط الإجهاد: ${avg.toStringAsFixed(0)}/100');
    }
    final trained = logs.where((l) => l.training?.trained == true).toList();
    if (trained.isNotEmpty) {
      final totalMinutes = trained.fold<int>(0, (s, l) => s + (l.training!.durationMinutes ?? 0));
      final avgMinutes = totalMinutes / trained.length;
      buf.writeln('- أيام التدريب: ${trained.length}/${logs.length}');
      buf.writeln('- متوسط مدة التدريب: ${avgMinutes.toStringAsFixed(0)} دقيقة');
      if (trained.any((l) => l.training!.rpe != null)) {
        final avgRpe = trained.where((l) => l.training!.rpe != null)
            .map((l) => l.training!.rpe!)
            .fold<double>(0, (a, b) => a + b) / trained.where((l) => l.training!.rpe != null).length;
        buf.writeln('- متوسط RPE: ${avgRpe.toStringAsFixed(1)}');
      }
    }
    final withNutrition = logs.where((l) => l.nutrition != null).toList();
    if (withNutrition.isNotEmpty) {
      final avgMeals = withNutrition.map((l) => l.nutrition!.mealsCount).fold<double>(0, (a, b) => a + b) / withNutrition.length;
      buf.writeln('- متوسط الوجبات: ${avgMeals.toStringAsFixed(1)}/4');
      final hydrated = withNutrition.where((l) => l.nutrition!.hydrationLiters >= 2).length;
      buf.writeln('- أيام الترطيب الكافي: $hydrated/${withNutrition.length}');
      final protein = withNutrition.where((l) => l.nutrition!.proteinSufficient).length;
      buf.writeln('- أيام البروتين الكافي: $protein/${withNutrition.length}');
    }
  }

  String _swimLevelLabel(SwimLevel level) {
    switch (level) {
      case SwimLevel.beginner: return 'مبتدئ';
      case SwimLevel.intermediate: return 'متوسط';
      case SwimLevel.advanced: return 'متقدم';
      case SwimLevel.competitive: return 'تنافسي';
    }
  }

  String _sleepQualityLabel(SleepQuality q) {
    switch (q) {
      case SleepQuality.poor: return 'سيء';
      case SleepQuality.fair: return 'مقبول';
      case SleepQuality.good: return 'جيد';
      case SleepQuality.excellent: return 'ممتاز';
    }
  }

  String _trainingTypeLabel(TrainingType t) {
    switch (t) {
      case TrainingType.technique: return 'تقنية';
      case TrainingType.endurance: return 'تحمل';
      case TrainingType.sprint: return 'سرعة';
      case TrainingType.dryland: return 'يابس';
      case TrainingType.competition: return 'منافسة';
      case TrainingType.rest: return 'راحة';
    }
  }
}
