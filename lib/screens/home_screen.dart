import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/profile_service.dart';
import '../services/theme_color_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../widgets/bitchord_card_motion.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/update_dialog.dart';
import 'equalizer_screen.dart';
import 'now_playing_screen.dart';
import 'playlist_detail_screen.dart';

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
        } else if (_selectedCategory == 'Spotify') {
          trendingFiltered = songs.where((s) => s.source == MusicSource.spotify).toList();
        } else if (_selectedCategory == 'YouTube Music') {
          trendingFiltered = songs.where((s) => s.source == MusicSource.youtube).toList();
        } else if (_selectedCategory == 'JioSaavn') {
          trendingFiltered = songs.where((s) => s.source == MusicSource.jiosaavn).toList();
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

                          // 2. SPOTIFY FEATURED PLAYLISTS
                          if (_selectedCategory == 'All' || _selectedCategory == 'Spotify') ...[
                            _buildSectionHeader('Spotify Featured Playlists', p, badge: 'SPOTIFY OFFICIAL', badgeColor: const Color(0xFF1DB954)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.spotifyPlaylists,
                              p,
                              badgeLabel: 'SPOTIFY',
                              badgeColor: const Color(0xFF1DB954),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 3. YOUTUBE MUSIC MIXES
                          if (_selectedCategory == 'All' || _selectedCategory == 'YouTube Music') ...[
                            _buildSectionHeader('YouTube Music Mixes', p, badge: 'TRENDING MIXES', badgeColor: const Color(0xFFEF4444)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.youtubePlaylists,
                              p,
                              badgeLabel: 'YOUTUBE MUSIC',
                              badgeColor: const Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 4. JIOSAAVN CURATED PLAYLISTS
                          if (_selectedCategory == 'All' || _selectedCategory == 'JioSaavn') ...[
                            _buildSectionHeader('JioSaavn Curated Playlists', p, badge: 'CHARTS & TOP 50', badgeColor: const Color(0xFF06B6D4)),
                            const SizedBox(height: 14),
                            _buildPlaylistCarousel(
                              widget.state.jiosaavnPlaylists,
                              p,
                              badgeLabel: 'JIOSAAVN',
                              badgeColor: const Color(0xFF06B6D4),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // 5. BOLLYWOOD PLAYLISTS (Bollywood Hits & Playlists)
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

                          // 6. HOLLYWOOD PLAYLISTS (Hollywood / Global Hits & Playlists)
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

                          // 7. BENGALI PLAYLISTS (Bengali Hits & Playlists)
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

                          // 8. ENDLESS MULTI-PLATFORM RECOMMENDATIONS FEED
                          if (_selectedCategory == 'All') ...[
                            _buildSectionHeader('Endless Recommendations', p, badge: 'MULTI-PLATFORM FLOW', badgeColor: p.primary),
                            const SizedBox(height: 14),
                            _buildEndlessRecommendationsFeed(widget.state.endlessPlaylists, p),
                            const SizedBox(height: 28),
                          ],

                          // 9. POPULAR PLAYLISTS
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
                                        widget.state.playPlaylist(playlists[0]);
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
                                        widget.state.playPlaylist(playlists[1]);
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

  /// Section Header with title, optional badge, and functional 3-dots options
  Widget _buildSectionHeader(
    String title,
    SongColorPalette p, {
    String? badge,
    Color badgeColor = const Color(0xFF1DB954),
    VoidCallback? onMoreTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
          NeumorphicBox(
            width: 34,
            height: 22,
            borderRadius: 11,
            onTap: onMoreTap ?? () => _showQuickSourceMenu(context, title, p),
            child: Icon(Icons.more_horiz_rounded, size: 16, color: p.textSecondary),
          ),
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

  /// Category Filter Bar (All, Spotify, YouTube Music, JioSaavn, Bollywood, Hollywood, Bengali)
  Widget _buildCategoryFilterBar(SongColorPalette p) {
    const categories = ['All', 'Spotify', 'YouTube Music', 'JioSaavn', 'Bollywood', 'Hollywood', 'Bengali'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
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
              curve: Curves.easeOutCubic,
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

  /// Playlist Carousel Section with smooth bouncing physics
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
        physics: const BouncingScrollPhysics(),
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

  /// Curated Playlist Card with direct play, modal inspection, and 3-dots options
  Widget _buildSpotifyPlaylistCard(
    Playlist playlist,
    SongColorPalette palette, {
    String badgeLabel = 'SPOTIFY',
    Color badgeColor = const Color(0xFF1DB954),
  }) {
    final isPlayingThisPlaylist = widget.state.isPlaying &&
        playlist.songs.any((s) => s.id == widget.state.currentSong?.id);

    return BitChordCardMotion(
      borderRadius: 22,
      glowColor: badgeColor,
      isPlaying: isPlayingThisPlaylist,
      onTap: () {
        _openPlaylistDetail(context, playlist, palette);
      },
      child: NeumorphicBox(
        width: 155,
        borderRadius: 22,
        padding: const EdgeInsets.all(10),
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
                // Functional 3-dots options on the playlist card
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _showPlaylistActionsBottomSheet(context, playlist, palette),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        size: 15,
                        color: Colors.white,
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
                        widget.state.playPlaylist(playlist);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Playing ${playlist.title}'),
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
              '${playlist.songs.length} Tracks • ${playlist.source.displayName}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Endless multi-platform recommendations feed (horizontal grid/carousel)
  Widget _buildEndlessRecommendationsFeed(List<Playlist> endlessList, SongColorPalette p) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: endlessList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final pl = endlessList[i];
          final badgeLabel = pl.source == MusicSource.youtube
              ? 'YOUTUBE'
              : (pl.source == MusicSource.jiosaavn ? 'JIOSAAVN' : 'SPOTIFY');
          final badgeColor = pl.source == MusicSource.youtube
              ? const Color(0xFFEF4444)
              : (pl.source == MusicSource.jiosaavn ? const Color(0xFF06B6D4) : const Color(0xFF1DB954));

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

  /// Functional 3-dots action sheet for any playlist
  void _showPlaylistActionsBottomSheet(BuildContext context, Playlist playlist, SongColorPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    playlist.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImageFallback(width: 48, height: 48, borderRadius: 10, palette: p),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${playlist.songs.length} Tracks • ${playlist.source.displayName}',
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: p.textSecondary.withOpacity(0.2)),
            ListTile(
              dense: true,
              leading: Icon(Icons.play_arrow_rounded, color: p.primary),
              title: Text('Play Playlist', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                if (playlist.songs.isNotEmpty) {
                  widget.state.playPlaylist(playlist);
                }
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.shuffle_rounded, color: p.textPrimary),
              title: Text('Shuffle Play', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                if (playlist.songs.isNotEmpty) {
                  final shuffled = List<Song>.from(playlist.songs)..shuffle();
                  widget.state.playSong(shuffled.first, newQueue: shuffled);
                }
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.queue_music_rounded, color: p.textPrimary),
              title: Text('Add Tracks to Queue', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                for (final s in playlist.songs) {
                  widget.state.addToQueue(s);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${playlist.songs.length} tracks to queue')),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.playlist_play_rounded, color: p.textPrimary),
              title: Text('View Full Tracklist', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showPlaylistModal(context, playlist, p);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Quick source/category filter sheet triggered by section header 3 dots
  void _showQuickSourceMenu(BuildContext context, String sectionTitle, SongColorPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Filter by Platform & Genre',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Spotify', 'YouTube Music', 'JioSaavn', 'Bollywood', 'Hollywood', 'Bengali'].map((c) {
                final isCur = _selectedCategory == c;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedCategory = c;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCur ? p.primary : p.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isCur ? p.primary : Colors.white12),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCur ? FontWeight.w800 : FontWeight.w600,
                        color: isCur ? Colors.white : p.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to full BitChord v1.9 playlist detail screen with smooth spring slide-fade animation
  void _openPlaylistDetail(BuildContext context, Playlist playlist, SongColorPalette p) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlaylistDetailScreen(
          playlist: playlist,
          state: widget.state,
          initialPalette: p,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  void _showPlaylistModal(BuildContext context, Playlist playlist, SongColorPalette p) {
    _openPlaylistDetail(context, playlist, p);
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
}
