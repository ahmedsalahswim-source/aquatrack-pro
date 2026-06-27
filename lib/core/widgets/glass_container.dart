import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurX;
  final double blurY;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Border? border;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurX = 10.0,
    this.blurY = 10.0,
    this.color,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).cardColor.withAlpha(40);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorder = border ?? Border.all(
      color: isDark ? Colors.white.withAlpha(20) : Colors.white.withAlpha(60),
      width: 1.5,
    );

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: defaultBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 10),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
