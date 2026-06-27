import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/core/widgets/glass_container.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

class AthleteCard extends StatefulWidget {
  final AthleteEntity athlete;
  final VoidCallback? onTap;
  final bool isSelected;
  final int? stressScore;

  const AthleteCard({
    super.key,
    required this.athlete,
    this.onTap,
    this.isSelected = false,
    this.stressScore,
  });

  @override
  State<AthleteCard> createState() => _AthleteCardState();
}

class _AthleteCardState extends State<AthleteCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final stressColor = widget.stressScore != null ? AppColors.stressColor(widget.stressScore!) : AppColors.textMuted;
    final scale = _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0);

    return Semantics(
      button: true,
      label: widget.athlete.name,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: GlassContainer(
              width: 110,
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              border: Border.all(
                color: widget.isSelected ? AppColors.accent : Colors.white.withAlpha(40),
                width: widget.isSelected ? 2 : 1,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.background.withAlpha(100),
                        backgroundImage: widget.athlete.photoUrl != null
                            ? CachedNetworkImageProvider(widget.athlete.photoUrl!)
                            : null,
                        child: widget.athlete.photoUrl == null
                            ? Text(
                                widget.athlete.name[0],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              )
                            : null,
                      ),
                      if (widget.stressScore != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: stressColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.athlete.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.primary,
                    ),
                  ),
                  Text(
                    '${DateHelpers.calculateAge(widget.athlete.birthDate)} سنة',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _levelLabel(widget.athlete.swimLevel),
                      style: const TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _levelLabel(SwimLevel level) {
    switch (level.name) {
      case 'beginner':
        return 'مبتدئ';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'متقدم';
      case 'competitive':
        return 'تنافسي';
      default:
        return 'مبتدئ';
    }
  }
}
