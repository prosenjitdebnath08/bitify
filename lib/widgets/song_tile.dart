import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../theme/app_theme.dart';
import 'source_badge.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLikeTap;
  final bool isLiked;

  const SongTile({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.isPlaying = false,
    required this.onTap,
    this.onLikeTap,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.coverUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.surfaceElevated,
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
            ),
            if (isCurrent && isPlaying)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.equalizer_rounded,
                  color: AppTheme.secondary,
                  size: 26,
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SourceBadge(source: song.source),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onLikeTap != null)
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? AppTheme.accentPink : Colors.white38,
                  size: 20,
                ),
                onPressed: onLikeTap,
              ),
            Text(
              song.formattedDuration,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
              color: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$val: "${song.title}"'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Add to Playlist',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Add to Playlist'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Play Next',
                  child: Row(
                    children: [
                      Icon(Icons.queue_music_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Play Next'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Download Offline',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Download Lossless (FLAC)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Share Song',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Share Bitify Link'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
