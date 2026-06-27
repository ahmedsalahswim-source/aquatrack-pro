import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

class StepSleep extends StatelessWidget {
  final String athleteName;
  final int athleteAge;

  const StepSleep({
    super.key,
    required this.athleteName,
    required this.athleteAge,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final bloc = context.read<DailyLogBloc>();
    final rec = DateHelpers.sleepRecommendationByAge(athleteAge);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            t.translate('sleep_title', params: {'name': athleteName}),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BlocBuilder<DailyLogBloc, DailyLogState>(
            builder: (context, state) {
              final hours = state.sleepHours ?? rec.$1;
              final isLow = hours < rec.$1;
              return Column(
                children: [
                  Text(
                    '${hours.toStringAsFixed(1)} ${t.translate('hours')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: isLow ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: hours,
                    min: 0,
                    max: 16,
                    divisions: 32,
                    onChanged: (v) {
                      bloc.add(UpdateSleepStep(
                        hours: v,
                        quality: state.sleepQuality ?? SleepQuality.good,
                      ));
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLow ? AppColors.danger.withValues(alpha:  0.1) : AppColors.success.withValues(alpha:  0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.translate('sleep_recommendation', params: {
                        'min': '${rec.$1}',
                        'max': '${rec.$2}',
                        'age': '$athleteAge',
                      }),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLow ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isLow) ...[
                    const SizedBox(height: 8),
                    Text(
                      t.translate('low_sleep_warning', params: {
                        'name': athleteName,
                        'recommended': '${rec.$1}',
                      }),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    t.translate('sleep_quality'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _qualityButton(SleepQuality.poor, '😴', t.translate('poor')),
                      _qualityButton(SleepQuality.fair, '😐', t.translate('fair')),
                      _qualityButton(SleepQuality.good, '😊', t.translate('good')),
                      _qualityButton(SleepQuality.excellent, '🌟', t.translate('excellent')),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _qualityButton(SleepQuality quality, String emoji, String label) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        final isSelected = state.sleepQuality == quality;
        return Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: () {
              context.read<DailyLogBloc>().add(UpdateSleepStep(
                hours: state.sleepHours ?? 8,
                quality: quality,
              ));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withValues(alpha:  0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
