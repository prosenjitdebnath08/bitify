import 'package:flutter/material.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';
import '../services/music_api_service.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/neumorphic_box.dart';
import '../widgets/song_tile.dart';

class ExploreScreen extends StatefulWidget {
  final MusicPlayerState state;

  const ExploreScreen({super.key, required this.state});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All'; // 'All', 'Bollywood', 'Hollywood', 'Bengali', 'Pop', 'Synthwave'
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _activeSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _activeSearchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeSearchQuery = clean;
    });

    try {
      final results = await MusicApiService.searchOnline(clean, limit: 30);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractArtistsFromResults(List<Song> songs) {
    final Map<String, List<Song>> artistMap = {};
    for (final s in songs) {
      final primary = s.artist.split(RegExp(r'[,&]')).first.trim();
      if (primary.isNotEmpty) {
        artistMap.putIfAbsent(primary, () => []).add(s);
      }
    }
    return artistMap.entries.map((e) {
      return {
        'name': e.key,
        'image': e.value.first.coverUrl,
        'songs': e.value,
      };
    }).take(6).toList();
  }

  List<Playlist> _generatePlaylistsFromResults(String query, List<Song> songs) {
    if (songs.isEmpty) return [];
    final List<Playlist> list = [];

    // 1. Essentials Playlist
    list.add(
      Playlist(
        id: 'search_pl_essentials',
        title: '$query Essentials',
        description: 'Complete collection of $query chartbusters & hits',
        coverUrl: songs.first.coverUrl,
        songs: songs,
      ),
    );

    // 2. Radio / Flow Playlist
    if (songs.length > 2) {
      list.add(
        Playlist(
          id: 'search_pl_radio',
          title: '$query Radio Mix',
          description: 'Continuous algorithmic flow inspired by $query',
          coverUrl: songs.length > 1 ? songs[1].coverUrl : songs.first.coverUrl,
          songs: songs.reversed.toList(),
        ),
      );
    }

    // 3. Artist Collection
    final artists = _extractArtistsFromResults(songs);
    if (artists.isNotEmpty && (artists.first['songs'] as List<Song>).length > 1) {
      final a = artists.first;
      list.add(
        Playlist(
          id: 'search_pl_artist',
          title: '${a['name']} Hits',
          description: 'Best songs by ${a['name']} on Spotify & JioSaavn',
          coverUrl: a['image'] as String,
          songs: a['songs'] as List<Song>,
        ),
      );
    }

    return list;
  }

  void _onCategoryTapped(String cat) {
    setState(() {
      _selectedCategory = cat;
    });

    if (cat == 'Bollywood') {
      _performSearch('Bollywood Top Hits');
    } else if (cat == 'Hollywood') {
      _performSearch('The Weeknd Dua Lipa Pop Hits');
    } else if (cat == 'Bengali') {
      _performSearch('Bengali Hits Arijit Singh');
    } else if (cat == 'Pop') {
      _performSearch('Pop Hits Spotify');
    } else if (cat == 'Synthwave') {
      _performSearch('Synthwave Retro Cyberpunk');
    } else {
      setState(() {
        _searchResults = [];
        _activeSearchQuery = '';
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = widget.state.onlineTrending.isNotEmpty
        ? widget.state.onlineTrending
        : MockMusicRepository.allSongs;
    final artists = MockMusicRepository.artists;
    final albums = MockMusicRepository.albums;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.state, ThemeColorService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              // Top Title App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: p.surface.withOpacity(0.85),
                elevation: 0,
                title: Text(
                  'Explore & Search',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),

              // Search Bar & Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      // Universal Live Search Bar
                      NeumorphicBox(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: p.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search_rounded, color: p.primary, size: 22),
                            hintText: 'Search Bollywood, Hollywood, Bengali songs...',
                            hintStyle: TextStyle(
                              color: p.textSecondary.withOpacity(0.8),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: p.textSecondary, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _activeSearchQuery = '';
                                        _isSearching = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: _performSearch,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Pills (Spotify & JioSaavn style)
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final cat in ['All', 'Bollywood', 'Hollywood', 'Bengali', 'Pop', 'Synthwave'])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _onCategoryTapped(cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == cat
                                          ? p.primary.withOpacity(0.2)
                                          : p.surface,
                                      borderRadius: BorderRadius.circular(17),
                                      border: Border.all(
                                        color: _selectedCategory == cat
                                            ? p.primary
                                            : p.textSecondary.withOpacity(0.2),
                                        width: _selectedCategory == cat ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: _selectedCategory == cat
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: _selectedCategory == cat
                                              ? p.primary
                                              : p.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Search Results View (Artists, Playlists, and Single Songs)
              if (_isSearching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: p.primary),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Results for "$_activeSearchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              '${_searchResults.length} Tracks',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: p.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 1. MATCHING ARTISTS SECTION
                        () {
                          final matchingArtists = _extractArtistsFromResults(_searchResults);
                          if (matchingArtists.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Artists',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 110,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: matchingArtists.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                                  itemBuilder: (context, idx) {
                                    final art = matchingArtists[idx];
                                    final artSongs = art['songs'] as List<Song>;

                                    return GestureDetector(
                                      onTap: () {
                                        final pl = Playlist(
                                          id: 'art_${art['name']}',
                                          title: '${art['name']} Collection',
                                          description: '${artSongs.length} songs by ${art['name']}',
                                          coverUrl: art['image'] as String,
                                          songs: artSongs,
                                        );
                                        widget.state.playPlaylist(pl);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Playing ${art['name']} playlist (Continuous Flow)'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 66,
                                            height: 66,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: p.primary.withOpacity(0.5),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: p.glow.withOpacity(0.25),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                art['image'] as String,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(Icons.person, color: p.textSecondary),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: 76,
                                            child: Text(
                                              art['name'] as String,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Artist • ${artSongs.length} Tracks',
                                            style: TextStyle(fontSize: 9, color: p.textSecondary),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }(),

                        // 2. MATCHING PLAYLISTS SECTION
                        () {
                          final searchPlaylists = _generatePlaylistsFromResults(_activeSearchQuery, _searchResults);
                          if (searchPlaylists.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Playlists for "$_activeSearchQuery"',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Continuous Play',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1DB954),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: searchPlaylists.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                                  itemBuilder: (context, idx) {
                                    final pl = searchPlaylists[idx];

                                    return NeumorphicBox(
                                      width: 140,
                                      borderRadius: 18,
                                      padding: const EdgeInsets.all(8),
                                      onTap: () {
                                        widget.state.playPlaylist(pl);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Playing playlist: ${pl.title} (Plays full list)'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: Image.network(
                                                  pl.coverUrl,
                                                  width: 124,
                                                  height: 105,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(width: 124, height: 105, color: Colors.white12),
                                                ),
                                              ),
                                              Positioned(
                                                top: 6,
                                                left: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1DB954),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: const Text(
                                                    'PLAYLIST',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 7,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 6,
                                                right: 6,
                                                child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: p.surface.withOpacity(0.9),
                                                  ),
                                                  child: Icon(Icons.play_arrow_rounded, color: p.primary, size: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            pl.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: p.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${pl.songs.length} Tracks • Playlist',
                                            style: TextStyle(fontSize: 10, color: p.textSecondary),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }(),

                        // 3. SINGLE SONGS SECTION (Stops after track completes)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Single Songs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'STOPS AFTER TRACK',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final song in _searchResults) ...[
                          SongTile(
                            song: song,
                            isCurrent: song.id == widget.state.currentSong?.id,
                            isPlaying: widget.state.isPlaying && song.id == widget.state.currentSong?.id,
                            isLiked: widget.state.isSongLiked(song.id),
                            onTap: () {
                              widget.state.playSingleSong(song);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Playing "${song.title}" (Single Song Mode)'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            onLikeTap: () => widget.state.toggleLike(song.id),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                )
              else
                // Default Explore Screen Sections
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Charts Horizontal
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Top Charts (Spotify & JioSaavn)',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'LIVE SYNC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: p.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 150,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildChartCard(
                                title: 'Bollywood Top 50',
                                platform: 'JioSaavn Desi',
                                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                icon: Icons.music_note_rounded,
                                onTap: () {
                                  _performSearch('Bollywood Hits');
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildChartCard(
                                title: 'Spotify Global 50',
                                platform: 'Spotify Direct',
                                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                                icon: Icons.graphic_eq_rounded,
                                onTap: () {
                                  _performSearch('Hollywood Top Hits');
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildChartCard(
                                title: 'Bangla Top Hits',
                                platform: 'Bengali Radar',
                                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)]),
                                icon: Icons.library_music_rounded,
                                onTap: () {
                                  _performSearch('Bengali Hits');
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildChartCard(
                                title: 'Synthwave Nights',
                                platform: 'Cyberpunk Retrowave',
                                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                                icon: Icons.nightlife_rounded,
                                onTap: () {
                                  _performSearch('Synthwave Retro');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 2. Browse Categories (Spotify / JioSaavn Style Tiles)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Browse Genres & Languages',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                            children: [
                              _buildBrowseTile('Bollywood Romance', Icons.favorite_rounded, const Color(0xFFEF4444), () {
                                _performSearch('Bollywood Romance Hits');
                              }),
                              _buildBrowseTile('Hollywood Pop', Icons.star_rounded, const Color(0xFF8B5CF6), () {
                                _performSearch('Hollywood Pop Dua Lipa');
                              }),
                              _buildBrowseTile('Bengali Melodies', Icons.audiotrack_rounded, const Color(0xFF10B981), () {
                                _performSearch('Bengali Hits Arijit Singh');
                              }),
                              _buildBrowseTile('Synthwave Retro', Icons.bolt_rounded, const Color(0xFFEC4899), () {
                                _performSearch('Synthwave The Weeknd');
                              }),
                              _buildBrowseTile('Desi Party Mix', Icons.celebration_rounded, const Color(0xFFF59E0B), () {
                                _performSearch('Desi Party Dance');
                              }),
                              _buildBrowseTile('Lo-Fi & Study', Icons.headphones_rounded, const Color(0xFF06B6D4), () {
                                _performSearch('Lo-Fi Chill Focus');
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 3. Spotlight Artists
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Spotlight Artists',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: artists.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, i) {
                              final artist = artists[i];
                              return GestureDetector(
                                onTap: () => _performSearch(artist.name),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: p.primary.withOpacity(0.5),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: p.glow.withOpacity(0.3),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          artist.avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.person, color: p.textSecondary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      artist.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      artist.genres.isNotEmpty ? artist.genres.first : 'Artist',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. Albums & EPs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Trending Albums & EPs',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 170,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: albums.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, i) {
                              final album = albums[i];
                              return GestureDetector(
                                onTap: () {
                                  if (album.songs.isNotEmpty) {
                                    widget.state.playSong(album.songs.first, newQueue: album.songs);
                                  }
                                },
                                child: SizedBox(
                                  width: 130,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          album.coverUrl,
                                          width: 130,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        album.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        album.artist,
                                        maxLines: 1,
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
                        const SizedBox(height: 24),

                        // 5. Viral Radar Tracks
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Explore Recommendations',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...allSongs.take(6).map((song) {
                          final isCurrent = song.id == widget.state.currentSong?.id;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: SongTile(
                              song: song,
                              isCurrent: isCurrent,
                              isPlaying: widget.state.isPlaying && isCurrent,
                              isLiked: widget.state.isSongLiked(song.id),
                              onTap: () => widget.state.playSong(song),
                              onLikeTap: () => widget.state.toggleLike(song.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard({
    required String title,
    required String platform,
    required LinearGradient gradient,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
          ],
        ),
      ),
    );
  }
}
