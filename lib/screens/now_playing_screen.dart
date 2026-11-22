import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../services/spotify_algorithm_service.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/neumorphic_box.dart';
import 'equalizer_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  final MusicPlayerState state;

  const NowPlayingScreen({super.key, required this.state});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isDraggingSeek = false;
  double _dragSeekValue = 0.0;
  bool _showPlaylist = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    if (widget.state.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NowPlayingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.state, ThemeColorService(), DownloadService()]),
      builder: (context, _) {
        final song = widget.state.currentSong;
        if (song == null) {
          return const Scaffold(body: Center(child: Text('No track playing')));
        }

        final p = ThemeColorService().palette;
        final size = MediaQuery.of(context).size;

        final duration = widget.state.durationSeconds > 0
            ? widget.state.durationSeconds
            : (song.durationSeconds > 0 ? song.durationSeconds : 200);
        final currentSeconds = widget.state.positionSeconds.clamp(0, duration);
        final progress = (currentSeconds / duration).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: p.background,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: p.background,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.background,
                  p.surface,
                  p.background,
                ],
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -120) {
                    // Swipe UP -> show playlist in the blank space
                    if (!_showPlaylist) {
                      setState(() => _showPlaylist = true);
                    }
                  } else if (details.primaryVelocity! > 120) {
                    // Swipe DOWN -> return to vinyl turntable stage
                    if (_showPlaylist) {
                      setState(() => _showPlaylist = false);
                    }
                  }
                },
                child: Stack(
                  children: [
                    // 1. Top Bar with back button and options
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NeumorphicBox(
                            width: 44,
                            height: 44,
                            borderRadius: 22,
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: p.textPrimary,
                            ),
                          ),
                          NeumorphicBox(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: p.glow,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '256kbps Master',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Theme Shuffle Button (Dark / Light / System)
                              NeumorphicBox(
                                width: 44,
                                height: 44,
                                borderRadius: 22,
                                onTap: () async {
                                  await ThemeColorService().cycleThemeMode();
                                  final mode = ThemeColorService().themeMode;
                                  final label = mode == ThemeModeOption.dark
                                      ? 'Dark'
                                      : (mode == ThemeModeOption.light ? 'Light' : 'System Default');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Theme set to: $label'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                child: Icon(
                                  ThemeColorService().themeMode == ThemeModeOption.dark
                                      ? Icons.dark_mode_rounded
                                      : (ThemeColorService().themeMode == ThemeModeOption.light
                                          ? Icons.light_mode_rounded
                                          : Icons.brightness_auto_rounded),
                                  size: 20,
                                  color: p.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              NeumorphicBox(
                                width: 44,
                                height: 44,
                                borderRadius: 22,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EqualizerScreen(state: widget.state),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: p.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Track Typography (Top Left, exactly matching the reference design)
                    Positioned(
                      top: 76,
                      left: 24,
                      right: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: p.textPrimary,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song.album,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: p.textSecondary.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtle tap/swipe toggle pill
                          GestureDetector(
                            onTap: () => setState(() => _showPlaylist = !_showPlaylist),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: p.isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.55),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.shadowDark.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showPlaylist ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                    size: 16,
                                    color: p.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showPlaylist ? 'Swipe down for Disc' : 'Swipe up for Playlist',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Right Blank Space: Vinyl Record Cutout OR Scrollable Playlist Queue on Swipe Up
                    if (!_showPlaylist)
                      Positioned(
                        right: -size.width * 0.28,
                        top: size.height * 0.22,
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                              setState(() => _showPlaylist = true);
                            }
                          },
                          child: _buildVinylTurntable(song, p, size),
                        ),
                      )
                    else
                      Positioned(
                        left: 88,
                        right: 18,
                        top: size.height * 0.20,
                        bottom: 124,
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                              setState(() => _showPlaylist = false);
                            }
                          },
                          child: _buildPlaylistQueue(song, p),
                        ),
                      ),

                    // 4. Floating Left Control Capsule Bar (Exact match to reference design)
                    Positioned(
                      left: 20,
                      top: size.height * 0.20,
                      child: _buildVerticalControlCapsule(song, p),
                    ),

                    // 5. Bottom Neumorphic Seekbar & Controls
                    Positioned(
                      bottom: 40,
                      left: 20,
                      right: 20,
                      child: _buildBottomSeekBar(song, p, progress, currentSeconds, duration),
                    ),

                    // 6. Visible Bottom Logo in Player (Bitify Master Audio / Spotify Algorithm)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: _buildBottomLogo(p),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Right Vinyl Turntable Cutout with ambient glow and rotation
  Widget _buildVinylTurntable(Song song, SongColorPalette p, Size size) {
    final diskSize = size.width * 0.88;

    return Container(
      width: diskSize,
      height: diskSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface,
        boxShadow: [
          // Enhanced glowing aura matching song thumbnail
          BoxShadow(
            color: p.glow,
            blurRadius: 36,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: p.shadowDark.withOpacity(0.9),
            offset: const Offset(10, 14),
            blurRadius: 22,
          ),
          BoxShadow(
            color: p.shadowLight,
            offset: const Offset(-8, -8),
            blurRadius: 18,
          ),
        ],
        border: Border.all(
          color: p.isDark ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.7),
          width: 2.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl grooves pattern
              ClipOval(
                child: Image.network(
                  song.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black87),
                ),
              ),
              // Center Vinyl Spindle Ring
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surface,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating Vertical Control Capsule on the left
  Widget _buildVerticalControlCapsule(Song song, SongColorPalette p) {
    final isLiked = widget.state.isSongLiked(song.id);
    final isPlaying = widget.state.isPlaying;
    final ds = DownloadService();
    final isDownloaded = ds.isDownloaded(song.id);
    final isDownloading = ds.isDownloading(song.id);

    return NeumorphicBox(
      width: 54,
      height: 425,
      borderRadius: 27,
      hasGlow: true,
      glowColor: p.glow.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Shuffle Option Button
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              size: 20,
              color: widget.state.isShuffle ? p.primary : p.textSecondary,
            ),
            tooltip: 'Shuffle Mode',
            onPressed: () {
              widget.state.toggleShuffle();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Shuffle: ${widget.state.isShuffle ? "Enabled" : "Disabled"}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // 2. Repeat / Loop Option Button
          IconButton(
            icon: Icon(
              widget.state.repeatMode == BitifyRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              size: 20,
              color: widget.state.repeatMode != BitifyRepeatMode.off
                  ? p.primary
                  : p.textSecondary,
            ),
            tooltip: 'Repeat Mode',
            onPressed: () {
              widget.state.toggleRepeat();
              final modeText = widget.state.repeatMode == BitifyRepeatMode.all
                  ? 'Repeat All'
                  : (widget.state.repeatMode == BitifyRepeatMode.one ? 'Repeat One' : 'Repeat Off');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Repeat: $modeText'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // 3. Next Track
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              size: 24,
              color: p.textPrimary,
            ),
            tooltip: 'Next Track',
            onPressed: widget.state.next,
          ),

          // 4. Play / Pause Button (Embossed Neumorphic circle in center)
          NeumorphicBox(
            width: 44,
            height: 44,
            isCircle: true,
            hasGlow: isPlaying,
            glowColor: p.glow,
            onTap: widget.state.togglePlayPause,
            child: Center(
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 26,
                color: isPlaying ? p.primary : p.textPrimary,
              ),
            ),
          ),

          // 5. Previous Track
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 24,
              color: p.textPrimary,
            ),
            tooltip: 'Previous Track',
            onPressed: widget.state.previous,
          ),

          // 6. Heart / Like Button (Red if liked)
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 22,
              color: isLiked ? const Color(0xFFEF4444) : p.textSecondary,
            ),
            tooltip: 'Favorite',
            onPressed: () => widget.state.toggleLike(song.id),
          ),

          // 7. Download Button (Just below the love sign)
          IconButton(
            icon: Icon(
              isDownloaded
                  ? Icons.download_done_rounded
                  : (isDownloading
                      ? Icons.downloading_rounded
                      : Icons.download_rounded),
              size: 22,
              color: isDownloaded
                  ? const Color(0xFF10B981)
                  : (isDownloading ? p.primary : p.textSecondary),
            ),
            tooltip: isDownloaded ? 'Downloaded' : 'Download Song',
            onPressed: () {
              if (isDownloaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${song.title} is already saved offline'),
                    action: SnackBarAction(
                      label: 'Delete',
                      textColor: const Color(0xFFEF4444),
                      onPressed: () => DownloadService().deleteSong(song.id),
                    ),
                  ),
                );
              } else if (isDownloading) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading in 256kbps Master Audio...')),
                );
              } else {
                DownloadService().startDownload(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${song.title} (256kbps)...'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Bottom Seekbar Card
  Widget _buildBottomSeekBar(
    Song song,
    SongColorPalette p,
    double progress,
    int currentSeconds,
    int duration,
  ) {
    return NeumorphicBox(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: p.primary,
              inactiveTrackColor: p.shadowDark.withOpacity(0.5),
              thumbColor: p.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(currentSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
                Text(
                  _formatTime(duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Interactive Player Options: Shuffle, Mode, Repeat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shuffle Option Button
              GestureDetector(
                onTap: () {
                  widget.state.toggleShuffle();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shuffle: ${widget.state.isShuffle ? "Enabled" : "Disabled"}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.state.isShuffle ? p.primary.withOpacity(0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.state.isShuffle ? p.primary : p.textSecondary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shuffle_rounded,
                        size: 15,
                        color: widget.state.isShuffle ? p.primary : p.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: widget.state.isShuffle ? FontWeight.w800 : FontWeight.w600,
                          color: widget.state.isShuffle ? p.primary : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Playback mode indicator (Single Track vs Playlist Flow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.state.isSingleSongMode ? 'SINGLE TRACK' : 'PLAYLIST FLOW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: widget.state.isSingleSongMode ? const Color(0xFFF59E0B) : const Color(0xFF1DB954),
                  ),
                ),
              ),

              // Repeat Option Button
              GestureDetector(
                onTap: () {
                  widget.state.toggleRepeat();
                  final modeText = widget.state.repeatMode == BitifyRepeatMode.all
                      ? 'Repeat All'
                      : (widget.state.repeatMode == BitifyRepeatMode.one ? 'Repeat One' : 'Repeat Off');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Repeat: $modeText'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.state.repeatMode != BitifyRepeatMode.off
                        ? p.primary.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.state.repeatMode != BitifyRepeatMode.off
                          ? p.primary
                          : p.textSecondary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.state.repeatMode == BitifyRepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        size: 15,
                        color: widget.state.repeatMode != BitifyRepeatMode.off
                            ? p.primary
                            : p.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.state.repeatMode == BitifyRepeatMode.one
                            ? 'One'
                            : (widget.state.repeatMode == BitifyRepeatMode.all ? 'All' : 'Repeat'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: widget.state.repeatMode != BitifyRepeatMode.off
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: widget.state.repeatMode != BitifyRepeatMode.off
                              ? p.primary
                              : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Scrollable Playlist Queue shown when user swipes UP on the player
  Widget _buildPlaylistQueue(Song currentSong, SongColorPalette p) {
    final queue = widget.state.queue;
    final cluster = SpotifyAlgorithmService.getPrimaryGenreCluster(currentSong);
    final lang = SpotifyAlgorithmService.normalizeLanguage(currentSong);
    final genreLabel = cluster.replaceAll('_', ' ').toUpperCase();
    final langLabel = lang.toUpperCase();

    return NeumorphicBox(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue_music_rounded, color: p.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playlist Queue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      '${queue.length} Tracks • $langLabel • $genreLabel',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showPlaylist = false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: queue.length,
              itemBuilder: (context, i) {
                final s = queue[i];
                final isCurrent = s.id == currentSong.id;

                return GestureDetector(
                  onTap: () {
                    widget.state.playSong(s);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? p.primary.withOpacity(0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(color: p.primary.withOpacity(0.4), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            s.coverUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 38,
                              height: 38,
                              color: Colors.white12,
                              child: const Icon(Icons.music_note, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrent ? p.primary : p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: p.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent && widget.state.isPlaying) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 16,
                            color: p.primary,
                          ),
                        ] else ...[
                          Text(
                            s.formattedDuration,
                            style: TextStyle(
                              fontSize: 10,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Visible bottom logo and brand indicator in player
  Widget _buildBottomLogo(SongColorPalette p) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/bitify_logo.png',
            height: 18,
            width: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'BITIFY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.primary),
          ),
          const SizedBox(width: 6),
          Text(
            'SPOTIFY ALGORITHM',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: widget.state.spotifyAlgorithmEnabled ? const Color(0xFF1DB954) : p.primary,
            ),
          ),
        ],
      ),
    );
  }
}
