import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/bitchord_card_motion.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final MusicPlayerState state;

  const LibraryScreen({super.key, required this.state});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    DownloadService().addListener(_onDownloadChanged);
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DownloadService().removeListener(_onDownloadChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.state, ThemeColorService(), DownloadService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final allSongs = MockMusicRepository.allSongs;
        final likedSongs = allSongs.where((s) => widget.state.isSongLiked(s.id)).toList();
        final playlists = widget.state.allPlaylists;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Your Music Vault',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: p.primary, size: 26),
                tooltip: 'New Playlist',
                onPressed: () => _showCreatePlaylistDialog(context, p),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: p.primary,
              indicatorWeight: 3,
              labelColor: p.textPrimary,
              unselectedLabelColor: p.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Playlists'),
                Tab(text: 'Liked Songs'),
                Tab(text: 'Downloads'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Playlists Tab
              _buildPlaylistsTab(playlists, p),

              // 2. Liked Songs Tab
              _buildLikedSongsTab(likedSongs, p),

              // 3. Downloads / Offline Vault Tab
              _buildDownloadsTab(allSongs, p),

              // 4. History Tab
              _buildHistoryTab(allSongs, p),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(List<Playlist> playlists, SongColorPalette p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        // Create playlist card
        GestureDetector(
          onTap: () => _showCreatePlaylistDialog(context, p),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.primary.withOpacity(0.18),
                  p.accent.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.primary.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.playlist_add_circle_rounded, size: 36, color: p.primary),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom Playlist',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                    Text(
                      'Aggregate tracks from Spotify, YT Music & JioSaavn',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Grid of playlists
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, i) {
            final playlist = playlists[i];
            final isPlayingThis = widget.state.isPlaying &&
                playlist.songs.any((s) => s.id == widget.state.currentSong?.id);

            return BitChordCardMotion(
              borderRadius: 18,
              glowColor: p.primary,
              isPlaying: isPlayingThis,
              onTap: () {
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
              },
              child: GlassCard(
                padding: const EdgeInsets.all(10),
                radius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          playlist.coverUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: p.surface,
                            child: Center(
                              child: Icon(Icons.queue_music_rounded, color: p.primary, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.songs.length} Tracks • Bitify Flow',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLikedSongsTab(List<Song> likedSongs, SongColorPalette p) {
    if (likedSongs.isEmpty) {
      return Center(
        child: Text(
          'No liked songs yet.\nTap the heart icon on any song to save it here!',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 150),
      itemCount: likedSongs.length,
      itemBuilder: (context, i) {
        final song = likedSongs[i];
        final isCurrent = song.id == widget.state.currentSong?.id;

        return SongTile(
          song: song,
          isCurrent: isCurrent,
          isPlaying: widget.state.isPlaying && isCurrent,
          isLiked: true,
          onTap: () => widget.state.playSong(song, newQueue: likedSongs),
          onLikeTap: () => widget.state.toggleLike(song.id),
        );
      },
    );
  }

  Widget _buildDownloadsTab(List<Song> allSongs, SongColorPalette p) {
    return AnimatedBuilder(
      animation: DownloadService(),
      builder: (context, _) {
        final ds = DownloadService();
        final downloading = ds.downloading;
        final downloaded = ds.downloaded;
        final total = downloaded.length + downloading.length;
        final downloadedSongs = downloaded.map((e) => e.song).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            // Storage / info card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offline Audio Vault',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                            fontSize: 15),
                      ),
                      Row(
                        children: [
                          Text(
                            '$total Track${total == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: p.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                          if (downloaded.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _confirmClearAllDownloads(context, p),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 16),
                                    SizedBox(width: 2),
                                    Text(
                                      'Clear',
                                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : downloaded.length / total.clamp(1, 999),
                    backgroundColor: p.isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation(p.primary),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    total == 0
                        ? 'No downloads yet — tap download icon on any song'
                        : '${downloaded.length} Track${downloaded.length == 1 ? '' : 's'} stored in 256kbps Master Audio',
                    style: TextStyle(color: p.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active downloads
            if (downloading.isNotEmpty) ...[
              Text(
                'Downloading',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.primary),
              ),
              const SizedBox(height: 8),
              ...downloading.map((e) {
                final isCurrent = e.song.id == widget.state.currentSong?.id;
                return SongTile(
                  song: e.song,
                  isCurrent: isCurrent,
                  isPlaying: widget.state.isPlaying && isCurrent,
                  isLiked: widget.state.isSongLiked(e.song.id),
                  onTap: () => widget.state.playSong(e.song),
                  onLikeTap: () => widget.state.toggleLike(e.song.id),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Completed downloads
            if (downloaded.isNotEmpty) ...[
              Text(
                'Downloaded Tracks',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary),
              ),
              const SizedBox(height: 8),
              ...downloaded.map((e) {
                final isCurrent = e.song.id == widget.state.currentSong?.id;
                return SongTile(
                  song: e.song,
                  isCurrent: isCurrent,
                  isPlaying: widget.state.isPlaying && isCurrent,
                  isLiked: widget.state.isSongLiked(e.song.id),
                  showDeleteOption: true,
                  onTap: () => widget.state.playSong(e.song, newQueue: downloadedSongs),
                  onLikeTap: () => widget.state.toggleLike(e.song.id),
                );
              }),
            ],

            // Empty state
            if (total == 0)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.download_for_offline_outlined,
                          size: 64, color: p.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No downloaded songs',
                        style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the download icon below the love sign in\nNow Playing to save tracks offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab(List<Song> songs, SongColorPalette p) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 150),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Today',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.primary),
          ),
        ),
        ...songs.take(3).map((s) {
          final isCurrent = s.id == widget.state.currentSong?.id;
          return SongTile(
            song: s,
            isCurrent: isCurrent,
            isPlaying: widget.state.isPlaying && isCurrent,
            isLiked: widget.state.isSongLiked(s.id),
            onTap: () => widget.state.playSong(s),
            onLikeTap: () => widget.state.toggleLike(s.id),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Yesterday',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textSecondary),
          ),
        ),
        ...songs.skip(3).take(3).map((s) {
          final isCurrent = s.id == widget.state.currentSong?.id;
          return SongTile(
            song: s,
            isCurrent: isCurrent,
            isPlaying: widget.state.isPlaying && isCurrent,
            isLiked: widget.state.isSongLiked(s.id),
            onTap: () => widget.state.playSong(s),
            onLikeTap: () => widget.state.toggleLike(s.id),
          );
        }),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, SongColorPalette p) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Playlist', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: p.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter playlist title...',
            hintStyle: TextStyle(color: p.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                widget.state.createPlaylist(title);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created playlist "$title"')),
                );
              }
            },
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllDownloads(BuildContext context, SongColorPalette p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Downloads', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete all downloaded offline songs?',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DownloadService().clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All offline downloads cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
