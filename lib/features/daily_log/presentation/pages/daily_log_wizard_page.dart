import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_rhr.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_sleep.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_wellness.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_nutrition.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_training.dart';

class DailyLogWizardPage extends StatefulWidget {
  final String athleteId;
  final String athleteName;
  final int athleteAge;
  final int? baselineHR;

  const DailyLogWizardPage({
    super.key,
    required this.athleteId,
    required this.athleteName,
    this.athleteAge = 10,
    this.baselineHR,
  });

  @override
  State<DailyLogWizardPage> createState() => _DailyLogWizardPageState();
}

class _DailyLogWizardPageState extends State<DailyLogWizardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DailyLogBloc>().add(InitLogEvent(
      athleteId: widget.athleteId,
      athleteName: widget.athleteName,
      athleteAge: widget.athleteAge,
      baselineHR: widget.baselineHR,
    ));
    context.read<DailyLogBloc>().add(CheckExistingLogEvent(
      athleteId: widget.athleteId,
    ));
  }

  Future<bool> _onWillPop() async {
    final state = context.read<DailyLogBloc>().state;
    if (state.currentStep == 0) {
      final discard = await _showDiscardDialog();
      return discard;
    }
    return false;
  }

  Future<bool> _showDiscardDialog() async {
    final t = context.read<AppLocalizations>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('discard_title')),
        content: Text(t.translate('discard_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.translate('keep_editing')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.translate('discard_confirm'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onClose() {
    final state = context.read<DailyLogBloc>().state;
    if (state.currentStep > 0) {
      context.read<DailyLogBloc>().add(const PreviousStepEvent());
    } else {
      final navigator = Navigator.of(context);
      _onWillPop().then((discard) {
        if (discard) navigator.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _onWillPop();
        if (discard) navigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('daily_log')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onClose,
        ),
      ),
      body: BlocConsumer<DailyLogBloc, DailyLogState>(
        listener: (context, state) {
          if (state.isSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(state.isExistingLog ? t.translate('log_edit_success') : t.translate('log_success')),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
            context.read<DailyLogBloc>().add(const ResetLogEvent());
            Navigator.of(context).pop(true);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildProgressBar(state.currentStep, t),
              if (state.isExistingLog)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.warning.withValues(alpha:  0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        t.translate('existing_log_warning'),
                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: state.currentStep,
                  children: [
                    StepRHR(athleteName: widget.athleteName, athleteAge: widget.athleteAge),
                    StepSleep(athleteName: widget.athleteName, athleteAge: widget.athleteAge),
                    StepWellness(athleteName: widget.athleteName),
                    StepNutrition(athleteName: widget.athleteName),
                    StepTraining(athleteName: widget.athleteName),
                  ],
                ),
              ),
              _buildBottomBar(state, t),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, AppLocalizations t) {
    final steps = [
      t.translate('step_rhr_label'),
      t.translate('step_sleep_label'),
      t.translate('step_wellness_label'),
      t.translate('step_nutrition_label'),
      t.translate('step_training_label'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${t.translate('step')} ${currentStep + 1} ${t.translate('of')} 5',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                steps[currentStep],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 5,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final isActive = i <= currentStep;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.border,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(DailyLogState state, AppLocalizations t) {
    final isLastStep = state.currentStep == 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              TextButton(
                onPressed: () => context.read<DailyLogBloc>().add(const PreviousStepEvent()),
                child: Text(t.translate('previous')),
              )
            else
              TextButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  _onWillPop().then((discard) {
                    if (discard) navigator.pop();
                  });
                },
                child: Text(t.translate('cancel')),
              ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.isSaving
                    ? null
                    : () {
                        if (isLastStep) {
                          context.read<DailyLogBloc>().add(const SaveLogEvent());
                        } else {
                          context.read<DailyLogBloc>().add(const NextStepEvent());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLastStep ? '💾 ${t.translate('save')}' : t.translate('next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
