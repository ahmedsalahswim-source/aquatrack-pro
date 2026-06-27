import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/widgets/athlete_card.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

Widget createTestWidget({
  bool isSelected = false,
  int? stressScore,
  VoidCallback? onTap,
}) {
  final athlete = AthleteEntity(
    id: '1',
    parentId: 'p1',
    name: 'Ahmed',
    birthDate: DateTime(2010, 6, 15),
    gender: Gender.male,
    createdAt: DateTime(2026),
  );
  return MaterialApp(
    home: Scaffold(
      body: AthleteCard(
        athlete: athlete,
        isSelected: isSelected,
        stressScore: stressScore,
        onTap: onTap,
      ),
    ),
  );
}

void main() {
  testWidgets('renders athlete name and age', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.textContaining('16'), findsOneWidget);
  });

  testWidgets('shows selected state with accent border', (tester) async {
    await tester.pumpWidget(createTestWidget(isSelected: true));
    await tester.pumpAndSettle();

    final glassContainerFinder = find.byType(GlassContainer);
    final container = tester.widget<GlassContainer>(glassContainerFinder.first);
    expect(container.border, isA<Border>());
    final border = container.border as Border;
    expect(border.left.color, AppColors.accent);
    expect(border.left.width, 2);
  });

  testWidgets('calls onTap when pressed', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(createTestWidget(onTap: () => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ahmed'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
