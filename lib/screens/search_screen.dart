import 'dart:async';
import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../services/music_api_service.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  final MusicPlayerState state;

  const SearchScreen({super.key, required this.state});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  MusicSource? _selectedSource;
  String _query = '';
  List<Song> _searchResults = [];
  List<Playlist> _playlistResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    setState(() {
      _query = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _playlistResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final songs = await MusicApiService.searchOnline(query.trim());
        final playlists = await MusicApiService.searchMultiSourcePlaylists(query.trim(), songs);
        if (mounted) {
          setState(() {
            _searchResults = songs;
            _playlistResults = playlists;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeColorService(),
      builder: (context, _) {
        final p = ThemeColorService().palette;

        final filteredSongs = _searchResults.where((song) {
          if (_selectedSource == null) return true;
          return song.source == _selectedSource;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Universal Search',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: p.isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.white.withOpacity(0.65),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadowDark.withOpacity(p.isDark ? 0.6 : 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: p.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search any song, artist, album in the world...',
                      hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.7), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: p.primary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: p.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _onQueryChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _onQueryChanged,
                  ),
                ),
              ),

              // Source filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSourceFilterChip(label: 'All Sources', source: null, palette: p),
                    const SizedBox(width: 8),
                    _buildSourceFilterChip(
                      label: 'YouTube Music',
                      source: MusicSource.youtube,
                      color: const Color(0xFFEF4444),
                      palette: p,
                    ),
                    const SizedBox(width: 8),
                    _buildSourceFilterChip(
                      label: 'Spotify',
                      source: MusicSource.spotify,
                      color: const Color(0xFF10B981),
                      palette: p,
                    ),
                    const SizedBox(width: 8),
                    _buildSourceFilterChip(
                      label: 'JioSaavn',
                      source: MusicSource.jiosaavn,
                      color: const Color(0xFF06B6D4),
                      palette: p,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Loading, Results, or Browse Categories
              Expanded(
                child: _isSearching
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: p.primary),
                            const SizedBox(height: 14),
                            Text(
                              'Searching across Spotify, YouTube Music & JioSaavn...',
                              style: TextStyle(color: p.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : _query.isEmpty
                        ? _buildBrowseCategories(p)
                        : _buildSearchResults(filteredSongs, p),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceFilterChip({
    required String label,
    required MusicSource? source,
    Color? color,
    required SongColorPalette palette,
  }) {
    final isSelected = _selectedSource == source;
    final activeColor = color ?? palette.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSource = source;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : palette.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : palette.textSecondary.withOpacity(0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (palette.isDark ? Colors.white : activeColor) : palette.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Song> songs, SongColorPalette p) {
    final filteredPlaylists = _playlistResults.where((pl) {
      if (_selectedSource == null) return true;
      return pl.source == _selectedSource;
    }).toList();

    if (songs.isEmpty && filteredPlaylists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: p.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No results found for "$_query"',
              style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with another keyword or select All Sources',
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 1. Multi-source Playlists & Mixes (YouTube Music, Spotify, JioSaavn)
        if (filteredPlaylists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Playlists & Mixes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${filteredPlaylists.length} Available',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildPlaylistsCarousel(filteredPlaylists, p),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],

        // 2. Tracks & Singles Section Header
        if (songs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tracks & Singles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    '${songs.length} Tracks',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Songs List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final song = songs[i];
              final isCurrent = song.id == widget.state.currentSong?.id;

              return SongTile(
                song: song,
                isCurrent: isCurrent,
                isPlaying: widget.state.isPlaying && isCurrent,
                isLiked: widget.state.isSongLiked(song.id),
                onTap: () => _handleSongTap(song, songs, p),
                onLikeTap: () => widget.state.toggleLike(song.id),
              );
            },
            childCount: songs.length,
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 140),
        ),
      ],
    );
  }

  /// Horizontal Carousel for YouTube Music, Spotify & JioSaavn Playlists
  Widget _buildPlaylistsCarousel(List<Playlist> playlists, SongColorPalette p) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final pl = playlists[i];
          final Color badgeColor;
          final String badgeText;

          switch (pl.source) {
            case MusicSource.youtube:
              badgeColor = const Color(0xFFEF4444);
              badgeText = 'YOUTUBE MUSIC';
              break;
            case MusicSource.spotify:
              badgeColor = const Color(0xFF10B981);
              badgeText = 'SPOTIFY';
              break;
            case MusicSource.jiosaavn:
              badgeColor = const Color(0xFF06B6D4);
              badgeText = 'JIOSAAVN';
              break;
            default:
              badgeColor = const Color(0xFF8B5CF6);
              badgeText = 'PLAYLIST';
          }

          return Container(
            width: 155,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: p.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.shadowDark.withOpacity(p.isDark ? 0.5 : 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showPlaylistModal(context, pl, p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          pl.coverUrl,
                          height: 125,
                          width: 135,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 125,
                            width: 135,
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.queue_music_rounded, color: badgeColor, size: 36),
                          ),
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
                            badgeText,
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
                            if (pl.songs.isNotEmpty) {
                              widget.state.playPlaylist(pl);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Playing ${pl.title} (${pl.source.displayName})'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.surface.withOpacity(0.92),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pl.title,
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
                    '${pl.songs.length} Tracks • ${pl.source.displayName}',
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
            ),
          );
        },
      ),
    );
  }

  /// Full Playlist / Album Exploration Modal with Play Choice
  void _showPlaylistModal(BuildContext context, Playlist playlist, SongColorPalette p) {
    final Color badgeColor;
    switch (playlist.source) {
      case MusicSource.youtube:
        badgeColor = const Color(0xFFEF4444);
        break;
      case MusicSource.spotify:
        badgeColor = const Color(0xFF10B981);
        break;
      case MusicSource.jiosaavn:
        badgeColor = const Color(0xFF06B6D4);
        break;
      default:
        badgeColor = const Color(0xFF8B5CF6);
    }

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
                      playlist.coverUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.music_note_rounded, color: badgeColor, size: 32),
                      ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${playlist.songs.length} Tracks • ${playlist.source.displayName}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
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
                  if (playlist.songs.isNotEmpty) {
                    widget.state.playPlaylist(playlist);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badgeColor, badgeColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'PLAY FULL PLAYLIST (${playlist.source.displayName.toUpperCase()})',
                        style: const TextStyle(
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
                                errorBuilder: (_, __, ___) => Container(
                                  width: 42,
                                  height: 42,
                                  color: Colors.white12,
                                  child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
                                ),
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
                              song.formattedDuration,
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

  /// Handle song tap: plays song with full queue or lets user pick
  void _handleSongTap(Song song, List<Song> allSongs, SongColorPalette p) {
    widget.state.playSong(song, newQueue: allSongs);
  }

  Widget _buildBrowseCategories(SongColorPalette p) {
    final categories = [
      {'name': 'Top Global 2026', 'query': 'Top Global Hits 2026', 'color': 0xFF6366F1, 'icon': Icons.public_rounded},
      {'name': 'Bollywood & Desi', 'query': 'Arijit Singh Pritam Hits', 'color': 0xFFF59E0B, 'icon': Icons.music_note_rounded},
      {'name': 'Synthwave & Retro', 'query': 'Synthwave Electronic Hits', 'color': 0xFFEC4899, 'icon': Icons.nightlife_rounded},
      {'name': 'Pop & Trending', 'query': 'Dua Lipa Weeknd Pop', 'color': 0xFF10B981, 'icon': Icons.trending_up_rounded},
      {'name': 'Lo-Fi Chill Beats', 'query': 'Lofi Chill Study', 'color': 0xFF06B6D4, 'icon': Icons.cloud_rounded},
      {'name': 'Workout & Energy', 'query': 'Workout Energy Rock', 'color': 0xFFEF4444, 'icon': Icons.fitness_center_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(
          'Quick Search Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            final color = Color(cat['color'] as int);

            return InkWell(
              onTap: () {
                _searchController.text = cat['name'] as String;
                _onQueryChanged(cat['query'] as String);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat['name'] as String,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
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
}
