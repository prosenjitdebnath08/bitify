import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class ExploreScreen extends StatelessWidget {
  final MusicPlayerState state;

  const ExploreScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final songs = state.onlineTrending;
    final artists = MockMusicRepository.artists;
    final albums = MockMusicRepository.albums;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.background.withOpacity(0.8),
            elevation: 0,
            title: const Text(
              'Explore & Radar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Trending Charts Horizontal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Global Charts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LIVE SYNC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildChartCard(
                          title: 'Global Top 50',
                          platform: 'Multi-Source',
                          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                          icon: Icons.public_rounded,
                          onTap: () => state.playSong(songs.first, newQueue: songs),
                        ),
                        const SizedBox(width: 12),
                        _buildChartCard(
                          title: 'Viral YouTube Hits',
                          platform: 'YouTube Music',
                          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                          icon: Icons.play_arrow_rounded,
                          onTap: () {
                            final yt = songs.where((s) => s.source == MusicSource.youtube).toList();
                            if (yt.isNotEmpty) state.playSong(yt.first, newQueue: yt);
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildChartCard(
                          title: 'Spotify Top 100',
                          platform: 'Spotify Direct',
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                          icon: Icons.graphic_eq_rounded,
                          onTap: () {
                            final sp = songs.where((s) => s.source == MusicSource.spotify).toList();
                            if (sp.isNotEmpty) state.playSong(sp.first, newQueue: sp);
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildChartCard(
                          title: 'JioSaavn Weekly',
                          platform: 'JioSaavn Desi',
                          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)]),
                          icon: Icons.library_music_rounded,
                          onTap: () {
                            final js = songs.where((s) => s.source == MusicSource.jiosaavn).toList();
                            if (js.isNotEmpty) state.playSong(js.first, newQueue: js);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Top Artists Circle Avatars
                  const Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Spotlight Artists',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: artists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, i) {
                        final artist = artists[i];
                        return Column(
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryLight.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  artist.avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              artist.genres.isNotEmpty ? artist.genres.first : 'Artist',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Albums Carousel
                  const Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Trending Albums & EPs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final album = albums[i];
                        return GestureDetector(
                          onTap: () {
                            if (album.songs.isNotEmpty) {
                              state.playSong(album.songs.first, newQueue: album.songs);
                            }
                          },
                          child: SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    album.coverUrl,
                                    width: 130,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  album.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  album.artist,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Viral Radar Tracks
                  const Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Viral Radar (Global Picks)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...songs.reversed.take(4).map((song) {
                    final isCurrent = song.id == state.currentSong?.id;
                    return SongTile(
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: state.isPlaying && isCurrent,
                      isLiked: state.isSongLiked(song.id),
                      onTap: () => state.playSong(song),
                      onLikeTap: () => state.toggleLike(song.id),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String platform,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
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
