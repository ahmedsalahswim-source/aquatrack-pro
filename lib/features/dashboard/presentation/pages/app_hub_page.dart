import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/add_athlete_page.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/athletes_tab.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/settings_tab.dart';
import 'package:aquatrack_pro/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/pages/daily_log_wizard_page.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:aquatrack_pro/injection_container.dart' show sl;
import 'package:aquatrack_pro/core/widgets/gradient_scaffold.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

class AppHubPage extends StatefulWidget {
  final UserEntity user;

  const AppHubPage({
    super.key,
    required this.user,
  });

  @override
  State<AppHubPage> createState() => _AppHubPageState();
}

class _AppHubPageState extends State<AppHubPage> {
  int _currentTab = 0;
  bool _didInitDashboard = false;

  @override
  void initState() {
    super.initState();
    context.read<AthleteBloc>().add(WatchAthletesEvent(parentId: widget.user.uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteBloc, AthleteState>(
      builder: (context, athleteState) {
        final t = context.read<AppLocalizations>();
        final athletes = athleteState is AthletesLoaded ? athleteState.athletes : <AthleteEntity>[];
        final selectedAthlete = athleteState is AthletesLoaded ? athleteState.selectedAthlete : null;

        return GradientScaffold(
          body: IndexedStack(
            index: _currentTab,
            children: [
              // Tab 0: Dashboard
              _buildDashboardTab(context, athletes, selectedAthlete),
              // Tab 1: Athletes
              AthletesTab(parentId: widget.user.uid),
              // Tab 2: AI Assistant
              _buildAiTab(context, athletes, selectedAthlete),
              // Tab 3: Settings
              SettingsTab(user: widget.user),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _currentTab,
                  onTap: (index) => setState(() => _currentTab = index),
                  items: [
                    BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: t.translate('dashboard')),
                    BottomNavigationBarItem(icon: const Icon(Icons.people_outlined), activeIcon: const Icon(Icons.people), label: t.translate('athletes')),
                    BottomNavigationBarItem(icon: const Icon(Icons.smart_toy_outlined), activeIcon: const Icon(Icons.smart_toy), label: t.translate('ai_assistant')),
                    BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: t.translate('settings')),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _currentTab == 0 && athletes.isNotEmpty
              ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () {
                    final athlete = selectedAthlete ?? athletes.first;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailyLogWizardPage(
                          athleteId: athlete.id,
                          athleteName: athlete.name,
                          athleteAge: athlete.age,
                          baselineHR: athlete.restingHRBaseline,
                        ),
                      ),
                    );
                  },
                  backgroundColor: AppColors.accent,
                  icon: const Icon(Icons.add),
                  label: Text(
                    t.translate('log_today'),
                    style: TextStyle(
                      fontFamily: Theme.of(context).textTheme.titleSmall?.fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDashboardTab(BuildContext context, List<AthleteEntity> athletes, AthleteEntity? selected) {
    final t = context.read<AppLocalizations>();
    if (athletes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              t.translate('welcome_to_app'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('add_athlete_to_start'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddAthletePage(parentId: widget.user.uid),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(t.translate('add_athlete')),
            ),
          ],
        ),
      );
    }

    if (!_didInitDashboard && athletes.isNotEmpty) {
      _didInitDashboard = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardBloc>().add(LoadDashboardEvent(
            athlete: selected ?? athletes.first,
          ));
        }
      });
    }

    return DashboardPage(athletes: athletes);
  }

  Widget _buildAiTab(BuildContext context, List<AthleteEntity> athletes, AthleteEntity? selected) {
    final t = context.read<AppLocalizations>();
    if (athletes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              t.translate('add_athlete_first'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final athlete = selected ?? athletes.first;
    final dbState = context.read<DashboardBloc>().state;
    DashboardData? dashboardData;
    if (dbState is DashboardLoaded) {
      final s = dbState;
      dashboardData = DashboardData(
        athlete: s.athlete,
        todayLog: s.todayLog,
        stressScore: s.stressScore,
        acwr: s.acwr,
        hasTodayLog: s.hasTodayLog,
        recentLogs: s.recentLogs,
      );
    }

    return BlocProvider(
      create: (_) => sl<AiBloc>(),
      child: AiAssistantPage(
        userId: widget.user.uid,
        athlete: athlete,
        dashboardData: dashboardData,
      ),
    );
  }

}
