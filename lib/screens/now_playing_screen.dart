import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/source_badge.dart';
import 'equalizer_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  final MusicPlayerState state;

  const NowPlayingScreen({super.key, required this.state});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;
  bool _isDraggingSeek = false;
  double _dragSeekValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final song = widget.state.currentSong;
        if (song == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: Text('No song selected')),
          );
        }

        final duration = widget.state.durationSeconds > 0
            ? widget.state.durationSeconds
            : (song.durationSeconds > 0 ? song.durationSeconds : 180);
        final currentSeconds = widget.state.positionSeconds.clamp(0, duration);
        final progress = (currentSeconds / duration).clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -180) {
              widget.state.next();
            } else if (details.primaryVelocity! > 180) {
              widget.state.previous();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              // Dynamic blurred background art
              Positioned.fill(
                child: Image.network(
                  song.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E1B4B)),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.55),
                          AppTheme.background.withOpacity(0.85),
                          AppTheme.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // Foreground content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Top header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                            color: Colors.white,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Column(
                            children: [
                              const Text(
                                'PLAYING FROM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.album,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz_rounded, size: 26),
                            color: Colors.white,
                            onPressed: () => _showMoreSheet(context, song),
                          ),
                        ],
                      ),

                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity == null) return;
                            if (details.primaryVelocity! < -200) {
                              widget.state.next();
                            } else if (details.primaryVelocity! > 200) {
                              widget.state.previous();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: _showLyrics
                              ? _buildLyricsView(song, currentSeconds)
                              : Center(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size = (constraints.maxHeight * 0.90).clamp(180.0, 310.0);
                                      return Container(
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primary.withOpacity(0.35),
                                              blurRadius: 32,
                                              offset: const Offset(0, 12),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.6),
                                              blurRadius: 24,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Image.network(
                                            song.coverUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: AppTheme.surfaceElevated,
                                              child: const Icon(Icons.music_note, size: 80, color: Colors.white38),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),

                      // Source & Quality Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SourceBadge(source: song.source),
                          AudioQualityBadge(
                            isLossless: song.isLossless,
                            isDolbyAtmos: song.isDolbyAtmos,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title & Artist & Like
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              widget.state.isSongLiked(song.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: widget.state.isSongLiked(song.id)
                                  ? AppTheme.accentPink
                                  : Colors.white54,
                              size: 28,
                            ),
                            onPressed: () => widget.state.toggleLike(song.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Custom Seekbar with Smooth Scrubbing
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.16),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _isDraggingSeek ? _dragSeekValue : progress,
                          onChangeStart: (val) {
                            setState(() {
                              _isDraggingSeek = true;
                              _dragSeekValue = val;
                            });
                          },
                          onChanged: (val) {
                            setState(() {
                              _dragSeekValue = val;
                            });
                          },
                          onChangeEnd: (val) {
                            setState(() {
                              _isDraggingSeek = false;
                            });
                            widget.state.seekTo((val * duration).toInt());
                          },
                        ),
                      ),

                      // Time Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatSeconds(_isDraggingSeek
                                  ? (_dragSeekValue * duration).toInt()
                                  : currentSeconds),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatSeconds(duration),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: widget.state.isShuffle
                                  ? AppTheme.secondary
                                  : Colors.white38,
                              size: 24,
                            ),
                            onPressed: widget.state.toggleShuffle,
                          ),
                          // Prev
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            onPressed: widget.state.previous,
                          ),
                          // Play/Pause
                          GestureDetector(
                            onTap: widget.state.togglePlayPause,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            onPressed: widget.state.next,
                          ),
                          // Repeat
                          IconButton(
                            icon: Icon(
                              widget.state.repeatMode == BitifyRepeatMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: widget.state.repeatMode != BitifyRepeatMode.off
                                  ? AppTheme.secondary
                                  : Colors.white38,
                              size: 24,
                            ),
                            onPressed: widget.state.toggleRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Bottom Utilities bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lyrics toggle
                          IconButton(
                            icon: Icon(
                              Icons.subtitles_rounded,
                              color: _showLyrics ? AppTheme.secondary : Colors.white60,
                            ),
                            tooltip: 'Live Synced Lyrics',
                            onPressed: () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                              });
                            },
                          ),
                          // Equalizer
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Colors.white60),
                            tooltip: '10-Band Equalizer',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EqualizerScreen(state: widget.state),
                                ),
                              );
                            },
                          ),
                          // Sleep Timer
                          IconButton(
                            icon: Icon(
                              Icons.bedtime_rounded,
                              color: widget.state.sleepTimerMinutes != null
                                  ? AppTheme.accentPink
                                  : Colors.white60,
                            ),
                            tooltip: 'Sleep Timer',
                            onPressed: () => _showSleepTimerDialog(context),
                          ),
                          // Up Next Queue
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded, color: Colors.white60),
                            tooltip: 'Up Next Queue',
                            onPressed: () => _showQueueSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _buildLyricsView(Song song, int currentSeconds) {
    if (song.lyrics.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: const Text(
          'No lyrics available for this song',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
        ),
      );
    }

    return Container(
      height: 290,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: song.lyrics.length,
        itemBuilder: (context, i) {
          final line = song.lyrics[i];
          final isHighlighted = currentSeconds >= line.second &&
              (i == song.lyrics.length - 1 || currentSeconds < song.lyrics[i + 1].second);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isHighlighted ? 22 : 16,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
                color: isHighlighted ? Colors.white : Colors.white30,
                height: 1.4,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMoreSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.album_rounded, color: AppTheme.primaryLight),
              title: Text('View Album: ${song.album}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppTheme.secondary),
              title: Text('View Artist: ${song.artist}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white70),
              title: const Text('Download'),
              subtitle: const Text('256kbps High Quality Audio', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading "${song.title}" in 256kbps...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.white70),
              title: const Text('Share Song Link'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131522),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final queue = widget.state.queue;
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Up Next (${queue.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.shuffle, size: 16, color: AppTheme.secondary),
                        label: const Text('Shuffle Queue', style: TextStyle(color: AppTheme.secondary)),
                        onPressed: widget.state.toggleShuffle,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    itemCount: queue.length,
                    onReorder: widget.state.reorderQueue,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = item.id == widget.state.currentSong?.id;

                      return ListTile(
                        key: ValueKey(item.id),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.coverUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? AppTheme.primaryLight : Colors.white,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          item.artist,
                          maxLines: 1,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.drag_handle_rounded, color: Colors.white30),
                        onTap: () {
                          widget.state.playSong(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bedtime_rounded, color: AppTheme.accentPink),
            SizedBox(width: 10),
            Text('Sleep Timer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sleepTimerOption(context, '15 Minutes', 15),
            _sleepTimerOption(context, '30 Minutes', 30),
            _sleepTimerOption(context, '45 Minutes', 45),
            _sleepTimerOption(context, '60 Minutes', 60),
            if (widget.state.sleepTimerMinutes != null)
              ListTile(
                title: const Text('Cancel Timer', style: TextStyle(color: Colors.redAccent)),
                leading: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                onTap: () {
                  widget.state.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sleepTimerOption(BuildContext context, String title, int minutes) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: widget.state.sleepTimerMinutes == minutes
          ? const Icon(Icons.check, color: AppTheme.primaryLight)
          : null,
      onTap: () {
        widget.state.setSleepTimer(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Music will stop in $minutes minutes.')),
        );
      },
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
