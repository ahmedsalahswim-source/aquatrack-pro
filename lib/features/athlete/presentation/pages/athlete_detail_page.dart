import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/pages/daily_log_wizard_page.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/add_athlete_page.dart';
import 'package:aquatrack_pro/injection_container.dart';

class AthleteDetailPage extends StatefulWidget {
  final AthleteEntity athlete;

  const AthleteDetailPage({super.key, required this.athlete});

  @override
  State<AthleteDetailPage> createState() => _AthleteDetailPageState();
}

class _AthleteDetailPageState extends State<AthleteDetailPage> {
  List<DailyLogEntity> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentLogs();
  }

  Future<void> _loadRecentLogs() async {
    final result = await sl<DailyLogRepository>().getLogsInRange(widget.athlete.id, 14);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _isLoading = false),
      (logs) => setState(() {
        _logs = logs;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final a = widget.athlete;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddAthletePage(
                    parentId: a.parentId,
                    existingAthlete: a,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecentLogs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(a, t),
                    const SizedBox(height: 20),
                    _buildBaselineCard(a, t),
                    const SizedBox(height: 20),
                    _buildQuickStats(a, t),
                    const SizedBox(height: 20),
                    _buildRecentLogs(a, t),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard(AthleteEntity a, AppLocalizations t) {
    final age = DateHelpers.calculateAge(a.birthDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha:  0.3),
            child: Text(
              a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text('$age ${t.translate('years_old')} · ${_levelLabel(a.swimLevel, t)} · ${a.gender == Gender.male ? t.translate('male') : t.translate('female')}',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha:  0.9))),
        ],
      ),
    );
  }

  Widget _buildBaselineCard(AthleteEntity a, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.translate('baseline_measurements'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _baselineItem(t.translate('weight'), a.weightKg != null ? '${a.weightKg!.toStringAsFixed(1)} kg' : '--'),
              _baselineItem(t.translate('height'), a.heightCm != null ? '${a.heightCm!.toStringAsFixed(0)} cm' : '--'),
              _baselineItem(t.translate('weekly_goal'), '${a.targetWeeklyHours.toStringAsFixed(0)} h'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _baselineItem(t.translate('resting_hr_baseline'), a.restingHRBaseline != null ? '${a.restingHRBaseline} ${t.translate('beats')}' : '--'),
              _baselineItem(t.translate('sleep_baseline'), a.sleepBaseline != null ? '${a.sleepBaseline!.toStringAsFixed(1)} h' : '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _baselineItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AthleteEntity a, AppLocalizations t) {
    final withStress = _logs.where((l) => l.stressScore != null).toList();
    final withSleep = _logs.where((l) => l.sleepHours != null).toList();
    final withHR = _logs.where((l) => l.restingHR != null).toList();

    final avgStress = withStress.isEmpty ? 0 : withStress.fold<double>(0, (s, l) => s + l.stressScore!) / withStress.length;
    final avgSleep = withSleep.isEmpty ? 0 : withSleep.fold<double>(0, (s, l) => s + l.sleepHours!) / withSleep.length;
    final avgHR = withHR.isEmpty ? 0 : withHR.fold<double>(0, (s, l) => s + l.restingHR!) / withHR.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.translate('last_14_days'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox(t.translate('stress'), avgStress.toStringAsFixed(0), AppColors.stressColor(avgStress.round())),
              _statBox(t.translate('sleep'), '${avgSleep.toStringAsFixed(1)}h', avgSleep >= 8 ? AppColors.success : AppColors.danger),
              _statBox(t.translate('heart_rate'), avgHR.toStringAsFixed(0), AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:  0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs(AthleteEntity a, AppLocalizations t) {
    if (_logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Text('📋', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(t.translate('no_logs_yet'), style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyLogWizardPage(
                      athleteId: a.id,
                      athleteName: a.name,
                      athleteAge: a.age,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.translate('log_first_day')),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.translate('recent_logs'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._logs.take(10).map((log) => _buildLogTile(log, t)),
        ],
      ),
    );
  }

  Widget _buildLogTile(DailyLogEntity log, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                log.date.length >= 10 ? log.date.substring(5) : log.date,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (log.restingHR != null) _miniTag('${log.restingHR}', Icons.favorite_border),
                    if (log.sleepHours != null) _miniTag('${log.sleepHours!.toStringAsFixed(0)}h', Icons.bedtime_outlined),
                    if (log.stressScore != null)
                      _miniTag('${log.stressScore}', Icons.waves),
                    if (log.training?.trainingLoad != null)
                      _miniTag('${t.translate('training_load')} ${log.training!.trainingLoad}', Icons.fitness_center),
                  ],
                ),
                if (log.nutrition != null)
                  Text(
                    '${'🍳${log.nutrition!.breakfast ? '✓' : '✗'} '}'
                    '${'🍱${log.nutrition!.lunch ? '✓' : '✗'} '}'
                    '${'🍽${log.nutrition!.dinner ? '✓' : '✗'} '}'
                    '${'🥤${log.nutrition!.hydrationLiters.toStringAsFixed(0)}l'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: AppColors.textMuted),
            const SizedBox(width: 2),
            Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  String _levelLabel(SwimLevel level, AppLocalizations t) {
    switch (level) {
      case SwimLevel.beginner: return t.translate('beginner');
      case SwimLevel.intermediate: return t.translate('intermediate');
      case SwimLevel.advanced: return t.translate('advanced');
      case SwimLevel.competitive: return t.translate('competitive');
    }
  }
}
