import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_color_service.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeColorService(),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final cardColor = color ?? (p.isDark ? p.surface.withOpacity(0.70) : p.surface.withOpacity(0.88));
        final cardBorder = border ??
            Border.all(
              color: p.isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.65),
              width: 1.0,
            );
        final cardShadow = [
          BoxShadow(
            color: p.shadowDark.withOpacity(p.isDark ? 0.65 : 0.40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (!p.isDark)
            BoxShadow(
              color: p.shadowLight,
              blurRadius: 10,
              offset: const Offset(-2, -2),
            ),
        ];

        Widget content = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(radius),
            border: cardBorder,
            boxShadow: cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        );

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: p.primary.withOpacity(0.15),
            highlightColor: Colors.transparent,
            child: content,
          );
        }

        return content;
      },
    );
  }
}
