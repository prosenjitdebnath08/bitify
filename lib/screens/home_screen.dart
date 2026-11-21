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
                                  const SizedBox(width: 10),
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
                          // 1. SECTION: Trending (Circular elevated well buttons, exact match to reference screenshot)
                          _buildSectionHeader('Trending', p),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                for (int i = 0; i < 3 && i < songs.length; i++)
                                  _buildTrendingCircularButton(songs[i], p),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 2. SECTION: Popular Playlists (Tall squircle neumorphic cards, exact match to reference screenshot)
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
                                        widget.state.playSong(playlists[0].songs.first, newQueue: playlists[0].songs);
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
                                        widget.state.playSong(playlists[1].songs.first, newQueue: playlists[1].songs);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 3. SECTION: News / Top Tracks (Horizontal neumorphic pill cards, exact match to reference screenshot)
                          _buildSectionHeader('News', p),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                for (int i = 0; i < songs.length && i < 6; i++) ...[
                                  _buildNewsTrackPill(songs[i], p),
                                  if (i < 5) const SizedBox(height: 12),
                                ],
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

  /// Section Header with title and "..." button on right
  Widget _buildSectionHeader(String title, SongColorPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          NeumorphicBox(
            width: 36,
            height: 20,
            borderRadius: 10,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: p.textSecondary)),
                  const SizedBox(width: 2),
                  Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: p.textSecondary)),
                  const SizedBox(width: 2),
                  Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: p.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Circular neumorphic button in the Trending row
  Widget _buildTrendingCircularButton(Song song, SongColorPalette p) {
    final isCurrent = song.id == widget.state.currentSong?.id;

    return GestureDetector(
      onTap: () => widget.state.playSong(song),
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
                errorBuilder: (_, __, ___) => Container(color: Colors.white24),
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
              errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.white12),
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

  /// Horizontal Neumorphic Pill Track Card in "News" section
  Widget _buildNewsTrackPill(Song song, SongColorPalette p) {
    final isCurrent = song.id == widget.state.currentSong?.id;
    final isPlaying = widget.state.isPlaying && isCurrent;

    return NeumorphicBox(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      hasGlow: isCurrent,
      glowColor: p.glow.withOpacity(0.4),
      onTap: () => widget.state.playSong(song),
      child: Row(
        children: [
          // Circular thumbnail
          ClipOval(
            child: Image.network(
              song.coverUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: Colors.white24),
            ),
          ),
          const SizedBox(width: 14),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                    color: isCurrent ? p.primary : p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${song.artist} • ${song.formattedDuration}',
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
          // Playing or arrow indicator
          if (isPlaying)
            Icon(Icons.equalizer_rounded, color: p.primary, size: 22)
          else
            Icon(Icons.play_arrow_rounded, color: p.textSecondary, size: 20),
        ],
      ),
    );
  }
}
