import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../services/download_service.dart';
import '../services/profile_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/update_dialog.dart';
import 'equalizer_screen.dart';
import 'playlist_detail_screen.dart';

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
    _checkForAppUpdates();
  }

  Future<void> _checkForAppUpdates() async {
    final info = await UpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateInfo = info;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final songs = state.onlineTrending;
    final playlists = MockMusicRepository.playlists;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Clean & simple App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.background.withOpacity(0.95),
            elevation: 0,
            toolbarHeight: 64,
            title: AnimatedBuilder(
              animation: ProfileService(),
              builder: (context, _) {
                final profile = ProfileService();
                return Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_getGreeting()}, ${profile.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Bitify Music',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              // One-Tap Equalizer & DSP Access
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 22),
                tooltip: 'Equalizer & DSP',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EqualizerScreen(state: state),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Update Banner (shown only when a new release is live)
                  if (_updateInfo != null && _updateInfo!.hasUpdate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GestureDetector(
                        onTap: () => showBitifyUpdateDialog(context, _updateInfo!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bitify ${_updateInfo!.latestVersion} Available! Tap to update',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Quick Access Cards (Liked Songs & Offline Vault)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickPlayCard(
                            title: 'Liked Songs',
                            subtitle: '${songs.where((s) => state.isSongLiked(s.id)).length} tracks',
                            icon: Icons.favorite_rounded,
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                            onTap: () {
                              final liked = songs.where((s) => state.isSongLiked(s.id)).toList();
                              if (liked.isNotEmpty) state.playSong(liked.first, newQueue: liked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickPlayCard(
                            title: 'Offline Vault',
                            subtitle: '${DownloadService().downloadedSongs.length} downloaded',
                            icon: Icons.offline_pin_rounded,
                            gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                            onTap: () {
                              final downloaded = DownloadService().downloadedSongs;
                              if (downloaded.isNotEmpty) {
                                state.playSong(downloaded.first, newQueue: downloaded);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No offline tracks yet. Tap ⋮ on any song to download.')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: Featured Playlists (Prominently displayed)
                  _buildSectionHeader('Playlists', subtitle: 'Curated playlists & soundscapes'),
                  const SizedBox(height: 12),

                  // 2-Column Playlist Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: playlists.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, i) {
                        final p = playlists[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(playlist: p, state: state),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                        child: Image.network(
                                          p.coverUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(color: Colors.white12),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (p.songs.isNotEmpty) {
                                              state.playSong(p.songs.first, newQueue: p.songs);
                                            }
                                          },
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: AppTheme.primaryGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black45,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                      const SizedBox(height: 2),
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // SECTION: Today's Hits & Trending
                  _buildSectionHeader('Today\'s Top Tracks', subtitle: '320kbps Lossless streaming'),
                  const SizedBox(height: 8),

                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length,
                    itemBuilder: (context, i) {
                      final s = songs[i];
                      final isCurrent = s.id == state.currentSong?.id;
                      return SongTile(
                        song: s,
                        isCurrent: isCurrent,
                        isPlaying: state.isPlaying && isCurrent,
                        isLiked: state.isSongLiked(s.id),
                        onTap: () => state.playSong(s, newQueue: songs),
                        onLikeTap: () => state.toggleLike(s.id),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPlayCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
    );
  }
}
