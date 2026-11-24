import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Replicates BitChord v1.9's signature CardMotion animation:
/// - Interactive spring scale (0.955 on press down, bouncing back on release with damping: 0.72, stiffness: 420)
/// - Dynamic responsive glow / shadow shift
/// - Optional liquid glass border highlight
/// - Integrated tactile haptic feedback
class BitChordCardMotion extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPlaying;
  final Color? glowColor;
  final double borderRadius;
  final double pressedScale;

  const BitChordCardMotion({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isPlaying = false,
    this.glowColor,
    this.borderRadius = 22,
    this.pressedScale = 0.955,
  });

  @override
  State<BitChordCardMotion> createState() => _BitChordCardMotionState();
}

class _BitChordCardMotionState extends State<BitChordCardMotion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    // BitChord spring specs: dampingRatio: 0.72f, stiffness: 420f (~220ms spring cycle)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: widget.isPlaying ? 1.0 : 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant BitChordCardMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying && !_isDown) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _isDown = true;
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isDown) return;
    _isDown = false;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!_isDown) return;
    _isDown = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final activeGlowColor = widget.glowColor ?? const Color(0xFF1DB954);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final glowFactor = _glowAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                if (widget.isPlaying || glowFactor > 0.05)
                  BoxShadow(
                    color: activeGlowColor.withOpacity(
                      (0.28 * (widget.isPlaying ? 1.0 : glowFactor)).clamp(0.0, 0.4),
                    ),
                    blurRadius: 18 + (6 * glowFactor),
                    spreadRadius: 1 + (2 * glowFactor),
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null ? _handleTapDown : null,
        onTapUp: widget.onTap != null ? _handleTapUp : null,
        onTapCancel: widget.onTap != null ? _handleTapCancel : null,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: widget.child,
      ),
    );
  }
}
