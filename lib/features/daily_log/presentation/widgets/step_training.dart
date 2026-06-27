import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

class StepTraining extends StatelessWidget {
  final String athleteName;

  const StepTraining({super.key, required this.athleteName});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              t.translate('training_title', params: {'name': athleteName}),
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
                final training = state.training ?? const TrainingData();
                return Column(
                  children: [
                    _buildTrainedToggle(training, t),
                    if (training.trained) ...[
                      const SizedBox(height: 24),
                      _buildTrainingTypeSelector(training, t),
                      const SizedBox(height: 24),
                      _buildDurationSlider(training, t),
                      const SizedBox(height: 24),
                      _buildDistanceField(training, t),
                      const SizedBox(height: 24),
                      _buildRPESlider(training, t),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainedToggle(TrainingData training, AppLocalizations t) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'تم التمرين',
                child: InkWell(
                  onTap: () {
                    context.read<DailyLogBloc>().add(UpdateTrainingStep(
                      data: training.copyWith(trained: true),
                    ));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: training.trained
                          ? AppColors.success.withValues(alpha:  0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: training.trained ? AppColors.success : AppColors.border,
                        width: training.trained ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.fitness_center, size: 36, color: AppColors.success),
                        const SizedBox(height: 8),
                        Text(
                          t.translate('trained_yes'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Semantics(
                button: true,
                label: 'لم يتم التمرين',
                child: InkWell(
                  onTap: () {
                    context.read<DailyLogBloc>().add(UpdateTrainingStep(
                      data: training.copyWith(trained: false, clearDuration: true, clearType: true, clearRpe: true, clearDistance: true),
                    ));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: !training.trained
                          ? AppColors.textMuted.withValues(alpha:  0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !training.trained ? AppColors.textMuted : AppColors.border,
                        width: !training.trained ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.hotel, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          t.translate('trained_no'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrainingTypeSelector(TrainingData training, AppLocalizations t) {
    final types = [
      (TrainingType.technique, t.translate('technique'), Icons.handyman),
      (TrainingType.endurance, t.translate('endurance'), Icons.directions_run),
      (TrainingType.sprint, t.translate('sprint'), Icons.bolt),
      (TrainingType.dryland, t.translate('dryland'), Icons.fitness_center),
      (TrainingType.competition, t.translate('competition'), Icons.emoji_events),
      (TrainingType.rest, t.translate('rest'), Icons.hotel),
    ];
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.translate('training_type'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                final isSelected = training.type == t.$1;
                return Semantics(
                  button: true,
                  label: t.$2,
                  child: InkWell(
                    onTap: () {
                      context.read<DailyLogBloc>().add(UpdateTrainingStep(
                        data: training.copyWith(type: t.$1),
                      ));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withValues(alpha:  0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.$3, size: 18, color: isSelected ? AppColors.accent : AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(t.$2, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationSlider(TrainingData training, AppLocalizations t) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        final minutes = training.durationMinutes ?? 60;
        return Column(
          children: [
            Text(t.translate('training_duration'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              '$minutes ${t.translate('minutes')}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            Slider(
              value: minutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 33,
              label: '$minutes ${t.translate('minutes')}',
              onChanged: (v) {
                context.read<DailyLogBloc>().add(UpdateTrainingStep(
                  data: training.copyWith(durationMinutes: v.round()),
                ));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDistanceField(TrainingData training, AppLocalizations t) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: t.translate('distance_hint'),
            prefixIcon: const Icon(Icons.straighten, color: AppColors.accent),
            suffixText: t.translate('m_suffix'),
          ),
          onChanged: (v) {
            final distance = int.tryParse(v);
            context.read<DailyLogBloc>().add(UpdateTrainingStep(
              data: training.copyWith(distanceMeters: distance),
            ));
          },
        );
      },
    );
  }

  Widget _buildRPESlider(TrainingData training, AppLocalizations t) {
    final rpeLabels = {
      1: t.translate('rpe_very_light'),
      2: t.translate('rpe_light'),
      3: t.translate('rpe_light'),
      4: t.translate('rpe_moderate'),
      5: t.translate('rpe_moderate'),
      6: t.translate('rpe_moderate'),
      7: t.translate('rpe_hard'),
      8: t.translate('rpe_hard'),
      9: t.translate('rpe_very_hard'),
      10: t.translate('rpe_very_hard'),
    };
    final rpeColors = {
      1: AppColors.success,
      2: AppColors.success,
      3: AppColors.success,
      4: AppColors.warning,
      5: AppColors.warning,
      6: AppColors.warning,
      7: AppColors.danger,
      8: AppColors.danger,
      9: const Color(0xFF7F1D1D),
      10: const Color(0xFF7F1D1D),
    };

    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        final rpe = training.rpe ?? 5;
        final color = rpeColors[rpe] ?? AppColors.warning;
        return Column(
          children: [
            Text(t.translate('rpe'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha:  0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rpeLabels[rpe] ?? '',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$rpe',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color),
            ),
            Slider(
              value: rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: color,
              onChanged: (v) {
                context.read<DailyLogBloc>().add(UpdateTrainingStep(
                  data: training.copyWith(rpe: v.round()),
                ));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                Text('10', style: TextStyle(color: const Color(0xFF7F1D1D), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    );
  }
}
