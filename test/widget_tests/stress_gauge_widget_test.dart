import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/widgets/stress_gauge.dart';

Widget createTestWidget(int score) {
  return MaterialApp(
    home: Provider<AppLocalizations>.value(
      value: AppLocalizations(const Locale('en')),
      child: Scaffold(
        body: StressGauge(score: score),
      ),
    ),
  );
}

void main() {
  testWidgets('renders with score', (tester) async {
    await tester.pumpWidget(createTestWidget(42));
    await tester.pumpAndSettle();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Stress Score'), findsOneWidget);
  });

  testWidgets('shows correct color and label based on score level', (tester) async {
    await tester.pumpWidget(createTestWidget(20));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
    expect(find.text('ممتاز'), findsOneWidget);

    await tester.pumpWidget(createTestWidget(45));
    await tester.pumpAndSettle();
    expect(find.text('45'), findsOneWidget);
    expect(find.text('طبيعي'), findsOneWidget);

    await tester.pumpWidget(createTestWidget(90));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
    expect(find.text('خطر'), findsOneWidget);
  });
}
