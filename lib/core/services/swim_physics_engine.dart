import 'package:aquatrack_pro/core/models/swim_pose_metrics.dart';

class SwimPhysicsResult {
  final double bodyAngle;
  final String bodyAngleScore;
  final double dragRating;
  final String dragMessage;
  final double strokeEfficiency;
  final double fatigueIndex;
  final double stabilityIndex;
  final double symmetryScore;
  final double strokeRate;
  final double strokeLength;
  final double strokeIndex;
  final double coordinationIndex;
  final double bodyRollAngle;
  final double rollSymmetry;
  final double headLift;
  final double handVelocity;
  final double propulsiveDrag;
  final double strouhalNumber;
  final double kickFrequency;
  final double kickAmplitude;
  final double propulsiveEfficiency;
  final double normalizedStrokeLength;
  final double armSweepAngle;
  final Map<String, double> phaseDuration;
  final List<String> scientificReferences;
  final List<String> warnings;

  const SwimPhysicsResult({
    required this.bodyAngle,
    required this.bodyAngleScore,
    required this.dragRating,
    required this.dragMessage,
    required this.strokeEfficiency,
    required this.fatigueIndex,
    required this.stabilityIndex,
    required this.symmetryScore,
    this.strokeRate = 0,
    this.strokeLength = 0,
    this.strokeIndex = 0,
    this.coordinationIndex = 0,
    this.bodyRollAngle = 0,
    this.rollSymmetry = 0,
    this.headLift = 0,
    this.handVelocity = 0,
    this.propulsiveDrag = 0,
    this.strouhalNumber = 0,
    this.kickFrequency = 0,
    this.kickAmplitude = 0,
    this.propulsiveEfficiency = 0,
    this.normalizedStrokeLength = 0,
    this.armSweepAngle = 0,
    this.phaseDuration = const {},
    this.scientificReferences = const [],
    this.warnings = const [],
  });
}

class SwimPhysicsEngine {
  static const double _waterDensity = 1000.0;

  SwimPhysicsResult analyze({
    double? estimatedBodyAngle,
    double? userSpeed,
    double? userCrossSectionalArea,
    SwimPoseMetrics? poseMetrics,
  }) {
    final angle = estimatedBodyAngle ?? poseMetrics?.bodyAngle ?? 170.0;
    final speed = userSpeed ?? _estimateSpeed(poseMetrics, angle);
    final area = userCrossSectionalArea ?? _estimateArea(angle);
    final cd = _dragCoefficient(angle);
    final drag = _computeDrag(speed, cd, area);

    final sr = poseMetrics?.strokeRate ?? 0;
    final sl = poseMetrics?.strokeLength ?? 0;
    final si = poseMetrics?.strokeIndex ?? 0;
    final coordIdx = poseMetrics?.coordinationIndex ?? 0;
    final roll = poseMetrics?.bodyRollAngle ?? 0;
    final rollSym = poseMetrics?.rollSymmetry ?? 0;
    final headLift = poseMetrics?.headLift ?? 0;
    final handVel = poseMetrics?.handVelocity ?? 0;
    const propDrag = 0.5 * 1000 * 1.8 * 1.8 * 0.35 * 0.12;
    final strouhal = si > 0 && handVel > 0
        ? ((sr / 60.0) * (sl * 0.3) / handVel)
        : 0.0;
    final kickFreq = poseMetrics?.kickFrequency ?? 0;
    final kickAmp = poseMetrics?.kickAmplitude ?? 0;
    final symmetry = poseMetrics?.symmetryScore ?? _symmetryScore(angle, 0);
    
    // Bio-mechanics equations
    final estimatedPower = 75.0; // Baseline estimated mechanical power for a swimmer in Watts
    final propEff = poseMetrics?.propulsiveEfficiency ?? (estimatedPower > 0 ? (speed * drag) / estimatedPower : 0.0);
    final normSl = poseMetrics?.normalizedStrokeLength ?? (sl > 0 ? sl / 1.705 : 0.0);
    final armSweep = poseMetrics?.armSweepAngle ?? 90.0;

    final phaseDur = poseMetrics?.phaseDuration ?? const <String, double>{};

    final angleScore = _classifyBodyAngle(angle);
    final eff = _strokeEfficiency(angle, sr, sl, coordIdx);
    final fatigue = _estimateFatigue(angle, eff, sr);
    final stability = _stabilityIndex(angle, roll);

    final warnings = _generateWarnings(
      angle, eff, fatigue, stability, symmetry,
      sr, sl, coordIdx, roll, headLift, kickFreq,
      propEff, armSweep, handVel, drag,
    );

    final refs = _scientificReferences(angle, sr, sl, coordIdx);

    return SwimPhysicsResult(
      bodyAngle: angle,
      bodyAngleScore: angleScore,
      dragRating: drag,
      dragMessage: _dragMessage(drag),
      strokeEfficiency: eff,
      fatigueIndex: fatigue,
      stabilityIndex: stability,
      symmetryScore: symmetry,
      strokeRate: sr,
      strokeLength: sl,
      strokeIndex: si,
      coordinationIndex: coordIdx,
      bodyRollAngle: roll,
      rollSymmetry: rollSym,
      headLift: headLift,
      handVelocity: handVel,
      propulsiveDrag: propDrag,
      strouhalNumber: strouhal,
      kickFrequency: kickFreq,
      kickAmplitude: kickAmp,
      propulsiveEfficiency: propEff,
      normalizedStrokeLength: normSl,
      armSweepAngle: armSweep,
      phaseDuration: phaseDur,
      scientificReferences: refs,
      warnings: warnings,
    );
  }

  double _dragCoefficient(double angle) {
    if (angle > 175) return 0.25;
    if (angle >= 170) return 0.35;
    if (angle >= 160) return 0.42;
    if (angle >= 150) return 0.50;
    return 0.60;
  }

  double _computeDrag(double speed, double cd, double area) {
    return 0.5 * _waterDensity * speed * speed * cd * area;
  }

  double _estimateSpeed(SwimPoseMetrics? poseMetrics, double angle) {
    if (poseMetrics?.strokeLength != null &&
        poseMetrics!.strokeLength > 0 &&
        poseMetrics.strokeRate > 0) {
      return (poseMetrics.strokeLength * poseMetrics.strokeRate) / 60.0;
    }
    final baseSpeed = 1.8;
    final angleFactor = angle / 180.0;
    return baseSpeed * (0.7 + 0.3 * angleFactor);
  }

  double _estimateArea(double angle) {
    if (angle >= 175) return 0.10;
    if (angle >= 170) return 0.12;
    if (angle >= 160) return 0.14;
    if (angle >= 150) return 0.16;
    return 0.18;
  }

  String _classifyBodyAngle(double angle) {
    if (angle >= 175) return 'ممتاز';
    if (angle >= 170) return 'جيد';
    if (angle >= 160) return 'مقبول';
    if (angle >= 150) return 'ضعيف';
    return 'يحتاج تحسين كبير';
  }

  double _strokeEfficiency(double angle, double sr, double sl, double coordIdx) {
    final angleScore = (angle / 180.0) * 40.0;
    final srScore = sr > 0 ? ((sr - 20) / 40 * 20).clamp(0, 20) : 0;
    final slScore = sl > 0 ? ((sl - 1.0) / 2.0 * 20).clamp(0, 20) : 10;
    final coordScore = coordIdx > 0
        ? (coordIdx / 20 * 10).clamp(0, 10)
        : 5;
    final base = angleScore + srScore + slScore + coordScore;
    return base.clamp(0.0, 100.0);
  }

  double _estimateFatigue(double angle, double efficiency, double sr) {
    final baseFatigue = (1.0 - (angle / 180.0)) * 40.0;
    final effPenalty = (1.0 - (efficiency / 100.0)) * 25.0;
    final srPenalty = sr > 50 ? (sr - 50) * 0.5 : 0.0;
    return (baseFatigue + effPenalty + srPenalty).clamp(0.0, 100.0);
  }

  double _stabilityIndex(double angle, double rollAngle) {
    final angleDev = (180.0 - angle).abs();
    final angleStability = (1.0 - (angleDev / 30.0)).clamp(0.0, 1.0);
    final rollPenalty = (rollAngle - 45).abs() / 45.0 * 0.3;
    return (angleStability - rollPenalty).clamp(0.0, 1.0);
  }

  double _symmetryScore(double angle, double fatigue) {
    final angleBase = (angle / 180.0) * 60.0;
    final fatiguePenalty = fatigue * 0.3;
    return (angleBase - fatiguePenalty).clamp(0.0, 100.0);
  }

  String _dragMessage(double drag) {
    if (drag < 60) return 'مقاومة منخفضة — تقنية ممتازة';
    if (drag < 90) return 'مقاومة منخفضة — وضع جسم جيد';
    if (drag < 120) return 'مقاومة متوسطة — يمكن تحسين وضع الجسم';
    if (drag < 160) return 'مقاومة عالية — تحتاج تحسين في الانسيابية';
    return 'مقاومة عالية جداً — ركز على رفع الوركين';
  }

  List<String> _generateWarnings(
    double angle, double eff, double fatigue, double stability,
    double symmetry, double sr, double sl, double coordIdx,
    double roll, double headLift, double kickFreq,
    double propEff, double armSweep, double handVel, double drag,
  ) {
    final warnings = <String>[];
    if (angle < 170) warnings.add('زاوية الجسم منخفضة ($angle°) — حاول رفع الوركين لأعلى');
    if (angle < 160) warnings.add('انحناء حاد في الوركين — درب عضلات المركز');
    if (eff < 50) warnings.add('كفاءة الضربة منخفضة جداً — ركز على طول الشدة');
    if (fatigue > 30) warnings.add('مؤشر الإجهاد مرتفع — خذ قسطاً من الراحة');
    if (stability < 0.5) warnings.add('ثبات الجسم ضعيف — درب عضلات المركز');
    if (symmetry < 60) warnings.add('تماثل الضربات غير متوازن — درب الذراع الأضعف');
    if (sr > 55) warnings.add('تردد الضربات مرتفع جداً ($sr ض/د) — زد طول الشدة');
    if (sr < 20 && sr > 0) warnings.add('تردد الضربات منخفض جداً ($sr ض/د) — زد السرعة');
    if (sl < 1.2 && sl > 0) warnings.add('طول الشدة قصير جداً ($sl م) — حسّن الانسيابية');
    if (coordIdx < -10) warnings.add('تنسيق الذراعين بطيء — قلّل وقت الانتظار');
    if (roll > 60) warnings.add('دوران الجسم مفرط ($roll°) — اثبت أكثر');
    if (headLift > 20) warnings.add('ارتفاع الرأس عالي — ابقِ الرأس منخفضاً');
    if (kickFreq > 70) warnings.add('تردد الركلة مرتفع جداً — وفّر طاقتك');
    
    if (propEff < 0.1) warnings.add('الكفاءة الدفعية منخفضة جداً (أقل من 10%) — ركز على السحب');
    if (handVel > 3.0 && drag < 70) warnings.add('سرعة يد عالية ولكن دفع منخفض (احتمال تسرب جريان/أصابع متباعدة) — ضم أصابعك قليلاً لتحسين تأثير جناح الدلتا');
    if (armSweep > 120) warnings.add('انكفاف خلفي زائد للذراع — حافظ على زاوية السحب أقرب لـ 90° للحصول على مسار مستقيم فعال');

    return warnings;
  }

  List<String> _scientificReferences(
    double angle, double sr, double sl, double coordIdx,
  ) {
    final refs = <String>[];
    refs.add('Biomechanics and Medicine in Swimming XI (2010) — '
        'معادلات السحب النشط عبر مراحل الشد');
    if (sr > 0 && sl > 0) {
      refs.add('Swim Speed Strokes — Taormina (2014) — '
          'مؤشر الشد (SI = $sr × $sl): '
          'النخبة > 3.5، جيد 2.5-3.5');
    }
    if (coordIdx != 0) {
      refs.add('Seifert & Chollet (BMS XI) — '
          'مؤشر التنسيق (IdC = ${coordIdx.toStringAsFixed(1)}): '
          '> 0 = تعاقبي، 0 = تراكبي، < 0 = انتظاري');
    }
    refs.add('Pease et al. (BMS XI) — '
        'تأثير زاوية الهجوم والعمق على السحب السلبي');
    refs.add('Bio-mechanisms of Swimming and Flying (2008) — '
        'الكفاءة الدفعية وديناميكا جناح الدلتا لكف اليد');
    return refs;
  }
}
