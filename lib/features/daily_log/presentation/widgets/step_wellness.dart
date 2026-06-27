import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

class StepWellness extends StatelessWidget {
  final String athleteName;

  const StepWellness({super.key, required this.athleteName});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            t.translate('wellness_title', params: {'name': athleteName}),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('wellness_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          BlocBuilder<DailyLogBloc, DailyLogState>(
            builder: (context, state) {
              return Column(
                children: List.generate(5, (index) {
                  final score = 5 - index;
                  final isSelected = state.wellnessScore == score;
                  final emojis = ['🌟', '😊', '🙂', '😐', '😴'];
                  final labels = [
                    t.translate('wellness_detail_5'),
                    t.translate('wellness_detail_4'),
                    t.translate('wellness_detail_3'),
                    t.translate('wellness_detail_2'),
                    t.translate('wellness_detail_1'),
                  ];
                  final colors = [
                    AppColors.success,
                    AppColors.success.withValues(alpha:  0.7),
                    AppColors.warning,
                    AppColors.danger.withValues(alpha:  0.7),
                    AppColors.danger,
                  ];

                  return Semantics(
                    button: true,
                    label: labels[index],
                    child: InkWell(
                      onTap: () {
                        context.read<DailyLogBloc>().add(
                          UpdateWellnessStep(score: score),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors[index].withValues(alpha:  0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colors[index] : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(emojis[index], style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? colors[index] : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: colors[index], size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('wellness_skip_hint'),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
