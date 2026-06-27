import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:aquatrack_pro/features/swim_vision/domain/entities/swim_analysis_result.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/analysis_result_screen.dart';

SwimAnalysisResult createTestResult({
  double strokeRate = 40,
  double strokeLength = 2.0,
  double strokeIndex = 80,
  double coordinationIndex = 5.0,
  double bodyRollAngle = 45,
  double kickFrequency = 50,
  double headLift = 12,
  Map<String, double> phaseDuration = const {'catch_': 25, 'pull': 30, 'push': 20, 'recovery': 25},
  List<String> references = const [],
  List<String> warnings = const [],
}) {
  return SwimAnalysisResult(
    bodyAngle: 170,
    bodyAngleScore: 'جيد',
    dragRating: 68,
    dragMessage: 'منخفضة',
    strokeEfficiency: 75,
    fatigueIndex: 20,
    stabilityIndex: 0.85,
    symmetryScore: 90,
    strokeRate: strokeRate,
    strokeLength: strokeLength,
    strokeIndex: strokeIndex,
    coordinationIndex: coordinationIndex,
    bodyRollAngle: bodyRollAngle,
    kickFrequency: kickFrequency,
    headLift: headLift,
    phaseDuration: phaseDuration,
    aiCoachingReport: 'ركز على تحسين زاوية الجسم',
    scientificReferences: references,
    warnings: warnings,
    frameCountAnalyzed: 120,
    videoDurationSeconds: 30,
  );
}

Widget createTestWidget(SwimAnalysisResult result) {
  return MaterialApp(
    home: AnalysisResultScreen(
      result: result,
      userId: 'test_user',
      athleteId: 'test_athlete',
    ),
  );
}

void main() {
  setUpAll(() async {
    Hive.init('.test_hive');
    await Hive.openBox('swim_vision');
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('swim_vision');
  });

  testWidgets('renders basic performance metrics', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('قياسات الأداء'), findsOneWidget);
    expect(find.text('زاوية الجسم'), findsOneWidget);
    expect(find.text('مقاومة الماء'), findsOneWidget);
    expect(find.text('كفاءة الضربة'), findsOneWidget);
    expect(find.text('مؤشر الإجهاد'), findsOneWidget);
  });

  testWidgets('renders stroke mechanics section', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('ميكانيكية الضربة'), findsOneWidget);
    expect(find.text('تردد الضربات'), findsOneWidget);
    expect(find.text('طول الشدة'), findsOneWidget);
    expect(find.text('مؤشر الشد (SI)'), findsOneWidget);
    expect(find.text('تنسيق الذراعين (IdC)'), findsOneWidget);
    expect(find.text('دوران الجسم'), findsOneWidget);
    expect(find.text('تردد الركلة'), findsOneWidget);
    expect(find.text('ارتفاع الرأس'), findsOneWidget);
  });

  testWidgets('hides stroke mechanics when metrics are zero', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(
      strokeRate: 0,
      strokeLength: 0,
      strokeIndex: 0,
      coordinationIndex: 0,
      bodyRollAngle: 0,
      kickFrequency: 0,
      headLift: 0,
    )));
    await tester.pumpAndSettle();

    expect(find.text('ميكانيكية الضربة'), findsNothing);
    expect(find.text('تردد الضربات'), findsNothing);
  });

  testWidgets('shows stroke rate value and label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(strokeRate: 40)));
    await tester.pumpAndSettle();

    expect(find.textContaining('40.0'), findsWidgets);
    expect(find.text('مثالي'), findsWidgets);
  });

  testWidgets('shows stroke length label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(strokeLength: 2.0)));
    await tester.pumpAndSettle();

    expect(find.text('ممتاز'), findsWidgets);
  });

  testWidgets('shows stroke index label for elite', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(strokeIndex: 4.0)));
    await tester.pumpAndSettle();

    expect(find.text('نخبة'), findsOneWidget);
  });

  testWidgets('shows coordination label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(coordinationIndex: 10)));
    await tester.pumpAndSettle();

    expect(find.text('تعاقبي'), findsOneWidget);
  });

  testWidgets('shows body roll label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(bodyRollAngle: 45)));
    await tester.pumpAndSettle();

    expect(find.text('مثالي'), findsWidgets);
  });

  testWidgets('shows kick label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(kickFrequency: 50)));
    await tester.pumpAndSettle();

    expect(find.text('مثالي'), findsWidgets);
  });

  testWidgets('shows head lift label', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(headLift: 12)));
    await tester.pumpAndSettle();

    expect(find.text('جيد'), findsWidgets);
  });

  testWidgets('shows head lift danger when high', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(headLift: 20)));
    await tester.pumpAndSettle();

    expect(find.text('مرتفع'), findsOneWidget);
  });

  testWidgets('shows PhaseVisualizer', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('توزيع مراحل الضربة'), findsOneWidget);
  });

  testWidgets('hides PhaseVisualizer when phaseDuration is empty', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(phaseDuration: {})));
    await tester.pumpAndSettle();

    expect(find.text('توزيع مراحل الضربة'), findsNothing);
  });

  testWidgets('renders AI coaching report', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('تقرير التدريب'), findsOneWidget);
    expect(find.textContaining('ركز على تحسين'), findsOneWidget);
  });

  testWidgets('shows scientific references', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(
      references: ['Taormina (2012)', 'Biomechanics XI (2006)'],
    )));
    await tester.pumpAndSettle();

    expect(find.text('المراجع العلمية'), findsOneWidget);
    expect(find.textContaining('Taormina'), findsOneWidget);
    expect(find.textContaining('Biomechanics'), findsOneWidget);
  });

  testWidgets('hides references section when empty', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('المراجع العلمية'), findsNothing);
  });

  testWidgets('shows warnings', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult(
      warnings: ['زاوية الجسم تحتاج تحسين', 'ارتفاع الرأس مفرط'],
    )));
    await tester.pumpAndSettle();

    expect(find.text('ملاحظات تحسينية'), findsOneWidget);
    expect(find.textContaining('زاوية الجسم تحتاج تحسين'), findsOneWidget);
    expect(find.textContaining('ارتفاع الرأس مفرط'), findsOneWidget);
  });

  testWidgets('hides warnings when empty', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('ملاحظات تحسينية'), findsNothing);
  });

  testWidgets('renders action buttons', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('حفظ التقرير'), findsOneWidget);
    expect(find.text('تحليل جديد'), findsOneWidget);
  });

  testWidgets('renders drag label correctly', (tester) async {

    final lowDragResult = SwimAnalysisResult(
      bodyAngle: 170, bodyAngleScore: 'جيد', dragRating: 50,
      dragMessage: 'منخفضة', strokeEfficiency: 75, fatigueIndex: 20,
      stabilityIndex: 0.85, symmetryScore: 90,
    );
    await tester.pumpWidget(createTestWidget(lowDragResult));
    await tester.pumpAndSettle();
    expect(find.text('منخفضة'), findsOneWidget);
  });

  testWidgets('renders efficiency labels', (tester) async {
    final goodEff = SwimAnalysisResult(
      bodyAngle: 170, bodyAngleScore: 'جيد', dragRating: 68,
      dragMessage: 'منخفضة', strokeEfficiency: 85, fatigueIndex: 20,
      stabilityIndex: 0.85, symmetryScore: 90,
    );
    await tester.pumpWidget(createTestWidget(goodEff));
    await tester.pumpAndSettle();
    expect(find.text('ممتاز'), findsWidgets);
  });

  testWidgets('renders stroke length ممتاز label', (tester) async {
    final result = SwimAnalysisResult(
      bodyAngle: 170, bodyAngleScore: 'جيد', dragRating: 68,
      dragMessage: 'منخفضة', strokeEfficiency: 75, fatigueIndex: 20,
      stabilityIndex: 0.85, symmetryScore: 90,
      strokeLength: 2.0,
    );
    await tester.pumpWidget(createTestWidget(result));
    await tester.pumpAndSettle();
    expect(find.text('ممتاز'), findsWidgets);
  });

  testWidgets('renders fatigue label', (tester) async {
    final lowFatigue = SwimAnalysisResult(
      bodyAngle: 170, bodyAngleScore: 'جيد', dragRating: 68,
      dragMessage: 'منخفضة', strokeEfficiency: 75, fatigueIndex: 10,
      stabilityIndex: 0.85, symmetryScore: 90,
    );
    await tester.pumpWidget(createTestWidget(lowFatigue));
    await tester.pumpAndSettle();
    expect(find.text('طاقة جيدة'), findsOneWidget);
  });

  testWidgets('save and new analysis buttons are rendered', (tester) async {
    await tester.pumpWidget(createTestWidget(createTestResult()));
    await tester.pumpAndSettle();

    expect(find.text('حفظ التقرير'), findsOneWidget);
    expect(find.text('تحليل جديد'), findsOneWidget);
  });
}
