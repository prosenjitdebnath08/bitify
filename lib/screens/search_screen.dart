import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = MockMusicRepository.allSongs;
    final filteredSongs = allSongs.where((song) {
      final matchesQuery = _query.isEmpty ||
          song.title.toLowerCase().contains(_query.toLowerCase()) ||
          song.artist.toLowerCase().contains(_query.toLowerCase()) ||
          song.album.toLowerCase().contains(_query.toLowerCase());

      final matchesSource = _selectedSource == null || song.source == _selectedSource;

      return matchesQuery && matchesSource;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Universal Search',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums, or lyrics...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryLight),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) {
                  setState(() => _query = val);
                },
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
                _buildSourceFilterChip(label: 'All Sources', source: null),
                const SizedBox(width: 8),
                _buildSourceFilterChip(
                  label: 'YouTube Music',
                  source: MusicSource.youtube,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _buildSourceFilterChip(
                  label: 'Spotify',
                  source: MusicSource.spotify,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildSourceFilterChip(
                  label: 'JioSaavn',
                  source: MusicSource.jiosaavn,
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Results or Browse Categories
          Expanded(
            child: _query.isEmpty
                ? _buildBrowseCategories()
                : _buildSearchResults(filteredSongs),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFilterChip({
    required String label,
    required MusicSource? source,
    Color? color,
  }) {
    final isSelected = _selectedSource == source;
    final activeColor = color ?? AppTheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSource = source;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.1),
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
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Song> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No results found for "$_query"',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try searching with a different keyword or source filter',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
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

  Widget _buildBrowseCategories() {
    final categories = [
      {'name': 'Podcasts', 'color': 0xFF6366F1, 'icon': Icons.podcasts_rounded},
      {'name': 'Bollywood & Punjabi', 'color': 0xFFF59E0B, 'icon': Icons.music_note_rounded},
      {'name': 'Synthwave & Retro', 'color': 0xFFEC4899, 'icon': Icons.nightlife_rounded},
      {'name': 'Indie & Alternative', 'color': 0xFF10B981, 'icon': Icons.eco_rounded},
      {'name': 'Gaming Beats', 'color': 0xFF06B6D4, 'icon': Icons.sports_esports_rounded},
      {'name': 'Workout & Energy', 'color': 0xFFEF4444, 'icon': Icons.fitness_center_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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

            return Container(
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
