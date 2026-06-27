import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/widgets/phase_visualizer.dart';

Widget createTestWidget({
  Map<String, double>? phaseDuration,
  double strokeRate = 40,
  double? coordinationIndex,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PhaseVisualizer(
        phaseDuration: phaseDuration ?? {'catch_': 25, 'pull': 30, 'push': 20, 'recovery': 25},
        strokeRate: strokeRate,
        coordinationIndex: coordinationIndex,
      ),
    ),
  );
}

void main() {
  testWidgets('renders title and phases', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('توزيع مراحل الضربة'), findsOneWidget);
    expect(find.text('Catch'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
  });

  testWidgets('shows legend with percentages', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('%'), findsWidgets);
  });

  testWidgets('shows cycle time', (tester) async {
    await tester.pumpWidget(createTestWidget(strokeRate: 60));
    await tester.pumpAndSettle();

    expect(find.textContaining('زمن الدورة الكاملة'), findsOneWidget);
    expect(find.textContaining('1.0'), findsOneWidget);
  });

  testWidgets('shows coordination description when provided', (tester) async {
    await tester.pumpWidget(createTestWidget(coordinationIndex: 10));
    await tester.pumpAndSettle();

    expect(find.textContaining('تنسيق تعاقبي'), findsOneWidget);
  });

  testWidgets('shows catch-up for negative coordination', (tester) async {
    await tester.pumpWidget(createTestWidget(coordinationIndex: -10));
    await tester.pumpAndSettle();

    expect(find.textContaining('تنسيق انتظاري'), findsOneWidget);
  });

  testWidgets('shows superposition for near-zero coordination', (tester) async {
    await tester.pumpWidget(createTestWidget(coordinationIndex: 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('تنسيق تراكبي'), findsOneWidget);
  });

  testWidgets('hides coordination section when null', (tester) async {
    await tester.pumpWidget(createTestWidget(coordinationIndex: null));
    await tester.pumpAndSettle();

    expect(find.textContaining('تنسيق'), findsNothing);
  });

  testWidgets('shows 0s cycle time for strokeRate of 0', (tester) async {
    await tester.pumpWidget(createTestWidget(strokeRate: 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 ث'), findsOneWidget);
  });

  testWidgets('is empty for empty phaseDuration', (tester) async {
    await tester.pumpWidget(createTestWidget(phaseDuration: {}));
    await tester.pumpAndSettle();

    expect(find.text('توزيع مراحل الضربة'), findsNothing);
  });
}
