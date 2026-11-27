import 'package:flutter/material.dart';

/// Performance-tuned artwork widget that decodes remote images at bounded
/// target pixel dimensions, prevents rebuild flicker with [gaplessPlayback],
/// and softly fades in on first load.
class CachedArtworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedArtworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return errorBuilder?.call(context, 'Empty image URL', null) ??
          Container(
            width: width,
            height: height,
            color: Colors.white12,
            child: const Icon(Icons.music_note_rounded, color: Colors.white38),
          );
    }

    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: errorBuilder ??
          (_, __, ___) => Container(
                width: width,
                height: height,
                color: Colors.white12,
                child: const Icon(Icons.music_note_rounded, color: Colors.white38),
              ),
    );
  }
}
