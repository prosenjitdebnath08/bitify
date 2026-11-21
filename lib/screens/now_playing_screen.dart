import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/music_models.dart';
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
      animation: Listenable.merge([widget.state, ThemeColorService()]),
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
                      ],
                    ),
                  ),

                  // 3. Right Vinyl Record Cutout (Large turntable disc protruding from right edge)
                  Positioned(
                    right: -size.width * 0.28,
                    top: size.height * 0.22,
                    child: _buildVinylTurntable(song, p, size),
                  ),

                  // 4. Floating Left Control Capsule Bar (Exact match to reference design)
                  Positioned(
                    left: 22,
                    top: size.height * 0.23,
                    child: _buildVerticalControlCapsule(song, p),
                  ),

                  // 5. Bottom Neumorphic Seekbar & Controls
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: _buildBottomSeekBar(song, p, progress, currentSeconds, duration),
                  ),
                ],
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
          color: Colors.white.withOpacity(0.7),
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

    return NeumorphicBox(
      width: 54,
      height: 340,
      borderRadius: 27,
      hasGlow: true,
      glowColor: p.glow.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Repeat / Loop Button
          IconButton(
            icon: Icon(
              widget.state.repeatMode == BitifyRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              size: 22,
              color: widget.state.repeatMode != BitifyRepeatMode.off
                  ? p.primary
                  : p.textSecondary,
            ),
            tooltip: 'Repeat Mode',
            onPressed: widget.state.toggleRepeat,
          ),

          // 2. Next Track
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              size: 24,
              color: p.textPrimary,
            ),
            tooltip: 'Next Track',
            onPressed: widget.state.next,
          ),

          // 3. Play / Pause Button (Embossed Neumorphic circle in center)
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

          // 4. Previous Track
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 24,
              color: p.textPrimary,
            ),
            tooltip: 'Previous Track',
            onPressed: widget.state.previous,
          ),

          // 5. Heart / Like Button (Red if liked)
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 22,
              color: isLiked ? const Color(0xFFEF4444) : p.textSecondary,
            ),
            tooltip: 'Favorite',
            onPressed: () => widget.state.toggleLike(song.id),
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
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
