import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../services/theme_color_service.dart';
import '../theme/app_theme.dart';
import 'source_badge.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLikeTap;
  final bool isLiked;
  /// When true, displays an explicit delete icon button in the trailing row.
  final bool showDeleteOption;
  /// Called when the user confirms deletion.
  final VoidCallback? onDelete;

  const SongTile({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.isPlaying = false,
    required this.onTap,
    this.onLikeTap,
    this.isLiked = false,
    this.showDeleteOption = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([DownloadService(), ThemeColorService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final ds = DownloadService();
        final downloading = ds.isDownloading(song.id);
        final downloaded = ds.isDownloaded(song.id);
        final prog = ds.progress(song.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? p.primary.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isCurrent
                ? Border.all(color: p.primary.withOpacity(0.35), width: 1.2)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: onTap,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            color: Colors.white24,
                            child: const Icon(Icons.music_note,
                                color: Colors.white54),
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
                          child: Icon(
                            Icons.equalizer_rounded,
                            color: p.accent,
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
                      color: isCurrent
                          ? p.primary
                          : p.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w600,
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
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SourceBadge(source: song.source),
                        if (downloaded) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_done_rounded,
                                    size: 11, color: p.primary),
                                const SizedBox(width: 2),
                                Text(
                                  '256k',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: p.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onLikeTap != null)
                        IconButton(
                          icon: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked
                                ? const Color(0xFFEF4444)
                                : p.textSecondary,
                            size: 20,
                          ),
                          onPressed: onLikeTap,
                        ),
                      Text(
                        song.formattedDuration,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      // If shown in downloads tab, show direct Delete button
                      if (showDeleteOption)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 21),
                          tooltip: 'Delete Download',
                          onPressed: () => _confirmDelete(context),
                        )
                      else ...[
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              color: Colors.white38, size: 20),
                          color: AppTheme.surfaceElevated,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          onSelected: (val) {
                            switch (val) {
                              case 'Download':
                                if (!downloaded && !downloading) {
                                  DownloadService().startDownload(
                                    song,
                                    onComplete: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '✓ "${song.title}" downloaded! Available in Offline Vault.'),
                                          backgroundColor: const Color(0xFF1E2139),
                                        ),
                                      );
                                    },
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Downloading "${song.title}" in 256kbps…'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                                break;
                              case 'Delete':
                                _confirmDelete(context);
                                break;
                              default:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$val: "${song.title}"'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Add to Playlist',
                              child: Row(children: [
                                Icon(Icons.playlist_add_rounded,
                                    size: 18, color: Colors.white70),
                                SizedBox(width: 10),
                                Text('Add to Playlist'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'Play Next',
                              child: Row(children: [
                                Icon(Icons.queue_music_rounded,
                                    size: 18, color: Colors.white70),
                                SizedBox(width: 10),
                                Text('Play Next'),
                              ]),
                            ),
                            if (downloaded)
                              const PopupMenuItem(
                                value: 'Delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.redAccent),
                                  SizedBox(width: 10),
                                  Text('Delete Download',
                                      style: TextStyle(color: Colors.redAccent)),
                                ]),
                              )
                            else
                              PopupMenuItem(
                                value: 'Download',
                                child: Row(children: [
                                  Icon(
                                    downloading
                                        ? Icons.downloading_rounded
                                        : Icons.download_rounded,
                                    size: 18,
                                    color: downloading
                                        ? AppTheme.secondary
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    downloading
                                        ? 'Downloading…'
                                        : 'Download (256kbps)',
                                  ),
                                ]),
                              ),
                            const PopupMenuItem(
                              value: 'Share Song',
                              child: Row(children: [
                                Icon(Icons.share_rounded,
                                    size: 18, color: Colors.white70),
                                SizedBox(width: 10),
                                Text('Share Bitify Link'),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Progress bar shown while downloading
                if (downloading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: prog,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.secondary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading in 256kbps… ${(prog * 100).toInt()}%',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${((prog * 6.8)).toStringAsFixed(1)} MB / 6.8 MB',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Download',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${song.title}" from your offline downloads vault?',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DownloadService().deleteSong(song.id);
              onDelete?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${song.title}" removed from downloads'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
