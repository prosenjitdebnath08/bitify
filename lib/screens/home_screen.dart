import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../services/profile_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
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
  String _selectedCategory = 'All';

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
          // Spotify-style Header: Greeting & Profile Avatar
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: AppTheme.background,
            elevation: 0,
            toolbarHeight: 68,
            title: AnimatedBuilder(
              animation: ProfileService(),
              builder: (context, _) {
                final profile = ProfileService();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/bitify_logo.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_getGreeting()}, ${profile.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'What do you want to play?',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Update Banner (Only shown if a real GitHub release is available)
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

                  // Spotify-style Filter Chips: All, Music, Lossless, Downloads
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Music'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Lossless 24-bit'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Downloaded Vault'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Iconic Spotify 6-Card Quick Access Grid (2 columns x 3 rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSpotifyQuickGrid(state, songs),
                  ),
                  const SizedBox(height: 28),

                  // Jump Back In / Playlists Horizontal Carousel
                  _buildSectionHeader('Jump Back In', subtitle: 'Your favorite albums and aggregated mixes'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
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
                            width: 136,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    p.coverUrl,
                                    width: 136,
                                    height: 136,
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
                  const SizedBox(height: 28),

                  // Section: Today's Top Hits (Trending Songs List)
                  _buildSectionHeader(
                    'Today\'s Top Hits',
                    subtitle: 'Full 320kbps Lossless streaming direct from CDN',
                  ),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
        if (label == 'Downloaded Vault') {
          final downloaded = DownloadService().downloadedSongs;
          if (downloaded.isNotEmpty) {
            widget.state.playSong(downloaded.first, newQueue: downloaded);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing ${downloaded.length} downloaded tracks offline'),
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
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  /// The Spotify-style 2-column x 3-row compact grid
  Widget _buildSpotifyQuickGrid(MusicPlayerState state, List<Song> songs) {
    // Collect items for 6 quick slots
    final items = <_QuickCardItem>[
      _QuickCardItem(
        title: 'Liked Songs',
        icon: Icons.favorite_rounded,
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        onTap: () {
          final liked = songs.where((s) => state.isSongLiked(s.id)).toList();
          if (liked.isNotEmpty) state.playSong(liked.first, newQueue: liked);
        },
      ),
      _QuickCardItem(
        title: 'Downloads Vault',
        icon: Icons.offline_pin_rounded,
        gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
        onTap: () {
          final downloaded = DownloadService().downloadedSongs;
          if (downloaded.isNotEmpty) {
            state.playSong(downloaded.first, newQueue: downloaded);
          }
        },
      ),
    ];

    // Add up to 4 real songs
    for (int i = 0; i < 4 && i < songs.length; i++) {
      final s = songs[i];
      items.add(
        _QuickCardItem(
          title: s.title,
          imageUrl: s.coverUrl,
          onTap: () => state.playSong(s, newQueue: songs),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.white12,
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(gradient: item.gradient),
                          child: Icon(item.icon, color: Colors.white, size: 24),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
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
                  fontSize: 19,
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

class _QuickCardItem {
  final String title;
  final String? imageUrl;
  final IconData? icon;
  final Gradient? gradient;
  final VoidCallback onTap;

  _QuickCardItem({
    required this.title,
    this.imageUrl,
    this.icon,
    this.gradient,
    required this.onTap,
  });
}
