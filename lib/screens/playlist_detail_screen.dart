import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  final MusicPlayerState state;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final songs = playlist.songs;
        final totalDurationSeconds = songs.fold<int>(0, (sum, s) => sum + s.durationSeconds);
        final totalMinutes = totalDurationSeconds ~/ 60;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // Large Spotify-style Playlist Header with dynamic background
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred Artwork background
                      Image.network(
                        playlist.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              AppTheme.background.withOpacity(0.85),
                              AppTheme.background,
                            ],
                          ),
                        ),
                      ),
                      // Content inside header
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                playlist.coverUrl,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PLAYLIST',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    playlist.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${songs.length} songs • $totalMinutes mins',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Bar: Play & Shuffle buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Big Play Button
                      GestureDetector(
                        onTap: () {
                          if (songs.isNotEmpty) {
                            state.playSong(songs.first, newQueue: songs);
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Shuffle Button
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white70, size: 26),
                        tooltip: 'Shuffle Play',
                        onPressed: () {
                          if (songs.isNotEmpty) {
                            final shuffled = List<Song>.from(songs)..shuffle();
                            state.playSong(shuffled.first, newQueue: shuffled);
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        playlist.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              // Songs List in Playlist
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 160),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final isCurrent = song.id == state.currentSong?.id;

                      return SongTile(
                        song: song,
                        isCurrent: isCurrent,
                        isPlaying: state.isPlaying && isCurrent,
                        isLiked: state.isSongLiked(song.id),
                        onTap: () => state.playSong(song, newQueue: songs),
                        onLikeTap: () => state.toggleLike(song.id),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
