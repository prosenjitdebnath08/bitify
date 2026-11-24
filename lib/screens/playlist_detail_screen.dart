import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/music_models.dart';
import '../services/download_service.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/bitchord_card_motion.dart';
import '../widgets/mini_player_bar.dart';

/// Full-screen BitChord v1.9 playlist detail screen:
/// - Replicates BitChord's DetailScreen architecture (ReleaseHeader, PageBackground wash, ActionRow, ActionPills, DetailSearchField, CompactSongRow)
/// - Dynamic wash backdrop derived from artwork palette with scroll-reactive opacity
/// - Large glowing PlayCircle and neumorphic glass ActionPills
/// - Real-time inline search/filter
/// - Animated equalizer on the currently playing track
class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final MusicPlayerState state;
  final SongColorPalette? initialPalette;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.state,
    this.initialPalette,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  SongColorPalette? _extractedPalette;
  bool _showInlineSearch = false;
  String _searchQuery = '';
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _extractPalette();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  Future<void> _extractPalette() async {
    if (widget.initialPalette != null) return;
    try {
      final palette = await ThemeColorService().extractPaletteFromUrl(
        widget.playlist.coverUrl,
        ThemeColorService().themeMode,
      );
      if (mounted) {
        setState(() {
          _extractedPalette = palette;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  SongColorPalette get _activePalette =>
      _extractedPalette ?? widget.initialPalette ?? ThemeColorService().palette;

  String _formatTotalDuration(List<Song> songs) {
    final totalSec = songs.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    if (totalSec <= 0) return '0 min';
    final mins = totalSec ~/ 60;
    if (mins < 60) {
      return '$mins mins';
    }
    final hrs = mins ~/ 60;
    final remainingMins = mins % 60;
    return remainingMins > 0 ? '${hrs}h ${remainingMins}m' : '${hrs}h';
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  List<Song> get _filteredSongs {
    if (_searchQuery.trim().isEmpty) {
      return widget.playlist.songs;
    }
    final q = _searchQuery.trim().toLowerCase();
    return widget.playlist.songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = _activePalette;
    final songs = _filteredSongs;
    final isPlayingThisPlaylist = widget.state.isPlaying &&
        widget.playlist.songs.any((s) => s.id == widget.state.currentSong?.id);

    // Calculate wash fade based on scroll: BitChord fades out wash at ~280-340px
    final washOpacity = (1.0 - (_scrollOffset / 320.0)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          // 1. BitChord PageBackground Dynamic Wash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 440,
            child: Opacity(
              opacity: washOpacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.primary.withOpacity(0.42),
                      p.accent.withOpacity(0.24),
                      p.background.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Scrollable View with Parallax Header
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: _buildTopBar(p),
                ),

                // BitChord ReleaseHeader (Artwork Sleeve, Title, Curator, Meta)
                SliverToBoxAdapter(
                  child: _buildReleaseHeader(p, songs),
                ),

                // BitChord ActionRow (PlayCircle + ActionPills)
                SliverToBoxAdapter(
                  child: _buildActionRow(p, isPlayingThisPlaylist),
                ),

                // Optional DetailSearchField
                if (_showInlineSearch)
                  SliverToBoxAdapter(
                    child: _buildDetailSearchField(p),
                  ),

                // Track Count / Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'MATCHING TRACKS (${songs.length})'
                              : 'TRACKLIST',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: p.textSecondary.withOpacity(0.85),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // BitChord CompactSongRow List
                if (songs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No songs found for "$_searchQuery"'
                              : 'No tracks in this playlist yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = songs[index];
                        final isCurrentlyPlaying =
                            widget.state.currentSong?.id == song.id;

                        return _buildCompactSongRow(
                          song: song,
                          index: index,
                          palette: p,
                          isCurrentlyPlaying: isCurrentlyPlaying,
                        );
                      },
                      childCount: songs.length,
                    ),
                  ),

                // Bottom spacer for MiniPlayerBar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),

          // 3. Bottom Mini Player Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: MiniPlayerBar(state: widget.state),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Nav Bar with Translucent Pill Back Button & Options
  Widget _buildTopBar(SongColorPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: p.textPrimary,
              ),
            ),
          ),

          // Header Title when scrolled down
          if (_scrollOffset > 180)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          // More Options Button
          GestureDetector(
            onTap: () => _showPlaylistOptionsMenu(p),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// BitChord ReleaseHeader (Artwork Sleeve, Title, Subtitle, Stats)
  Widget _buildReleaseHeader(SongColorPalette p, List<Song> songs) {
    final totalDuration = _formatTotalDuration(widget.playlist.songs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Sleeve Cover Artwork with BitChord CardMotion & shadow
          BitChordCardMotion(
            borderRadius: 22,
            glowColor: p.primary,
            isPlaying: widget.state.isPlaying &&
                widget.playlist.songs.any((s) => s.id == widget.state.currentSong?.id),
            onTap: () {
              if (widget.playlist.songs.isNotEmpty) {
                widget.state.playPlaylist(widget.playlist);
              }
            },
            child: Container(
              width: 195,
              height: 195,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Image.network(
                  widget.playlist.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: p.surface,
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 64,
                        color: p.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Playlist Title
          Text(
            widget.playlist.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: p.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // Curator Tag / Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getSourceBadgeColor(widget.playlist.source),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: _getSourceBadgeColor(widget.playlist.source).withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  _getSourceBadgeLabel(widget.playlist.source),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.playlist.description.isNotEmpty
                      ? widget.playlist.description
                      : 'Curated Bitify Music Flow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Metadata Chips (Track Count · Duration · Lossless)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.playlist.songs.length} Tracks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary.withOpacity(0.9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
              Text(
                totalDuration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary.withOpacity(0.9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: p.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: p.accent.withOpacity(0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'LOSSLESS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: p.accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// BitChord ActionRow (PlayCircle + ActionPills)
  Widget _buildActionRow(SongColorPalette p, bool isPlayingThisPlaylist) {
    final downloadService = DownloadService();
    final allDownloaded = widget.playlist.songs.isNotEmpty &&
        widget.playlist.songs.every((s) => downloadService.isDownloaded(s.id));
    final anyDownloading = widget.playlist.songs.any((s) => downloadService.isDownloading(s.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. BitChord PlayCircle (Primary Accent Action)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (isPlayingThisPlaylist) {
                widget.state.togglePlayPause();
              } else if (widget.playlist.songs.isNotEmpty) {
                widget.state.playPlaylist(widget.playlist);
              }
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    p.accent,
                    p.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.accent.withOpacity(0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isPlayingThisPlaylist
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // 2. Shuffle ActionPill
          _buildActionPill(
            icon: Icons.shuffle_rounded,
            label: 'Shuffle',
            palette: p,
            isActive: widget.state.isShuffle,
            onTap: () {
              HapticFeedback.lightImpact();
              if (!widget.state.isShuffle) {
                widget.state.toggleShuffle();
              }
              if (widget.playlist.songs.isNotEmpty) {
                final shuffledList = List<Song>.from(widget.playlist.songs)..shuffle();
                widget.state.playSong(shuffledList.first, newQueue: shuffledList);
              }
            },
          ),

          const SizedBox(width: 10),

          // 3. Download All ActionPill
          _buildActionPill(
            icon: anyDownloading
                ? Icons.hourglass_top_rounded
                : (allDownloaded ? Icons.check_circle_rounded : Icons.download_rounded),
            label: allDownloaded ? 'Saved' : (anyDownloading ? 'Saving...' : 'Download'),
            palette: p,
            isActive: allDownloaded,
            onTap: () {
              HapticFeedback.selectionClick();
              if (allDownloaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All songs in this playlist are already downloaded!')),
                );
              } else {
                for (final song in widget.playlist.songs) {
                  downloadService.startDownload(song);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${widget.playlist.songs.length} tracks to offline vault...'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                setState(() {});
              }
            },
          ),

          const SizedBox(width: 10),

          // 4. Search Filter Pill
          _buildActionPill(
            icon: Icons.search_rounded,
            label: '',
            palette: p,
            isActive: _showInlineSearch,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showInlineSearch = !_showInlineSearch;
                if (_showInlineSearch) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                } else {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchFocusNode.unfocus();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  /// BitChord ActionPill widget
  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required SongColorPalette palette,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: label.isNotEmpty ? 14 : 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.14),
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.black : palette.textPrimary,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.black : palette.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// BitChord DetailSearchField (Inline dynamic playlist filter)
  Widget _buildDetailSearchField(SongColorPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: p.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: p.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search songs in this playlist...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: p.textSecondary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: p.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// BitChord CompactSongRow
  Widget _buildCompactSongRow({
    required Song song,
    required int index,
    required SongColorPalette palette,
    required bool isCurrentlyPlaying,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.state.playSong(song, newQueue: widget.playlist.songs);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isCurrentlyPlaying
                  ? palette.accent.withOpacity(0.12)
                  : Colors.transparent,
              border: isCurrentlyPlaying
                  ? Border.all(
                      color: palette.accent.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Track Index or Animated Equalizer
                SizedBox(
                  width: 24,
                  child: isCurrentlyPlaying && widget.state.isPlaying
                      ? _buildPlayingEqualizer(palette.accent)
                      : Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCurrentlyPlaying
                                ? palette.accent
                                : palette.textSecondary.withOpacity(0.6),
                          ),
                        ),
                ),

                const SizedBox(width: 8),

                // Song Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song.coverUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: palette.surface,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: palette.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Song Title & Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrentlyPlaying
                              ? palette.accent
                              : palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${song.artist}${song.album.isNotEmpty ? ' • ${song.album}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Duration
                Text(
                  _formatDuration(song.durationSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary.withOpacity(0.7),
                  ),
                ),

                const SizedBox(width: 4),

                // 3-dots Menu
                GestureDetector(
                  onTap: () => _showSongOptionsMenu(song, palette),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: palette.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Animated 3-bar equalizer for active playing song
  Widget _buildPlayingEqualizer(Color color) {
    return _EqualizerAnimation(color: color);
  }

  /// Song Options Bottom Sheet (BitChord style)
  void _showSongOptionsMenu(Song song, SongColorPalette p) {
    final downloadService = DownloadService();
    final isDownloaded = downloadService.isDownloaded(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Song Info Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      song.coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),

              // Actions
              ListTile(
                dense: true,
                leading: Icon(Icons.queue_play_next_rounded, color: p.accent),
                title: Text('Play Next', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.state.addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${song.title}" to play next')),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.playlist_add_rounded, color: p.primary),
                title: Text('Add to Queue', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.state.addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  isDownloaded ? Icons.delete_outline_rounded : Icons.download_rounded,
                  color: isDownloaded ? Colors.redAccent : p.accent,
                ),
                title: Text(
                  isDownloaded ? 'Remove from Offline Downloads' : 'Download Offline',
                  style: TextStyle(
                    color: isDownloaded ? Colors.redAccent : p.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isDownloaded) {
                    downloadService.deleteSong(song.id);
                  } else {
                    downloadService.startDownload(song);
                  }
                  setState(() {});
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.favorite_rounded,
                  color: widget.state.isSongLiked(song.id) ? Colors.redAccent : p.textSecondary,
                ),
                title: Text(
                  widget.state.isSongLiked(song.id) ? 'Remove from Favorites' : 'Add to Favorites',
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.state.toggleLike(song.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Playlist Options Bottom Sheet (BitChord style)
  void _showPlaylistOptionsMenu(SongColorPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.playlist.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),

              ListTile(
                dense: true,
                leading: Icon(Icons.playlist_play_rounded, color: p.accent),
                title: Text('Play All with Bitify Flow', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.playlist.songs.isNotEmpty) {
                    widget.state.playPlaylist(widget.playlist);
                  }
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.queue_music_rounded, color: p.primary),
                title: Text('Add Entire Playlist to Queue', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.state.addAllToQueue(widget.playlist.songs);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${widget.playlist.songs.length} tracks to queue')),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.download_for_offline_rounded, color: p.accent),
                title: Text('Download Entire Playlist', style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  final downloadService = DownloadService();
                  for (final song in widget.playlist.songs) {
                    downloadService.startDownload(song);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Started download of ${widget.playlist.songs.length} tracks')),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSourceBadgeColor(MusicSource source) {
    switch (source) {
      case MusicSource.spotify:
        return const Color(0xFF1DB954);
      case MusicSource.jiosaavn:
        return const Color(0xFF2BC5B4);
      case MusicSource.youtube:
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF0284C7);
    }
  }

  String _getSourceBadgeLabel(MusicSource source) {
    switch (source) {
      case MusicSource.spotify:
        return 'SPOTIFY CURATED';
      case MusicSource.jiosaavn:
        return 'JIOSAAVN CURATED';
      case MusicSource.youtube:
        return 'YOUTUBE MUSIC';
      default:
        return 'BITIFY FLOW';
    }
  }
}

/// Animated 3-bar equalizer widget
class _EqualizerAnimation extends StatefulWidget {
  final Color color;

  const _EqualizerAnimation({required this.color});

  @override
  State<_EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<_EqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final val = _ctrl.value;
        final h1 = 6.0 + 8.0 * math.sin(val * math.pi);
        final h2 = 4.0 + 10.0 * math.sin((val + 0.3) * math.pi);
        final h3 = 5.0 + 9.0 * math.sin((val + 0.6) * math.pi);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(h1),
            const SizedBox(width: 2),
            _buildBar(h2),
            const SizedBox(width: 2),
            _buildBar(h3),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 15.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
