import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/athlete_detail_page.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

import 'test_helpers.dart';

void main() {
  group('AthleteDetailPage Widget Tests', () {
    late AthleteEntity athlete;

    setUp(() {
      athlete = AthleteEntity(
        id: 'a1',
        parentId: 'p1',
        name: 'John Doe',
        birthDate: DateTime(2010, 1, 1),
        gender: Gender.male,
        swimLevel: SwimLevel.intermediate,
        targetWeeklyHours: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('Renders athlete details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          AthleteDetailPage(athlete: athlete),
        ),
      );

      // Verify AppBar has athlete name
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('John Doe')), findsOneWidget);

      // We might see a CircularProgressIndicator initially because of _loadRecentLogs
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
