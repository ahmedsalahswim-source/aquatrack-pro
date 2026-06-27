import 'package:aquatrack_pro/core/services/swim_physics_engine.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:aquatrack_pro/injection_container.dart' as di;

class AiCoachingResult {
  final String report;
  final List<String> references;

  const AiCoachingResult({
    required this.report,
    this.references = const [],
  });
}

class AiCoachingService {
  AiRemoteDataSource? _dataSource;

  AiRemoteDataSource get _ds => _dataSource ??= di.sl<AiRemoteDataSource>();

  Future<AiCoachingResult> getCoachingReport({
    required String userId,
    required String athleteId,
    required SwimPhysicsResult physics,
  }) async {
    final prompt = _buildPrompt(physics);

    try {
      final response = await _ds.sendToGemini(
        userId: userId,
        athleteId: athleteId,
        question: prompt,
        context: _buildContext(physics),
        category: AiCategory.training,
        systemPrompt: 'أنت مدرب سباحة محترف. قدم تحليلاً فنياً وبدنياً للسباح بناءً على بيانات التحليل الحركي.',
        kbChunks: const [],
        webResults: const [],
      );

      final report = response.answer.isNotEmpty
          ? response.answer
          : 'عذراً، لم يتمكن المساعد من إنشاء تقرير تدريبي.';
      final refs = _extractReferences(response.answer);

      return AiCoachingResult(report: report, references: refs);
    } catch (e) {
      return AiCoachingResult(
        report: _fallbackReport(physics),
        references: [
          'International Journal of Sports Physiology and Performance',
          'Swimming Science Bulletin — www.swimmingscience.com',
        ],
      );
    }
  }

  String _buildContext(SwimPhysicsResult physics) {
    return 'تحليل سباحة - زاوية الجسم: ${physics.bodyAngle.toStringAsFixed(1)}° | '
        'كفاءة الضربة: ${physics.strokeEfficiency.toStringAsFixed(1)}% | '
        'الكفاءة الدفعية: ${(physics.propulsiveEfficiency * 100).toStringAsFixed(1)}% | '
        'مؤشر الإجهاد: ${physics.fatigueIndex.toStringAsFixed(1)}% | '
        'تردد الضربات: ${physics.strokeRate.toStringAsFixed(1)} ض/د | '
        'مؤشر التنسيق: ${physics.coordinationIndex.toStringAsFixed(1)} | '
        'زاوية الدوران: ${physics.bodyRollAngle.toStringAsFixed(1)}°';
  }

  String _buildPrompt(SwimPhysicsResult physics) {
    return '''
أنت مدرب سباحة علمي متخصص.
بناءً على التحليل الميكانيكي التالي للسباح:

زاوية الجسم: ${physics.bodyAngle.toStringAsFixed(1)} درجة — ${physics.bodyAngleScore}
تقييم المقاومة: ${physics.dragRating.toStringAsFixed(1)} — ${physics.dragMessage}
كفاءة الضربة: ${physics.strokeEfficiency.toStringAsFixed(1)}%
مؤشر الإجهاد: ${physics.fatigueIndex.toStringAsFixed(1)}%
مؤشر الاستقرار: ${physics.stabilityIndex.toStringAsFixed(2)}
درجة التماثل: ${physics.symmetryScore.toStringAsFixed(1)}%
${physics.strokeRate > 0 ? 'تردد الضربات: ${physics.strokeRate.toStringAsFixed(1)} ضربة في الدقيقة' : ''}
${physics.strokeLength > 0 ? 'طول الشدة: ${physics.strokeLength.toStringAsFixed(2)} متر' : ''}
${physics.normalizedStrokeLength > 0 ? 'طول الشدة المطبع (بالنسبة للطول): ${physics.normalizedStrokeLength.toStringAsFixed(2)}' : ''}
${physics.strokeIndex > 0 ? 'مؤشر الشد (SI): ${physics.strokeIndex.toStringAsFixed(2)}' : ''}
${physics.propulsiveEfficiency > 0 ? 'الكفاءة الدفعية المقدرة: ${(physics.propulsiveEfficiency * 100).toStringAsFixed(1)}%' : ''}
${physics.armSweepAngle > 0 ? 'زاوية الانكفاف الخلفي للذراع: ${physics.armSweepAngle.toStringAsFixed(1)}°' : ''}
${physics.coordinationIndex != 0 ? 'مؤشر تنسيق الذراعين (IdC): ${physics.coordinationIndex.toStringAsFixed(1)}' : ''}
${physics.bodyRollAngle > 0 ? 'زاوية دوران الجسم: ${physics.bodyRollAngle.toStringAsFixed(1)}°' : ''}
${physics.kickFrequency > 0 ? 'تردد الركلة: ${physics.kickFrequency.toStringAsFixed(1)} ركلة/دقيقة' : ''}
${physics.headLift > 0 ? 'ارتفاع الرأس: ${physics.headLift.toStringAsFixed(1)} وحدات' : ''}

المصادر العلمية المستخدمة في التقييم:
${_buildRefList(physics)}

قدم تقريراً تدريبياً باللغة العربية يتضمن:
1. تقييم الوضع الحالي بالأرقام
2. أهم نقطتين تحتاجان تحسيناً فورياً
3. تمرينين تطبيقيين محددين وقابلين للتنفيذ
4. مرجع علمي واحد من الكتب المذكورة أعلاه

اجعل التقرير واضحاً ومحفزاً ومناسباً للسباح الشاب.
لا تتجاوز 300 كلمة.
'''.trim();
  }

  String _buildRefList(SwimPhysicsResult physics) {
    final refs = <String>[];
    refs.add('- Biomechanics and Medicine in Swimming XI (2010): معادلات السحب النشط');
    if (physics.strokeRate > 0 && physics.strokeLength > 0) {
      refs.add('- Swim Speed Strokes — Taormina (2014): مؤشر الشد SI');
    }
    if (physics.coordinationIndex != 0) {
      refs.add('- Seifert & Chollet (BMS XI): مؤشر التنسيق IdC');
    }
    refs.add('- Bio-mechanisms of Swimming and Flying (2008): الكفاءة الدفعية وجناح الدلتا');
    return refs.join('\n');
  }

  String _fallbackReport(SwimPhysicsResult physics) {
    return '''
تقرير التدريب — تحليل السباحة

التقييم العام:
${physics.bodyAngleScore} في زاوية الجسم (${physics.bodyAngle.toStringAsFixed(1)}°).
${physics.dragMessage}.
كفاءة الضربة: ${physics.strokeEfficiency.toStringAsFixed(1)}%.
مؤشر الإجهاد: ${physics.fatigueIndex.toStringAsFixed(1)}%.
${physics.strokeRate > 0 ? 'تردد الضربات: ${physics.strokeRate.toStringAsFixed(1)} ض/د.' : ''}
${physics.strokeLength > 0 ? 'طول الشدة: ${physics.strokeLength.toStringAsFixed(2)} م.' : ''}

النقاط التي تحتاج تحسيناً:
${physics.warnings.isNotEmpty ? physics.warnings.map((w) => '• $w').join('\n') : 'الأداء جيد بشكل عام'}

التمارين المقترحة:
• تمرين السباحة باستخدام لوح السباحة لتحسين وضع الجسم
• تمارين التنفس الجانبي لتقليل مقاومة الجسم

ملاحظة: هذا التقرير تلقائي — استشر مدرب السباحة للحصول على تقييم متخصص.
'''.trim();
  }

  List<String> _extractReferences(String answer) {
    final refs = <String>[];
    final lines = answer.split('\n');
    for (final line in lines) {
      if (line.contains('مرجع') ||
          line.contains('كتاب') ||
          line.contains('دراسة') ||
          line.contains('المصدر') ||
          line.contains('www.') ||
          line.contains('.com')) {
        refs.add(line.trim().replaceAll(RegExp(r'^[•\-*\d.]+'), '').trim());
      }
    }
    if (refs.isEmpty) {
      refs.add('International Journal of Sports Physiology and Performance');
    }
    return refs;
  }
}
