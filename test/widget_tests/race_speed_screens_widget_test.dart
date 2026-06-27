import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/race_speed_input_screen.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/race_speed_result_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'test_helpers.dart';

void main() {
  group('RaceSpeedInputScreen Tests', () {
    testWidgets('Renders properly with default 50m and 10m segments', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterialApp(
        const RaceSpeedInputScreen(userId: 'u1', athleteId: 'a1'),
      ));

      expect(find.text('تحليل سرعة السباق'), findsOneWidget);
      expect(find.text('المسافة الكلية (متر)'), findsOneWidget);
      
      // Default segments is 50/10 = 5 text fields
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('عند 10 متر'), findsOneWidget);
      expect(find.text('عند 50 متر'), findsOneWidget);
    });

    testWidgets('Validates empty inputs', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterialApp(
        const RaceSpeedInputScreen(userId: 'u1', athleteId: 'a1'),
      ));

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحليل الأداء'));
      await tester.pump();

      expect(find.text('مطلوب'), findsWidgets);
    });
  });

  group('RaceSpeedResultScreen Tests', () {
    testWidgets('Renders stable pacer successfully', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterialApp(
        const RaceSpeedResultScreen(
          totalDistance: 50.0,
          cumulativeSplits: [10.0, 20.0, 30.0, 40.0, 50.0], // 1 m/s perfectly stable
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('نتيجة هبوط السرعة'), findsOneWidget);
      expect(find.text('تنظيم سرعة مستقر'), findsOneWidget);
      
      expect(find.text('أقصى سرعة'), findsOneWidget);
      expect(find.text('مؤشر التعب'), findsOneWidget);
      
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('Renders negative split fatigue successfully', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterialApp(
        const RaceSpeedResultScreen(
          totalDistance: 50.0,
          cumulativeSplits: [10.0, 18.3, 30.8, 47.4, 67.4], // S1:1.0, S2:1.2, S3:0.8, S4:0.6, S5:0.5 -> negative split fatigue
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('تدهور وتعب مبكر'), findsOneWidget);
    });
  });
}
