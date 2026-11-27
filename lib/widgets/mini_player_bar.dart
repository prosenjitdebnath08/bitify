import 'package:flutter/material.dart';
import '../screens/now_playing_screen.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import 'cached_artwork_image.dart';
import 'neumorphic_box.dart';

class MiniPlayerBar extends StatelessWidget {
  final MusicPlayerState state;

  const MiniPlayerBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([state, ThemeColorService()]),
        builder: (context, _) {
          final song = state.currentSong;
          if (song == null) return const SizedBox.shrink();

          final p = ThemeColorService().palette;

          final duration = state.durationSeconds > 0
              ? state.durationSeconds
              : (song.durationSeconds > 0 ? song.durationSeconds : 180);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -250) {
                  state.next();
                } else if (details.primaryVelocity! > 250) {
                  state.previous();
                }
              },
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => NowPlayingScreen(state: state),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 240),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    NeumorphicBox(
                      height: 64,
                      borderRadius: 22,
                      hasGlow: true,
                      glowColor: p.glow,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Circular thumbnail
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: p.glow,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedArtworkImage(
                                url: song.coverUrl,
                                width: 44,
                                height: 44,
                                cacheWidth: 120,
                                cacheHeight: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.white24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Title & Artist
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: p.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Play/Pause button
                          NeumorphicBox(
                            width: 38,
                            height: 38,
                            borderRadius: 19,
                            onTap: state.togglePlayPause,
                            child: Icon(
                              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: p.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Next button
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded, color: p.textPrimary, size: 22),
                            onPressed: state.next,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 0,
                      height: 2.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ValueListenableBuilder<int>(
                          valueListenable: state.positionNotifier,
                          builder: (context, posSec, _) {
                            final progress = (posSec / duration).clamp(0.0, 1.0);
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.glow,
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
