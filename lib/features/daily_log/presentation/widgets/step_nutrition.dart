import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

enum MealType { breakfast, lunch, dinner, snack }

class StepNutrition extends StatelessWidget {
  final String athleteName;

  const StepNutrition({super.key, required this.athleteName});

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
            t.translate('nutrition_title', params: {'name': athleteName}),
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
              final nutrition = state.nutrition ?? const NutritionData();
              return Column(
                children: [
                  _buildMealToggles(nutrition, t),
                  const SizedBox(height: 24),
                  _buildWaterSlider(nutrition, t),
                  const SizedBox(height: 24),
                  _buildProteinToggle(nutrition, t),
                  const SizedBox(height: 16),
                  _buildMealProgress(nutrition, t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealToggles(NutritionData nutrition, AppLocalizations t) {
    final meals = <(String, bool, IconData, MealType)>[
      (t.translate('breakfast'), nutrition.breakfast, Icons.wb_sunny_outlined, MealType.breakfast),
      (t.translate('lunch'), nutrition.lunch, Icons.wb_cloudy_outlined, MealType.lunch),
      (t.translate('dinner'), nutrition.dinner, Icons.nights_stay_outlined, MealType.dinner),
      (t.translate('snack'), nutrition.snack, Icons.cookie_outlined, MealType.snack),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: meals.map((m) {
        return BlocBuilder<DailyLogBloc, DailyLogState>(
          builder: (context, state) {
            return Semantics(
              button: true,
              label: m.$1,
              child: InkWell(
                onTap: () {
                  final current = state.nutrition ?? const NutritionData();
                  NutritionData updated;
                  switch (m.$4) {
                    case MealType.breakfast:
                      updated = current.copyWith(breakfast: !current.breakfast);
                    case MealType.lunch:
                      updated = current.copyWith(lunch: !current.lunch);
                    case MealType.dinner:
                      updated = current.copyWith(dinner: !current.dinner);
                    case MealType.snack:
                      updated = current.copyWith(snack: !current.snack);
                  }
                  context.read<DailyLogBloc>().add(UpdateNutritionStep(data: updated));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: m.$2 ? AppColors.accent.withValues(alpha:  0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: m.$2 ? AppColors.accent : AppColors.border,
                      width: m.$2 ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.$3, color: m.$2 ? AppColors.accent : AppColors.textMuted, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        m.$1,
                        style: TextStyle(
                          fontWeight: m.$2 ? FontWeight.w700 : FontWeight.w500,
                          color: m.$2 ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildWaterSlider(NutritionData nutrition, AppLocalizations t) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        final water = nutrition.hydrationLiters;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop, color: AppColors.accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${water.toStringAsFixed(2)} ${t.translate('liters')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: water,
              min: 0,
              max: 3,
              divisions: 12,
              onChanged: (v) {
                context.read<DailyLogBloc>().add(UpdateNutritionStep(
                  data: nutrition.copyWith(hydrationLiters: v),
                ));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProteinToggle(NutritionData nutrition, AppLocalizations t) {
    return BlocBuilder<DailyLogBloc, DailyLogState>(
      builder: (context, state) {
        return Semantics(
          button: true,
          label: 'تبديل حالة البروتين',
          child: InkWell(
            onTap: () {
              context.read<DailyLogBloc>().add(UpdateNutritionStep(
                data: nutrition.copyWith(proteinSufficient: !nutrition.proteinSufficient),
              ));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: nutrition.proteinSufficient
                    ? AppColors.success.withValues(alpha:  0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: nutrition.proteinSufficient ? AppColors.success : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    nutrition.proteinSufficient ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: nutrition.proteinSufficient ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.translate('protein_question'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                      nutrition.proteinSufficient ? t.translate('yes_label') : t.translate('no_label'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: nutrition.proteinSufficient ? AppColors.success : AppColors.textMuted,
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

  Widget _buildMealProgress(NutritionData nutrition, AppLocalizations t) {
    final pct = nutrition.mealsPercentage;
    return Column(
      children: [
        Text(
          t.translate('meals_completed'),
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 75 ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.translate('meals_count', params: {'count': '${nutrition.mealsCount}'}),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
