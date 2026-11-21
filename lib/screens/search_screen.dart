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
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await MusicApiService.searchOnline(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
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
    if (songs.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150),
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final song = songs[i];
        final isCurrent = song.id == widget.state.currentSong?.id;

        return SongTile(
          song: song,
          isCurrent: isCurrent,
          isPlaying: widget.state.isPlaying && isCurrent,
          isLiked: widget.state.isSongLiked(song.id),
          onTap: () => widget.state.playSong(song, newQueue: songs),
          onLikeTap: () => widget.state.toggleLike(song.id),
        );
      },
    );
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
