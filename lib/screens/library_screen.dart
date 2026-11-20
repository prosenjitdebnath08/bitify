import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_tile.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final allSongs = MockMusicRepository.allSongs;
        final likedSongs = allSongs.where((s) => widget.state.isSongLiked(s.id)).toList();
        final playlists = MockMusicRepository.playlists;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Your Music Vault',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryLight, size: 26),
                tooltip: 'New Playlist',
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textMuted,
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
              _buildPlaylistsTab(playlists),

              // 2. Liked Songs Tab
              _buildLikedSongsTab(likedSongs),

              // 3. Downloads / Offline Vault Tab
              _buildDownloadsTab(allSongs),

              // 4. History Tab
              _buildHistoryTab(allSongs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(List<Playlist> playlists) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        // Create playlist card
        GestureDetector(
          onTap: () => _showCreatePlaylistDialog(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.playlist_add_circle_rounded, size: 36, color: AppTheme.primaryLight),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom Playlist',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      'Aggregate tracks from Spotify, YT Music & JioSaavn',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
            final p = playlists[i];
            return GestureDetector(
              onTap: () {
                if (p.songs.isNotEmpty) {
                  widget.state.playSong(p.songs.first, newQueue: p.songs);
                }
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
                          p.coverUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.songs.length} Tracks • FLAC',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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

  Widget _buildLikedSongsTab(List<Song> likedSongs) {
    if (likedSongs.isEmpty) {
      return const Center(
        child: Text(
          'No liked songs yet.\nTap the heart icon on any song to save it here!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
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

  Widget _buildDownloadsTab(List<Song> allSongs) {
    return AnimatedBuilder(
      animation: DownloadService(),
      builder: (context, _) {
        final ds = DownloadService();
        final downloading = ds.downloading;
        final downloaded = ds.downloaded;
        final total = downloaded.length + downloading.length;
        // Build queue of fully downloaded songs for playback
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
                      const Text(
                        'Offline Audio Vault',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 15),
                      ),
                      Text(
                        '$total Track${total == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : downloaded.length / total.clamp(1, 999),
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.secondary),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    total == 0
                        ? 'No downloads yet — tap ⋮ on any song to download'
                        : '${downloaded.length} Track${downloaded.length == 1 ? '' : 's'} stored in 256kbps High Quality format',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active downloads section
            if (downloading.isNotEmpty) ...[
              const Text(
                'Downloading',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary),
              ),
              const SizedBox(height: 8),
              ...downloading.map((e) {
                final isCurrent =
                    e.song.id == widget.state.currentSong?.id;
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

            // Completed downloads section
            if (downloaded.isNotEmpty) ...[
              const Text(
                'Downloaded Tracks',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              ...downloaded.map((e) {
                final isCurrent =
                    e.song.id == widget.state.currentSong?.id;
                return SongTile(
                  song: e.song,
                  isCurrent: isCurrent,
                  isPlaying: widget.state.isPlaying && isCurrent,
                  isLiked: widget.state.isSongLiked(e.song.id),
                  showDeleteOption: true,
                  onTap: () =>
                      widget.state.playSong(e.song, newQueue: downloadedSongs),
                  onLikeTap: () => widget.state.toggleLike(e.song.id),
                );
              }),
            ],

            // Empty state
            if (total == 0)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.download_for_offline_outlined,
                          size: 64, color: Colors.white12),
                      SizedBox(height: 16),
                      Text(
                        'No downloaded songs',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap ⋮ on any song and choose\n"Download (256kbps)" to save it offline.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
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

  Widget _buildHistoryTab(List<Song> songs) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 150),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Today',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.secondary),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Yesterday',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
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

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter playlist title...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created playlist "${controller.text}"')),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
