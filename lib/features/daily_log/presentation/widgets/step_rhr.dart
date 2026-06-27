import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/constants/app_constants.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

class StepRHR extends StatelessWidget {
  final String athleteName;
  final int athleteAge;

  const StepRHR({
    super.key,
    required this.athleteName,
    required this.athleteAge,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    final bloc = context.read<DailyLogBloc>();
    final hrRange = DateHelpers.hrNormalRangeByAge(athleteAge);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            t.translate('resting_hr_title', params: {'name': athleteName}),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('resting_hr_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.translate('normal_range', params: {
                'age': '$athleteAge',
                'min': '${hrRange.$1}',
                'max': '${hrRange.$2}',
              }),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),
          BlocBuilder<DailyLogBloc, DailyLogState>(
            builder: (context, state) {
              final hr = state.restingHR ?? 70;
              return Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha:  0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha:  0.3),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$hr',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'BPM',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _roundButton(Icons.remove, () {
                        if (hr > AppConstants.minRestingHR) {
                          bloc.add(UpdateRHRStep(value: hr - 1));
                        }
                      }),
                      const SizedBox(width: 40),
                      _roundButton(Icons.add, () {
                        if (hr < AppConstants.maxRestingHR) {
                          bloc.add(UpdateRHRStep(value: hr + 1));
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick number pad
                  _buildQuickPad(context, bloc, hr),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: 'تسجيل',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha:  0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildQuickPad(BuildContext context, DailyLogBloc bloc, int hr) {
    final numbers = [
      [60, 65, 70],
      [75, 80, 85],
      [90, 95, 100],
    ];
    return Column(
      children: numbers.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((n) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              label: '$n',
              child: InkWell(
                onTap: () => bloc.add(UpdateRHRStep(value: n)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hr == n ? AppColors.accent.withValues(alpha:  0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hr == n ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontWeight: hr == n ? FontWeight.w700 : FontWeight.w500,
                        color: hr == n ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      )).toList(),
    );
  }
}
