import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/profile_service.dart';
import '../services/theme_color_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/update_dialog.dart';
import 'equalizer_screen.dart';
import 'now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  final MusicPlayerState state;

  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UpdateInfo? _updateInfo;
  String _selectedCategory = 'All'; // 'All', 'Bollywood', 'Hollywood', 'Bengali'

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.state, ThemeColorService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final songs = widget.state.onlineTrending;
        final playlists = MockMusicRepository.playlists;

        final List<Song> trendingFiltered;
        if (_selectedCategory == 'Bollywood') {
          trendingFiltered = widget.state.bollywoodSongs.isNotEmpty
              ? widget.state.bollywoodSongs
              : songs.where((s) => s.language.toLowerCase().contains('hindi')).toList();
        } else if (_selectedCategory == 'Hollywood') {
          trendingFiltered = widget.state.hollywoodSongs.isNotEmpty
              ? widget.state.hollywoodSongs
              : songs.where((s) => s.language.toLowerCase().contains('english')).toList();
        } else if (_selectedCategory == 'Bengali') {
          trendingFiltered = widget.state.bengaliSongs.isNotEmpty
              ? widget.state.bengaliSongs
              : songs.where((s) => s.language.toLowerCase().contains('bengali')).toList();
        } else {
          trendingFiltered = songs;
        }

        return Scaffold(
          backgroundColor: p.background,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            color: p.background,
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar with clean Bitify logo, user greeting, and Equalizer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: AnimatedBuilder(
                        animation: ProfileService(),
                        builder: (context, _) {
                          final profile = ProfileService();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  NeumorphicBox(
                                    width: 44,
                                    height: 44,
                                    borderRadius: 14,
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      'assets/bitify_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: p.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        'Bitify Music Player',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                  // Equalizer button
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
                                    child: Icon(Icons.tune_rounded, size: 20, color: p.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  // Now Playing Disk Button
                                  NeumorphicBox(
                                    width: 44,
                                    height: 44,
                                    borderRadius: 22,
                                    hasGlow: widget.state.isPlaying,
                                    onTap: () {
                                      if (widget.state.currentSong != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NowPlayingScreen(state: widget.state),
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(Icons.album_rounded, size: 22, color: p.primary),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Update banner (if available)
                  if (_updateInfo != null && _updateInfo!.hasUpdate)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: GestureDetector(
                          onTap: () => showBitifyUpdateDialog(context, _updateInfo!),
                          child: NeumorphicBox(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hasGlow: true,
                            child: Row(
                              children: [
                                Icon(Icons.system_update_rounded, color: p.primary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Bitify ${_updateInfo!.latestVersion} Available! Tap to install',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 0. Language / Category Filter Chips (Spotify & JioSaavn style)
                          _buildCategoryFilterBar(p),
                          const SizedBox(height: 18),

                          // 1. SECTION: Trending (Circular elevated well buttons, exact match to reference screenshot)
                          _buildSectionHeader('Trending', p),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                for (int i = 0; i < 3 && i < (trendingFiltered.isNotEmpty ? trendingFiltered.length : songs.length); i++)
                                  _buildTrendingCircularButton((trendingFiltered.isNotEmpty ? trendingFiltered : songs)[i], p),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 2. BOLLYWOOD PLAYLISTS (Bollywood Hits & Playlists)
                          if (_selectedCategory == 'All' || _selectedCategory == 'Bollywood') ...[
                            _buildSectionHeader('Bollywood Playlists', p, badge: 'JIOSAAVN & SPOTIFY', badgeColor: const Color(0xFFF59E0B)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.bollywoodPlaylists,
                              p,
                              badgeLabel: 'BOLLYWOOD',
                              badgeColor: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 3. HOLLYWOOD PLAYLISTS (Hollywood / Global Hits & Playlists)
                          if (_selectedCategory == 'All' || _selectedCategory == 'Hollywood') ...[
                            _buildSectionHeader('Hollywood Playlists', p, badge: 'SPOTIFY GLOBAL', badgeColor: const Color(0xFF1DB954)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.hollywoodPlaylists,
                              p,
                              badgeLabel: 'SPOTIFY',
                              badgeColor: const Color(0xFF1DB954),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 4. BENGALI PLAYLISTS (Bengali Hits & Playlists)
                          if (_selectedCategory == 'All' || _selectedCategory == 'Bengali') ...[
                            _buildSectionHeader('Bengali Playlists', p, badge: 'BANGLA HITS', badgeColor: const Color(0xFF06B6D4)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.bengaliPlaylists,
                              p,
                              badgeLabel: 'BENGALI',
                              badgeColor: const Color(0xFF06B6D4),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 5. TRENDING ALBUMS & EPS (Full Albums from JioSaavn & Spotify)
                          _buildSectionHeader('Trending Albums & EPs', p, badge: 'FULL ALBUMS', badgeColor: const Color(0xFF8B5CF6)),
                          const SizedBox(height: 14),
                          _buildAlbumCarousel(widget.state.trendingAlbums, p),
                          const SizedBox(height: 28),

                          // 6. POPULAR PLAYLISTS
                          _buildSectionHeader('Popular Playlists', p),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                if (playlists.isNotEmpty)
                                  Expanded(
                                    child: _buildPopularPlaylistCard(
                                      title: 'Hip Hop',
                                      subtitle: 'Latest Collection',
                                      imageUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800&q=80',
                                      palette: p,
                                      onTap: () {
                                        widget.state.playWithSpotifyAlgorithm(playlists[0].songs.first, contextPlaylist: playlists[0].songs);
                                      },
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                if (playlists.length > 1)
                                  Expanded(
                                    child: _buildPopularPlaylistCard(
                                      title: 'Disco Beat',
                                      subtitle: 'Trending Ramp',
                                      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80',
                                      palette: p,
                                      onTap: () {
                                        widget.state.playWithSpotifyAlgorithm(playlists[1].songs.first, contextPlaylist: playlists[1].songs);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section Header with title and optional badge
  /// Section Header with title and optional badge (no non-functional 3 dots)
  Widget _buildSectionHeader(String title, SongColorPalette p, {String? badge, Color badgeColor = const Color(0xFF1DB954)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: badgeColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 10, color: badgeColor),
                  const SizedBox(width: 3),
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sleek gradient fallback for failed/missing network images
  Widget _buildImageFallback({double? width, double? height, double borderRadius = 12, required SongColorPalette palette}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface,
            palette.surface.withOpacity(0.6),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: palette.primary.withOpacity(0.7),
          size: (width != null && width < 50) ? 20 : 28,
        ),
      ),
    );
  }

  /// Category Filter Bar (All, Bollywood, Hollywood, Bengali)
  Widget _buildCategoryFilterBar(SongColorPalette p) {
    const categories = ['All', 'Bollywood', 'Hollywood', 'Bengali'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? p.primary.withOpacity(0.2) : p.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isSelected ? p.primary : p.textSecondary.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: p.glow.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: p.shadowDark.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? p.primary : p.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Playlist Carousel Section for Bollywood, Hollywood, Bengali
  Widget _buildPlaylistCarousel(
    List<Playlist> playlistList,
    SongColorPalette p, {
    required String badgeLabel,
    required Color badgeColor,
  }) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: playlistList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final pl = playlistList[i];
          return _buildSpotifyPlaylistCard(
            pl,
            p,
            badgeLabel: badgeLabel,
            badgeColor: badgeColor,
          );
        },
      ),
    );
  }

  /// Spotify / JioSaavn Curated Playlist Card with Spotify Algorithmic Flow
  Widget _buildSpotifyPlaylistCard(
    Playlist playlist,
    SongColorPalette palette, {
    String badgeLabel = 'SPOTIFY',
    Color badgeColor = const Color(0xFF1DB954),
  }) {
    return NeumorphicBox(
      width: 155,
      borderRadius: 22,
      padding: const EdgeInsets.all(10),
      onTap: () {
        _showPlaylistModal(context, playlist, palette);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  playlist.coverUrl,
                  height: 125,
                  width: 135,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImageFallback(width: 135, height: 125, borderRadius: 16, palette: palette),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    if (playlist.songs.isNotEmpty) {
                      widget.state.playWithSpotifyAlgorithm(playlist.songs.first, contextPlaylist: playlist.songs);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Playing ${playlist.title} with Spotify Algorithm'),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surface.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            playlist.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${playlist.songs.length} Tracks • Explore',
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Modal Bottom Sheet to Explore Playlist songs
  void _showPlaylistModal(BuildContext context, Playlist playlist, SongColorPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header with Cover Art, Title, Description
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      playlist.coverUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImageFallback(width: 72, height: 72, borderRadius: 16, palette: p),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${playlist.songs.length} Tracks • Spotify Algorithm Flow',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Button: Play All with Spotify Algorithm
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  if (playlist.songs.isNotEmpty) {
                    widget.state.playPlaylist(playlist);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text(
                        'PLAY WITH SPOTIFY ALGORITHM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: p.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 8),
              // Song list inside playlist
              Expanded(
                child: ListView.separated(
                  itemCount: playlist.songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final song = playlist.songs[idx];
                    final isCurrent = song.id == widget.state.currentSong?.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.state.playSong(song, newQueue: playlist.songs);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? p.primary.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.coverUrl,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildImageFallback(width: 42, height: 42, borderRadius: 8, palette: p),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      color: isCurrent ? p.primary : p.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${song.artist} • ${song.language}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent && widget.state.isPlaying)
                              const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954), size: 18)
                            else
                              Text(
                                song.formattedDuration,
                                style: TextStyle(fontSize: 11, color: p.textSecondary),
                              ),
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
      },
    );
  }

  /// Circular neumorphic button in the Trending row
  Widget _buildTrendingCircularButton(Song song, SongColorPalette p) {
    final isCurrent = song.id == widget.state.currentSong?.id;

    return GestureDetector(
      onTap: () => widget.state.playSingleSong(song),
      child: Column(
        children: [
          NeumorphicBox(
            width: 76,
            height: 76,
            isCircle: true,
            hasGlow: isCurrent,
            glowColor: p.glow,
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: Image.network(
                song.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImageFallback(borderRadius: 38, palette: p),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Popular Playlist Card (Tall squircle card matching reference design)
  Widget _buildPopularPlaylistCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required SongColorPalette palette,
    required VoidCallback onTap,
  }) {
    return NeumorphicBox(
      borderRadius: 24,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Upper image portion
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImageFallback(height: 140, borderRadius: 18, palette: palette),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          // Subtitle
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Trending Albums Carousel Section
  Widget _buildAlbumCarousel(List<Album> albums, SongColorPalette p) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final alb = albums[i];
          return NeumorphicBox(
            width: 155,
            borderRadius: 22,
            padding: const EdgeInsets.all(10),
            onTap: () => _showAlbumModal(context, alb, p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        alb.coverUrl,
                        height: 125,
                        width: 135,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImageFallback(width: 135, height: 125, borderRadius: 16, palette: p),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Text(
                          'ALBUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          if (alb.songs.isNotEmpty) {
                            widget.state.playSong(alb.songs.first, newQueue: alb.songs);
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.surface.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: p.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alb.title,
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
                  '${alb.artist} • ${alb.songs.length} Tracks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: p.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Full Album Details Bottom Sheet
  void _showAlbumModal(BuildContext context, Album album, SongColorPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      album.coverUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImageFallback(width: 72, height: 72, borderRadius: 16, palette: p),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${album.songs.length} Tracks • Full Album',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  if (album.songs.isNotEmpty) {
                    widget.state.playSong(album.songs.first, newQueue: album.songs);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text(
                        'PLAY FULL ALBUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: p.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: album.songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final song = album.songs[idx];
                    final isCurrent = song.id == widget.state.currentSong?.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.state.playSong(song, newQueue: album.songs);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? p.primary.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.coverUrl,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildImageFallback(width: 42, height: 42, borderRadius: 8, palette: p),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      color: isCurrent ? p.primary : p.textPrimary,
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${song.durationSeconds ~/ 60}:${(song.durationSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSecondary,
                              ),
                            ),
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
      },
    );
  }
}
