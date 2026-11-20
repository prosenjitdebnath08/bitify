import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../services/download_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_tile.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final MusicPlayerState state;

  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final songs = state.onlineTrending;
    final playlists = MockMusicRepository.playlists;
    final moodGenres = MockMusicRepository.moodGenres;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // App Bar with Clean Brand Greeting
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.background.withOpacity(0.95),
            elevation: 0,
            toolbarHeight: 64,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/bitify_logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BITIFY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        Text(
                          'Good evening 🎵',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4), width: 1.5),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time Update Available Banner
                  if (_updateInfo != null && _updateInfo!.hasUpdate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GestureDetector(
                        onTap: () => showBitifyUpdateDialog(context, _updateInfo!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bitify ${_updateInfo!.latestVersion} Available!',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                                    ),
                                    const Text(
                                      'Tap to download & install latest update',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'UPDATE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Quick Actions Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildQuickActionPill(
                          icon: Icons.favorite_rounded,
                          color: AppTheme.accentPink,
                          label: 'Liked Songs',
                          onTap: () {
                            final liked = songs.where((s) => state.isSongLiked(s.id)).toList();
                            if (liked.isNotEmpty) state.playSong(liked.first, newQueue: liked);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionPill(
                          icon: Icons.graphic_eq_rounded,
                          color: AppTheme.secondary,
                          label: 'Lossless Vault',
                          onTap: () {
                            final lossless = songs.where((s) => s.isLossless).toList();
                            if (lossless.isNotEmpty) state.playSong(lossless.first, newQueue: lossless);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionPill(
                          icon: Icons.offline_pin_rounded,
                          color: AppTheme.accentAmber,
                          label: 'Downloads',
                          onTap: () {
                            final downloaded = DownloadService().downloadedSongs;
                            if (downloaded.isNotEmpty) {
                              state.playSong(downloaded.first, newQueue: downloaded);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Playing ${downloaded.length} tracks from Offline Vault'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No downloads yet. Tap ⋮ on any song to download in 256kbps.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured Carousel Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      radius: 24,
                      padding: const EdgeInsets.all(0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1000&q=80',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 18,
                            right: 18,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'FEATURED SPOTLIGHT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Starboy (Lossless Master)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'The Weeknd • Daft Punk',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => state.playSong(songs.first),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primaryGradient,
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Section: Recently Played
                  _buildSectionHeader('Recently Played', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 185,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final p = playlists[i];
                        return GestureDetector(
                          onTap: () {
                            if (p.songs.isNotEmpty) {
                              state.playSong(p.songs.first, newQueue: p.songs);
                            }
                          },
                          child: SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    p.coverUrl,
                                    width: 140,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${p.songs.length} Tracks',
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

                  // Section: Trending Across Platforms
                  _buildSectionHeader(
                    'Trending Across Platforms',
                    subtitle: 'Aggregated from YouTube Music, Spotify & JioSaavn (${songs.length} Tracks)',
                  ),
                  const SizedBox(height: 8),
                  ...songs.take(15).map((song) {
                    final isCurrent = song.id == state.currentSong?.id;
                    return SongTile(
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: state.isPlaying && isCurrent,
                      isLiked: state.isSongLiked(song.id),
                      onTap: () => state.playSong(song, newQueue: songs),
                      onLikeTap: () => state.toggleLike(song.id),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Section: Mood & Genre Explorer
                  _buildSectionHeader('Mood & Genre Explorer'),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: moodGenres.length,
                      itemBuilder: (context, i) {
                        final item = moodGenres[i];
                        final c1 = Color(item['color1'] as int);
                        final c2 = Color(item['color2'] as int);

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c1, c2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: c1.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                state.playSong(songs[i % songs.length]);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
