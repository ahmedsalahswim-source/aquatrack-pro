import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/helpers.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/widgets/athlete_card.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/widgets/stress_gauge.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/widgets/mini_metric_card.dart';
import 'package:aquatrack_pro/injection_container.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/pages/daily_log_wizard_page.dart';
import 'package:aquatrack_pro/features/swim_vision/presentation/screens/swim_vision_screen.dart';
import 'package:aquatrack_pro/features/nutrition/presentation/screens/nutrition_dashboard_screen.dart';
import 'package:aquatrack_pro/features/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/widgets/dashboard_charts.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';

class DashboardPage extends StatelessWidget {
  final List<AthleteEntity> athletes;

  const DashboardPage({super.key, required this.athletes});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return _buildShimmerLoading();
        }
        if (state is DashboardLoaded) {
          return _buildDashboard(context, state);
        }
        if (state is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<DashboardBloc>().add(const RefreshDashboardEvent()),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.read<AppLocalizations>().translate('retry')),
                ),
              ],
            ),
          );
        }
        return _buildShimmerLoading();
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    final tr = context.read<AppLocalizations>();
    final t = DateHelpers.formatDateArabic(DateTime.now());

    return RefreshIndicator(
      onRefresh: () {
        context.read<DashboardBloc>().add(const RefreshDashboardEvent());
        return Future<void>.value();
      },
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Athlete Switcher
            if (athletes.length > 1)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: athletes.length,
                  itemBuilder: (context, index) {
                    final athlete = athletes[index];
                    final isSelected = athlete.id == state.athlete.id;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AthleteCard(
                        athlete: athlete,
                        isSelected: isSelected,
                        stressScore: isSelected ? state.stressScore : null,
                        onTap: () {
                          context.read<DashboardBloc>().add(
                            SelectAthleteEvent(athlete: athlete),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else if (athletes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AthleteCard(
                  athlete: state.athlete,
                  isSelected: true,
                  stressScore: state.stressScore,
                ),
              ),

            // Tab Bar
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.accent.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'يومي'),
                  Tab(text: 'أسبوعي'),
                  Tab(text: 'شهري'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                children: [
                  _buildDailyTab(context, state, tr, t),
                  _buildWeeklyTab(context, state, tr),
                  _buildMonthlyTab(context, state, tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab(BuildContext context, DashboardLoaded state, AppLocalizations tr, String t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Today Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.translate('today_status', params: {'name': state.athlete.name, 'date': t}),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.hasTodayLog ? tr.translate('last_updated_today') : tr.translate('not_logged_yet'),
                      style: TextStyle(
                        fontSize: 12,
                        color: state.hasTodayLog ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                // Readiness Score
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  borderRadius: 16,
                  color: AppColors.primary.withAlpha(20),
                  border: Border.all(color: AppColors.primary.withAlpha(100)),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'جاهزية ${state.readinessScore}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stress Score Gauge
            StressGauge(score: state.stressScore),
            const SizedBox(height: 16),

            // Mini Metrics Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: MiniMetricCard(
                    title: tr.translate('sleep'),
                    value: '${state.todayLog?.sleepHours?.toStringAsFixed(1) ?? '--'}h',
                    subtitle: '${tr.translate('compare_to_recommended')} ${DateHelpers.sleepRecommendationByAge(state.athlete.age).$1}h',
                    color: AppColors.sleepExcellent,
                    icon: Icons.bedtime_outlined,
                    metricType: MetricType.sleep,
                    trendData: state.recentLogs,
                    trendValue: state.recentLogs.length >= 2
                        ? (state.recentLogs.first.sleepHours ?? 0) - (state.recentLogs[1].sleepHours ?? 0)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniMetricCard(
                    title: tr.translate('heart_rate'),
                    value: state.todayLog?.restingHR != null
                        ? '${state.todayLog!.restingHR} BPM'
                        : '--',
                    subtitle: 'Baseline: ${state.athlete.restingHRBaseline ?? '--'}',
                    color: AppColors.danger,
                    icon: Icons.favorite_outlined,
                    metricType: MetricType.heartRate,
                    trendData: state.recentLogs,
                    trendValue: state.todayLog?.restingHR != null && state.athlete.restingHRBaseline != null
                        ? (state.todayLog!.restingHR! - state.athlete.restingHRBaseline!).toDouble()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiniMetricCard(
                    title: tr.translate('nutrition'),
                    value: state.todayLog?.nutrition != null
                        ? '${state.todayLog!.nutrition!.mealsCount}/4'
                        : '--',
                    subtitle: state.todayLog?.nutrition != null
                        ? '${state.todayLog!.nutrition!.hydrationLiters.toStringAsFixed(1)}L'
                        : tr.translate('no_data_yet'),
                    color: AppColors.success,
                    icon: Icons.restaurant_outlined,
                    metricType: MetricType.nutrition,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniMetricCard(
                    title: tr.translate('training'),
                    value: state.hasTodayLog && state.todayLog!.training != null
                        ? (state.todayLog!.training!.trained
                            ? '${state.todayLog!.training!.durationMinutes}min'
                            : tr.translate('rest_day'))
                        : '--',
                    subtitle: state.hasTodayLog && state.todayLog!.training?.rpe != null
                        ? 'RPE: ${state.todayLog!.training!.rpe}'
                        : tr.translate('no_data_yet'),
                    color: AppColors.accent,
                    icon: Icons.fitness_center_outlined,
                    metricType: MetricType.training,
                    trendData: state.recentLogs,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SwimVision Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.visibility_rounded, color: AppColors.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎥 تحليل الفيديو — SwimVision',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تحليل تقنية السباحة بالذكاء الاصطناعي',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SwimVisionScreen(
                            userId: state.athlete.id,
                            athleteId: state.athlete.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('فتح'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nutrition Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant_menu, color: AppColors.success, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🍎 التغذية والتعافي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تسجيل الوجبات وتتبع الماكروز',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => sl<NutritionBloc>(),
                            child: NutritionDashboardScreen(
                              athlete: state.athlete,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('فتح'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ACWR Section
            if (state.acwr != null && state.acwr! > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: state.acwr! > 1.3 ? AppColors.danger.withValues(alpha:  0.1) : AppColors.success.withValues(alpha:  0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          state.acwr!.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: state.acwr! > 1.3 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACWR — ${tr.translate('training_load')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            AcwrCalculator.getAcwrLabel(state.acwr!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: state.acwr! > 1.3 ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.acwr! > 1.3)
                      const Icon(Icons.warning_amber, color: AppColors.danger),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Alert Section
            if (!state.hasTodayLog)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha:  0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha:  0.2)),
                ),
                child: Column(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      tr.translate('not_logged_yet'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'سجّل بيانات اليوم لمتابعة دقيقة',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openLogWizard(context, state),
                      icon: const Icon(Icons.add),
                      label: Text(tr.translate('log_now')),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab(BuildContext context, DashboardLoaded state, AppLocalizations tr) {
    final weekLogs = state.recentLogs.take(7).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقرير 7 أيام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('مستوى الإجهاد (Stress)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StressChart(logs: weekLogs),
          const SizedBox(height: 24),
          const Text('معدل النوم (Sleep)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SleepChart(logs: weekLogs, athlete: state.athlete),
          const SizedBox(height: 24),
          const Text('حمل التدريب (Training Load)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TrainingLoadChart(logs: weekLogs),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(BuildContext context, DashboardLoaded state, AppLocalizations tr) {
    final monthLogs = state.recentLogs; // This is up to 30 days
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقرير 30 يوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('ACWR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AcwrChart(logs: monthLogs),
          const SizedBox(height: 24),
          const Text('نبض القلب وقت الراحة (HR)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HRChart(logs: monthLogs),
          const SizedBox(height: 24),
          const Text('ملخص التغذية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          NutritionSummary(logs: monthLogs),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final _ in [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openLogWizard(BuildContext context, DashboardLoaded state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DailyLogBloc>(),
          child: DailyLogWizardPage(
            athleteId: state.athlete.id,
            athleteName: state.athlete.name,
            athleteAge: state.athlete.age,
          ),
        ),
      ),
    );
  }
}
