import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../theme/app_theme.dart';

class SourceBadge extends StatelessWidget {
  final MusicSource source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    String label;
    IconData icon;

    switch (source) {
      case MusicSource.youtube:
        bg = const Color(0xFFEF4444);
        label = 'YouTube Music';
        icon = Icons.play_arrow_rounded;
        break;
      case MusicSource.spotify:
        bg = const Color(0xFF10B981);
        label = 'Spotify';
        icon = Icons.graphic_eq_rounded;
        break;
      case MusicSource.jiosaavn:
        bg = const Color(0xFF06B6D4);
        label = 'JioSaavn';
        icon = Icons.library_music_rounded;
        break;
      case MusicSource.local:
        bg = AppTheme.primary;
        label = 'Lossless Storage';
        icon = Icons.folder_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: bg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class AudioQualityBadge extends StatelessWidget {
  final bool isLossless;
  final bool isDolbyAtmos;

  const AudioQualityBadge({
    super.key,
    this.isLossless = true,
    this.isDolbyAtmos = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLossless)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.5)),
            ),
            child: const Text(
              'LOSSLESS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        if (isDolbyAtmos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
            ),
            child: const Text(
              'DOLBY ATMOS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentPink,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
