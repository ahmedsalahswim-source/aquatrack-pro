import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/features/athlete/presentation/widgets/athlete_card.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/add_athlete_page.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/athlete_detail_page.dart';

class AthletesTab extends StatefulWidget {
  final String parentId;

  const AthletesTab({super.key, required this.parentId});

  @override
  State<AthletesTab> createState() => _AthletesTabState();
}

class _AthletesTabState extends State<AthletesTab> {
  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AthleteBloc, AthleteState>(
        builder: (context, state) {
          if (state is AthleteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AthletesLoaded) {
            if (state.athletes.isEmpty) {
              return _buildEmptyState(context, t);
            }
            return RefreshIndicator(
              onRefresh: () {
                final bloc = context.read<AthleteBloc>();
                bloc.add(WatchAthletesEvent(parentId: widget.parentId));
                return bloc.stream.firstWhere((s) => s is AthletesLoaded || s is AthleteError);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: state.athletes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${t.translate('athletes')} (${state.athletes.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  final athlete = state.athletes[index - 1];
                  final isSelected = state.selectedAthlete?.id == athlete.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      button: true,
                      label: 'اختيار رياضي',
                      child: InkWell(
                        onTap: () {
                          context.read<AthleteBloc>().add(SelectAthleteEvent(athlete: athlete));
                        },
                        onLongPress: () => _showAthleteActions(context, t, athlete),
                        borderRadius: BorderRadius.circular(8),
                        child: AthleteCard(
                          athlete: athlete,
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          if (state is AthleteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AthleteBloc>().add(WatchAthletesEvent(parentId: widget.parentId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(t.translate('retry')),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState(context, t);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddAthletePage(parentId: widget.parentId),
            ),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add),
        label: Text(t.translate('add_athlete')),
      ),
    );
  }

  void _showAthleteActions(BuildContext context, AppLocalizations t, AthleteEntity athlete) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(athlete.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outlined, color: AppColors.accent),
                title: Text(t.translate('view_profile')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AthleteDetailPage(athlete: athlete),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.accent),
                title: Text(t.translate('edit_data')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddAthletePage(
                        parentId: widget.parentId,
                        existingAthlete: athlete,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(t.translate('delete_athlete'), style: const TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, t, athlete);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations t, AthleteEntity athlete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('confirm_delete_title')),
        content: Text(t.translate('confirm_delete_body', params: {'name': athlete.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AthleteBloc>().add(DeleteAthleteEvent(athleteId: athlete.id, parentId: athlete.parentId));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(t.translate('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            t.translate('no_athletes_yet'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('add_athlete_to_start'),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
