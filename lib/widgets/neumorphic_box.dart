import 'package:flutter/material.dart';
import '../services/theme_color_service.dart';

class NeumorphicBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isCircle;
  final bool hasGlow;
  final Color? glowColor;
  final Color? overrideColor;
  final VoidCallback? onTap;

  const NeumorphicBox({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.isCircle = false,
    this.hasGlow = false,
    this.glowColor,
    this.overrideColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeColorService(),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final baseColor = overrideColor ?? p.surface;

        final decoration = BoxDecoration(
          color: baseColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          boxShadow: [
            // Dark bottom-right shadow
            BoxShadow(
              color: p.shadowDark.withOpacity(0.85),
              offset: const Offset(5, 6),
              blurRadius: 10,
              spreadRadius: 0,
            ),
            // Light top-left highlight
            BoxShadow(
              color: p.shadowLight,
              offset: const Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
            // Optional vibrant ambient glow
            if (hasGlow)
              BoxShadow(
                color: glowColor ?? p.glow,
                offset: const Offset(0, 4),
                blurRadius: 18,
                spreadRadius: 2,
              ),
          ],
          border: Border.all(
            color: p.isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.60),
            width: p.isDark ? 1.0 : 1.2,
          ),
        );

        Widget box = Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: decoration,
          child: child,
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: box,
          );
        }

        return box;
      },
    );
  }
}
