import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/pages/dashboard_page.dart';
import 'test_helpers.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}

void main() {
  late MockDashboardBloc mockDashboardBloc;

  final testAthlete = AthleteEntity(
    id: 'a1',
    parentId: 'c1',
    name: 'Ahmed',
    birthDate: DateTime(1999, 1, 1),
    gender: Gender.male,
    heightCm: 180,
    weightKg: 75,
    swimLevel: SwimLevel.advanced,
    restingHRBaseline: 60,
    createdAt: DateTime.now(),
  );

  setUp(() async {
    await initializeDateFormatting('ar', null);
    mockDashboardBloc = MockDashboardBloc();
  });

  Widget createWidget(DashboardState state) {
    when(() => mockDashboardBloc.state).thenReturn(state);
    when(() => mockDashboardBloc.stream).thenAnswer((_) => Stream.value(state));

    return wrapWithMaterialApp(
      BlocProvider<DashboardBloc>.value(
        value: mockDashboardBloc,
        child: Scaffold(body: DashboardPage(athletes: [testAthlete])),
      ),
      locale: const Locale('ar'),
    );
  }

  testWidgets('renders shimmer loading when state is DashboardInitial', (tester) async {
    await tester.pumpWidget(createWidget(const DashboardInitial()));
    expect(find.byType(Shimmer), findsWidgets);
  });

  testWidgets('renders shimmer loading when state is DashboardLoading', (tester) async {
    await tester.pumpWidget(createWidget(const DashboardLoading()));
    expect(find.byType(Shimmer), findsWidgets);
  });

  testWidgets('renders error message when state is DashboardError', (tester) async {
    await tester.pumpWidget(createWidget(const DashboardError(message: 'Failed to load data')));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load data'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('renders dashboard tabs when state is DashboardLoaded', (tester) async {
    final loadedState = DashboardLoaded(
      athlete: testAthlete,
      recentLogs: const [],
      stressScore: 30,
      readinessScore: 85,
    );
    await tester.pumpWidget(createWidget(loadedState));
    await tester.pumpAndSettle();

    expect(find.text('يومي'), findsOneWidget);
    expect(find.text('أسبوعي'), findsOneWidget);
    expect(find.text('شهري'), findsOneWidget);
    expect(find.text('جاهزية 85%'), findsOneWidget);
  });
}
