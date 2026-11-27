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
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeColorService(),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final cardColor = color ?? (p.isDark ? p.surface.withOpacity(0.86) : p.surface.withOpacity(0.94));
        final cardBorder = border ??
            Border.all(
              color: p.isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.65),
              width: 1.0,
            );
        final cardShadow = [
          BoxShadow(
            color: p.shadowDark.withOpacity(p.isDark ? 0.55 : 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (!p.isDark)
            BoxShadow(
              color: p.shadowLight,
              blurRadius: 8,
              offset: const Offset(-2, -2),
            ),
        ];

        final innerMaterial = Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        );

        Widget content = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cardColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withOpacity(0.98),
                p.background.withOpacity(p.isDark ? 0.88 : 0.82),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: cardBorder,
            boxShadow: cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: enableBlur
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: innerMaterial,
                  )
                : innerMaterial,
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
