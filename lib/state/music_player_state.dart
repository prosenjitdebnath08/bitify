import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_models.dart';
import '../data/mock_music_repository.dart';
import '../services/audio_dsp_service.dart';
import '../services/music_api_service.dart';
import '../services/spotify_algorithm_service.dart';
import '../services/theme_color_service.dart';
import '../services/youtube_service.dart';

enum BitifyRepeatMode { off, all, one }

class MusicPlayerState extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Song? _currentSong;
  String? _resolvedAudioUrl;
  String? _currentYoutubeVideoUrl;
  String? get currentYoutubeVideoUrl => _currentYoutubeVideoUrl;
  bool _isPlaying = false;
  int _positionSeconds = 0;
  int _durationSeconds = 0;
  bool _isShuffle = false;
  BitifyRepeatMode _repeatMode = BitifyRepeatMode.all;
  bool _spotifyAlgorithmEnabled = true;
  List<Song> _queue = [];
  final List<Song> _history = [];
  List<Song> _onlineTrending = [];
  bool _isLoadingOnline = false;

  // Stream subscriptions
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  // Liked songs set
  final Set<String> _likedSongIds = {'s1', 's2', 's4', 's6'};

  // Single Song Playback Mode (Stop when single track completes) vs Playlist Flow
  bool _isSingleSongMode = false;
  // True when playing a user-selected Playlist (preserves exact track order on next/previous)
  bool _isPlaylistQueue = false;
  List<Song> _originalPlaylistQueue = [];
  int _playSequenceId = 0;

  bool get isPlaylistQueue => _isPlaylistQueue;

  // Categorized Catalogs and Playlists (Bollywood, Hollywood, Bengali)
  List<Song> _bollywoodSongs = [];
  List<Song> _hollywoodSongs = [];
  List<Song> _bengaliSongs = [];
  List<Playlist> _bollywoodPlaylists = [];
  List<Playlist> _hollywoodPlaylists = [];
  List<Playlist> _bengaliPlaylists = [];
  List<Playlist> _spotifyPlaylists = [];
  List<Playlist> _youtubePlaylists = [];
  List<Playlist> _jiosaavnPlaylists = [];
  List<Playlist> _customPlaylists = [];
  List<Album> _trendingAlbums = [];

  // Equalizer
  final List<String> eqFrequencies = [
    '60Hz', '170Hz', '310Hz', '600Hz', '1kHz',
    '3kHz', '6kHz', '12kHz', '14kHz', '16kHz',
  ];
  List<double> _bandGains = [2.0, 3.5, 1.0, 0.0, -1.0, 2.0, 4.0, 3.0, 2.5, 3.0];
  double _bassBoost = 0.55;
  double _virtualizer = 0.40;
  String _currentPreset = 'Bitify Dynamic';

  // Settings
  String _audioQuality = 'High Quality (256 kbps MP3)';
  int _crossfadeSeconds = 3;
  bool _gaplessPlayback = true;
  bool _normalizeVolume = true;
  int? _sleepTimerMinutes;
  Timer? _sleepTimer;

  // Connected Sources
  bool _isSpotifyConnected = true;
  bool _isYoutubeConnected = true;
  bool _isJiosaavnConnected = true;
  bool _isLastFmConnected = false;

  MusicPlayerState() {
    _queue = List.from(MockMusicRepository.allSongs);
    _bollywoodPlaylists = List.from(MockMusicRepository.bollywoodPlaylists);
    _hollywoodPlaylists = List.from(MockMusicRepository.hollywoodPlaylists);
    _bengaliPlaylists = List.from(MockMusicRepository.bengaliPlaylists);
    _customPlaylists = List.from(MockMusicRepository.playlists);
    _spotifyPlaylists = List.from(MockMusicRepository.spotifyPlaylists);
    _youtubePlaylists = [
      Playlist(
        id: 'yt_top_100',
        title: 'YouTube Top 100',
        description: 'Global streaming charts & trending music videos on YouTube.',
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
        songs: MockMusicRepository.hollywoodPlaylists.first.songs,
        source: MusicSource.youtube,
      ),
      Playlist(
        id: 'yt_lofi_chill',
        title: 'Lo-Fi Chill & Beats',
        description: 'Mellow beats, late-night study vibes & soothing rhythms.',
        coverUrl: 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=800&q=80',
        songs: MockMusicRepository.hollywoodPlaylists.length > 1
            ? MockMusicRepository.hollywoodPlaylists[1].songs
            : MockMusicRepository.allSongs,
        source: MusicSource.youtube,
      ),
      Playlist(
        id: 'yt_dance_hits',
        title: 'EDM & Dance Floor Mix',
        description: 'Electrifying club anthems & bass drops.',
        coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80',
        songs: MockMusicRepository.allSongs,
        source: MusicSource.youtube,
      ),
    ];
    _jiosaavnPlaylists = [
      Playlist(
        id: 'js_weekly_top',
        title: 'JioSaavn Weekly Top 50',
        description: 'Trending Bollywood & Indian chartbusters on JioSaavn.',
        coverUrl: MockMusicRepository.bollywoodPlaylists.first.coverUrl,
        songs: MockMusicRepository.bollywoodPlaylists.first.songs,
        source: MusicSource.jiosaavn,
      ),
      Playlist(
        id: 'js_arijit_hits',
        title: 'Arijit Singh: Romance & Soul',
        description: 'Pure acoustic feelings and soul stirring melodies.',
        coverUrl: MockMusicRepository.bollywoodPlaylists.length > 2
            ? MockMusicRepository.bollywoodPlaylists[2].coverUrl
            : MockMusicRepository.bollywoodPlaylists.first.coverUrl,
        songs: MockMusicRepository.bollywoodPlaylists.length > 2
            ? MockMusicRepository.bollywoodPlaylists[2].songs
            : MockMusicRepository.allSongs,
        source: MusicSource.jiosaavn,
      ),
      Playlist(
        id: 'js_desi_party',
        title: 'Desi Punjabi Party',
        description: 'High energy dance bangers and Punjabi pop.',
        coverUrl: MockMusicRepository.bollywoodPlaylists.length > 3
            ? MockMusicRepository.bollywoodPlaylists[3].coverUrl
            : MockMusicRepository.bollywoodPlaylists.first.coverUrl,
        songs: MockMusicRepository.bollywoodPlaylists.length > 3
            ? MockMusicRepository.bollywoodPlaylists[3].songs
            : MockMusicRepository.allSongs,
        source: MusicSource.jiosaavn,
      ),
    ];
    _trendingAlbums = List.from(MockMusicRepository.albums);

    _bollywoodSongs = MockMusicRepository.allSongs.where((s) => SpotifyAlgorithmService.normalizeLanguage(s) == 'hindi').toList();
    _hollywoodSongs = MockMusicRepository.allSongs.where((s) => SpotifyAlgorithmService.normalizeLanguage(s) == 'english').toList();
    _bengaliSongs = MockMusicRepository.allSongs.where((s) => SpotifyAlgorithmService.normalizeLanguage(s) == 'bengali').toList();

    if (_queue.isNotEmpty) {
      _currentSong = _queue.first;
      _durationSeconds = _currentSong!.durationSeconds;
      _queue = SpotifyAlgorithmService.generateAlgorithmicQueue(_currentSong!, _queue);
      ThemeColorService().updateForSong(_currentSong);
    }
    _initAudioListeners();
    _loadOnlineTrendingCatalog();
    AudioDspService.init();
  }

  void _initAudioListeners() {
    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      _positionSeconds = pos.inSeconds;
      notifyListeners();
    });

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (dur.inSeconds > 0) {
        _durationSeconds = dur.inSeconds;
        notifyListeners();
      }
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (_repeatMode == BitifyRepeatMode.one) {
        if (_currentSong?.audioUrl != null) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.resume();
        }
      } else if (_isSingleSongMode && _repeatMode == BitifyRepeatMode.off) {
        // User selected a single song: stop immediately after track finishes
        _isPlaying = false;
        _positionSeconds = 0;
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.stop();
        notifyListeners();
      } else {
        next();
      }
    });
  }

  Future<void> _loadOnlineTrendingCatalog() async {
    _isLoadingOnline = true;
    notifyListeners();

    try {
      // 1. Parallel fetch all category playlists and full albums
      final results = await Future.wait([
        // Bollywood (0..3)
        MusicApiService.fetchCategorySongs('Bollywood Hits', limit: 30),
        MusicApiService.fetchCategorySongs('Bollywood Romance', limit: 30),
        MusicApiService.fetchCategorySongs('Arijit Singh', limit: 30),
        MusicApiService.fetchCategorySongs('Desi Party', limit: 30),

        // Hollywood (4..7)
        MusicApiService.fetchCategorySongs('Pop Hits', limit: 30),
        MusicApiService.fetchCategorySongs('The Weeknd Synthwave', limit: 30),
        MusicApiService.fetchCategorySongs('Dua Lipa Pop', limit: 30),
        MusicApiService.fetchCategorySongs('Billboard Hits', limit: 30),

        // Bengali (8..10)
        MusicApiService.fetchCategorySongs('Bangla Hits', limit: 30),
        MusicApiService.fetchCategorySongs('Arijit Singh Bengali', limit: 30),
        MusicApiService.fetchCategorySongs('Anupam Roy', limit: 30),

        // Albums (11)
        _fetchCuratedAlbums(),
      ]);

      final bHits = results[0] as List<Song>;
      final bRomance = results[1] as List<Song>;
      final bArijit = results[2] as List<Song>;
      final bParty = results[3] as List<Song>;

      final hTop = results[4] as List<Song>;
      final hSynth = results[5] as List<Song>;
      final hPop = results[6] as List<Song>;
      final hBillboard = results[7] as List<Song>;

      final benTop = results[8] as List<Song>;
      final benArijit = results[9] as List<Song>;
      final benAnupam = results[10] as List<Song>;

      final loadedAlbums = results[11] as List<Album>;

      // Populate Bollywood
      if (bHits.isNotEmpty) {
        _bollywoodSongs = bHits;
        _bollywoodPlaylists = [
          Playlist(
            id: 'bp_live_top',
            title: 'Bollywood Top 50',
            description: "India's hottest romantic chartbusters and cinema anthems.",
            coverUrl: bHits.first.coverUrl,
            songs: bHits,
          ),
          if (bRomance.isNotEmpty)
            Playlist(
              id: 'bp_live_romance',
              title: 'Bollywood Romance',
              description: 'Soulful love songs, acoustic feelings and heartwarming duets.',
              coverUrl: bRomance.first.coverUrl,
              songs: bRomance,
            ),
          if (bArijit.isNotEmpty)
            Playlist(
              id: 'bp_live_arijit',
              title: 'Arijit Singh Essentials',
              description: 'The defining romantic voice of Bollywood, curated by Bitify.',
              coverUrl: bArijit.first.coverUrl,
              songs: bArijit,
            ),
          if (bParty.isNotEmpty)
            Playlist(
              id: 'bp_live_party',
              title: 'Desi Party Hits',
              description: 'High energy dance tracks, club bangers & Punjabi rhythm.',
              coverUrl: bParty.first.coverUrl,
              songs: bParty,
            ),
        ];
      }

      // Populate Hollywood
      if (hTop.isNotEmpty) {
        _hollywoodSongs = hTop;
        _hollywoodPlaylists = [
          Playlist(
            id: 'hp_live_top',
            title: "Today's Top Hits",
            description: 'The hottest global pop & international tracks on Spotify.',
            coverUrl: hTop.first.coverUrl,
            songs: hTop,
          ),
          if (hSynth.isNotEmpty)
            Playlist(
              id: 'hp_live_synth',
              title: 'Synthwave & Retro',
              description: 'Neon drenched synthwave, synthpop & late night R&B.',
              coverUrl: hSynth.first.coverUrl,
              songs: hSynth,
            ),
          if (hPop.isNotEmpty)
            Playlist(
              id: 'hp_live_pop',
              title: 'Pop Rising Hollywood',
              description: 'Global pop sensations, dance anthems & chartbusters.',
              coverUrl: hPop.first.coverUrl,
              songs: hPop,
            ),
          if (hBillboard.isNotEmpty)
            Playlist(
              id: 'hp_live_billboard',
              title: 'Billboard Hot 100',
              description: 'The definitive international weekly music chart.',
              coverUrl: hBillboard.first.coverUrl,
              songs: hBillboard,
            ),
        ];
      }

      // Populate Bengali
      if (benTop.isNotEmpty) {
        _bengaliSongs = benTop;
        _bengaliPlaylists = [
          Playlist(
            id: 'beng_live_top',
            title: 'Bangla Top Hits',
            description: 'The biggest Bengali film and indie chartbusters.',
            coverUrl: benTop.first.coverUrl,
            songs: benTop,
          ),
          if (benArijit.isNotEmpty)
            Playlist(
              id: 'beng_live_arijit',
              title: 'Arijit Bengali Melodies',
              description: 'Soulful Bengali movie hits and acoustic classics by Arijit Singh.',
              coverUrl: benArijit.first.coverUrl,
              songs: benArijit,
            ),
          if (benAnupam.isNotEmpty)
            Playlist(
              id: 'beng_live_anupam',
              title: 'Anupam Roy Essentials',
              description: 'Poetic lyrics, acoustic guitar and heart-touching stories.',
              coverUrl: benAnupam.first.coverUrl,
              songs: benAnupam,
            ),
        ];
      }

      // Populate Albums
      if (loadedAlbums.isNotEmpty) {
        _trendingAlbums = loadedAlbums;
      }

      // Populate Multi-Platform Playlists (Spotify, YouTube Music, JioSaavn)
      if (hTop.isNotEmpty || hPop.isNotEmpty) {
        final spPool = [...hTop, ...hPop, ...hSynth];
        _spotifyPlaylists = [
          Playlist(
            id: 'sp_today_top_hits',
            title: "Today's Top Hits",
            description: "Spotify's biggest global hits & chartbusters.",
            coverUrl: hTop.isNotEmpty ? hTop.first.coverUrl : spPool.first.coverUrl,
            songs: hTop.isNotEmpty ? hTop : spPool,
            source: MusicSource.spotify,
          ),
          Playlist(
            id: 'sp_pop_rising',
            title: 'Pop Rising Global',
            description: 'The next generation of pop music sensations.',
            coverUrl: hPop.isNotEmpty ? hPop.first.coverUrl : spPool.first.coverUrl,
            songs: hPop.isNotEmpty ? hPop : spPool,
            source: MusicSource.spotify,
          ),
          if (hSynth.isNotEmpty)
            Playlist(
              id: 'sp_deep_focus',
              title: 'Deep Focus & Retro Synth',
              description: 'Atmospheric electronic & late night chill soundscapes.',
              coverUrl: hSynth.first.coverUrl,
              songs: hSynth,
              source: MusicSource.spotify,
            ),
          if (bHits.isNotEmpty)
            Playlist(
              id: 'sp_hot_hits_hindi',
              title: 'Hot Hits Hindi',
              description: 'The hottest Bollywood songs in India right now on Spotify.',
              coverUrl: bHits.first.coverUrl,
              songs: bHits,
              source: MusicSource.spotify,
            ),
        ];
      }

      // Populate real YouTube playlists directly from YouTube in parallel
      final ytResults = await Future.wait([
        YouTubeService.searchSongs('top music hits 2025', limit: 15),
        YouTubeService.searchSongs('bollywood hits songs', limit: 15),
        YouTubeService.searchSongs('lofi chill beats music', limit: 15),
      ]);
      final ytTrending = ytResults[0];
      final ytBollywood = ytResults[1];
      final ytLofi = ytResults[2];

      if (ytTrending.isNotEmpty || hBillboard.isNotEmpty || bParty.isNotEmpty) {
        _youtubePlaylists = [
          Playlist(
            id: 'yt_top_charts',
            title: 'YouTube Top 100',
            description: 'Top trending tracks and viral music videos on YouTube.',
            coverUrl: ytTrending.isNotEmpty
                ? ytTrending.first.coverUrl
                : (hBillboard.isNotEmpty ? hBillboard.first.coverUrl : (hTop.isNotEmpty ? hTop.first.coverUrl : '')),
            songs: ytTrending.isNotEmpty ? ytTrending : (hBillboard.isNotEmpty ? hBillboard : hTop),
            source: MusicSource.youtube,
          ),
          if (ytBollywood.isNotEmpty || bParty.isNotEmpty)
            Playlist(
              id: 'yt_party_mix',
              title: 'Bollywood & Desi YouTube Mix',
              description: 'Trending Bollywood hits & music videos on YouTube.',
              coverUrl: ytBollywood.isNotEmpty ? ytBollywood.first.coverUrl : bParty.first.coverUrl,
              songs: ytBollywood.isNotEmpty ? ytBollywood : bParty,
              source: MusicSource.youtube,
            ),
          if (ytLofi.isNotEmpty || hSynth.isNotEmpty)
            Playlist(
              id: 'yt_lofi_mix',
              title: 'Lo-Fi Chill & Beats',
              description: 'Mellow vibes and soothing rhythms on YouTube.',
              coverUrl: ytLofi.isNotEmpty ? ytLofi.first.coverUrl : hSynth.first.coverUrl,
              songs: ytLofi.isNotEmpty ? ytLofi : hSynth,
              source: MusicSource.youtube,
            ),
        ];
      }

      if (bHits.isNotEmpty || bRomance.isNotEmpty) {
        _jiosaavnPlaylists = [
          Playlist(
            id: 'js_weekly_charts',
            title: 'JioSaavn Weekly Top 50',
            description: 'Official weekly Indian streaming chart on JioSaavn.',
            coverUrl: bHits.first.coverUrl,
            songs: bHits,
            source: MusicSource.jiosaavn,
          ),
          if (bRomance.isNotEmpty)
            Playlist(
              id: 'js_romance_melodies',
              title: 'Bollywood Romance & Heartbeats',
              description: 'Soulful love anthems and acoustic feelings.',
              coverUrl: bRomance.first.coverUrl,
              songs: bRomance,
              source: MusicSource.jiosaavn,
            ),
          if (bArijit.isNotEmpty)
            Playlist(
              id: 'js_arijit_essentials',
              title: 'Arijit Singh Essentials',
              description: 'The defining romantic voice of our generation on JioSaavn.',
              coverUrl: bArijit.first.coverUrl,
              songs: bArijit,
              source: MusicSource.jiosaavn,
            ),
          if (benTop.isNotEmpty)
            Playlist(
              id: 'js_bangla_hits',
              title: 'Bangla Top Chartbusters',
              description: 'The biggest Bengali cinema and modern hits.',
              coverUrl: benTop.first.coverUrl,
              songs: benTop,
              source: MusicSource.jiosaavn,
            ),
        ];
      }

      // Combine into _onlineTrending
      final combined = <Song>[];
      for (final s in [..._bollywoodSongs, ..._hollywoodSongs, ..._bengaliSongs]) {
        if (!combined.any((c) => c.id == s.id)) {
          combined.add(s);
        }
      }
      if (combined.isNotEmpty) {
        _onlineTrending = combined;
        final cur = _currentSong;
        if (cur != null) {
          final existingIds = _queue.map((s) => s.id).toSet();
          for (final s in combined) {
            if (!existingIds.contains(s.id) &&
                SpotifyAlgorithmService.isSameLanguage(s, cur) &&
                SpotifyAlgorithmService.isSameGenreCluster(s, cur)) {
              _queue.add(s);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading online catalog: $e');
    } finally {
      _isLoadingOnline = false;
      notifyListeners();
    }
  }

  Future<List<Album>> _fetchCuratedAlbums() async {
    try {
      const albumIds = [
        '38845390', // Brahmastra
        '38682222', // Bhediya
        '1031364',  // Jab We Met
        '23241654', // Future Nostalgia
        '19531208', // After Hours
        '14791860', // Autograph
      ];
      final albums = await Future.wait(
        albumIds.map((id) => MusicApiService.fetchAlbumById(id)),
      );
      final valid = albums.whereType<Album>().toList();
      if (valid.isNotEmpty) return valid;
    } catch (e) {
      debugPrint('Error fetching curated albums: $e');
    }
    return MockMusicRepository.albums;
  }

  // Getters
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  int get positionSeconds => _positionSeconds;
  int get durationSeconds => _durationSeconds > 0
      ? _durationSeconds
      : (_currentSong?.durationSeconds ?? 180);
  bool get isShuffle => _isShuffle;
  BitifyRepeatMode get repeatMode => _repeatMode;
  bool get spotifyAlgorithmEnabled => _spotifyAlgorithmEnabled;
  List<Song> get queue => List.unmodifiable(_queue);
  List<Song> get history => List.unmodifiable(_history);
  List<Song> get onlineTrending => List.unmodifiable(_onlineTrending.isNotEmpty ? _onlineTrending : _queue);
  List<Song> get bollywoodSongs => List.unmodifiable(_bollywoodSongs);
  List<Song> get hollywoodSongs => List.unmodifiable(_hollywoodSongs);
  List<Song> get bengaliSongs => List.unmodifiable(_bengaliSongs);
  List<Playlist> get bollywoodPlaylists => List.unmodifiable(_bollywoodPlaylists);
  List<Playlist> get hollywoodPlaylists => List.unmodifiable(_hollywoodPlaylists);
  List<Playlist> get bengaliPlaylists => List.unmodifiable(_bengaliPlaylists);
  List<Playlist> get spotifyPlaylists => List.unmodifiable(_spotifyPlaylists);
  List<Playlist> get youtubePlaylists => List.unmodifiable(_youtubePlaylists);
  List<Playlist> get jiosaavnPlaylists => List.unmodifiable(_jiosaavnPlaylists);
  List<Playlist> get customPlaylists => List.unmodifiable(_customPlaylists);
  List<Playlist> get endlessPlaylists => List.unmodifiable([
        ..._spotifyPlaylists,
        ..._youtubePlaylists,
        ..._jiosaavnPlaylists,
        ..._bollywoodPlaylists,
        ..._hollywoodPlaylists,
        ..._bengaliPlaylists,
      ]);
  List<Playlist> get allPlaylists => List.unmodifiable([
        ..._customPlaylists,
        ...MockMusicRepository.playlists,
      ]);

  // Playlist Management
  Playlist createPlaylist(String title, {String? description, Song? initialSong}) {
    final newId = 'custom_pl_${DateTime.now().millisecondsSinceEpoch}';
    final newPl = Playlist(
      id: newId,
      title: title.trim().isNotEmpty ? title.trim() : 'My Playlist',
      description: description ?? 'Created with Bitify',
      coverUrl: initialSong?.coverUrl ??
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
      songs: initialSong != null ? [initialSong] : [],
      isCustom: true,
      source: MusicSource.spotify,
    );
    _customPlaylists.insert(0, newPl);
    notifyListeners();
    return newPl;
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final pl = _customPlaylists[idx];
      if (!pl.songs.any((s) => s.id == song.id)) {
        final updatedSongs = [...pl.songs, song];
        _customPlaylists[idx] = Playlist(
          id: pl.id,
          title: pl.title,
          description: pl.description,
          coverUrl: pl.coverUrl.isEmpty ? song.coverUrl : pl.coverUrl,
          songs: updatedSongs,
          isCustom: pl.isCustom,
          source: pl.source,
        );
        notifyListeners();
      }
    } else {
      final mockIdx = MockMusicRepository.playlists.indexWhere((p) => p.id == playlistId);
      if (mockIdx != -1) {
        final pl = MockMusicRepository.playlists[mockIdx];
        if (!pl.songs.any((s) => s.id == song.id)) {
          final updatedSongs = [...pl.songs, song];
          _customPlaylists.add(Playlist(
            id: pl.id,
            title: pl.title,
            description: pl.description,
            coverUrl: pl.coverUrl,
            songs: updatedSongs,
            isCustom: true,
            source: pl.source,
          ));
          notifyListeners();
        }
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final pl = _customPlaylists[idx];
      final updatedSongs = pl.songs.where((s) => s.id != songId).toList();
      _customPlaylists[idx] = Playlist(
        id: pl.id,
        title: pl.title,
        description: pl.description,
        coverUrl: pl.coverUrl,
        songs: updatedSongs,
        isCustom: pl.isCustom,
        source: pl.source,
      );
      notifyListeners();
    }
  }

  bool isSongInPlaylist(String playlistId, String songId) {
    final pl = _customPlaylists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => MockMusicRepository.playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => const Playlist(id: '', title: '', description: '', coverUrl: ''),
      ),
    );
    return pl.songs.any((s) => s.id == songId);
  }

  void deletePlaylist(String playlistId) {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }
  List<Album> get trendingAlbums => List.unmodifiable(_trendingAlbums.isNotEmpty ? _trendingAlbums : MockMusicRepository.albums);
  bool get isLoadingOnline => _isLoadingOnline;
  List<double> get bandGains => List.unmodifiable(_bandGains);
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  String get currentPreset => _currentPreset;
  String get audioQuality => _audioQuality;
  int get crossfadeSeconds => _crossfadeSeconds;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get normalizeVolume => _normalizeVolume;
  int? get sleepTimerMinutes => _sleepTimerMinutes;
  bool get isSpotifyConnected => _isSpotifyConnected;
  bool get isYoutubeConnected => _isYoutubeConnected;
  bool get isJiosaavnConnected => _isJiosaavnConnected;
  bool get isLastFmConnected => _isLastFmConnected;

  bool isSongLiked(String id) => _likedSongIds.contains(id);

  bool get isSingleSongMode => _isSingleSongMode;

  @visibleForTesting
  void setCurrentSongForTest(Song song, {List<Song>? queue, bool isPlaylistQueue = false}) {
    _currentSong = song;
    _isPlaying = false;
    _currentYoutubeVideoUrl = null;
    if (queue != null) {
      _queue = List.from(queue);
    }
    _isPlaylistQueue = isPlaylistQueue;
    notifyListeners();
  }

  Future<void> playSingleSong(Song song) async {
    _isSingleSongMode = true;
    _isPlaylistQueue = false;
    await playSong(song, newQueue: [song], isSingleSong: true);
  }

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    if (playlist.songs.isEmpty) return;
    _isSingleSongMode = false;
    _isPlaylistQueue = true;
    final startSong = (startIndex >= 0 && startIndex < playlist.songs.length)
        ? playlist.songs[startIndex]
        : playlist.songs.first;
    await playSong(startSong, newQueue: playlist.songs, isSingleSong: false);
  }

  void toggleSpotifyAlgorithm() {
    _spotifyAlgorithmEnabled = !_spotifyAlgorithmEnabled;
    notifyListeners();
  }

  void playWithSpotifyAlgorithm(Song seedSong, {List<Song>? contextPlaylist}) {
    _spotifyAlgorithmEnabled = true;
    _isSingleSongMode = false;
    _isPlaylistQueue = false;
    final pool = (contextPlaylist != null && contextPlaylist.isNotEmpty)
        ? contextPlaylist
        : MockMusicRepository.allSongs;
    final algorithmicQueue = SpotifyAlgorithmService.generateAlgorithmicQueue(seedSong, pool);
    playSong(seedSong, newQueue: algorithmicQueue, isSingleSong: false);
  }

  Future<void> playSong(
    Song song, {
    List<Song>? newQueue,
    bool? isSingleSong,
    bool preserveQueueOrder = false,
  }) async {
    final seqId = ++_playSequenceId;
    _currentSong = song;
    if (isSingleSong != null) {
      _isSingleSongMode = isSingleSong;
    } else if (newQueue != null && newQueue.length == 1) {
      _isSingleSongMode = true;
    } else if (newQueue != null && newQueue.length > 1) {
      _isSingleSongMode = false;
    }

    if (!_history.any((s) => s.id == song.id)) {
      _history.insert(0, song);
    }

    if (!preserveQueueOrder) {
      if (newQueue != null && newQueue.isNotEmpty) {
        if (newQueue.length > 1) {
          // Deduplicate while preserving exact playlist order!
          final seen = <String>{};
          final deduped = <Song>[];
          for (final item in newQueue) {
            if (seen.add(item.id)) {
              deduped.add(item);
            }
          }
          if (!seen.contains(song.id)) {
            deduped.insert(0, song);
          }
          _isPlaylistQueue = true;
          _originalPlaylistQueue = List.from(deduped);
          if (_isShuffle) {
            final others = deduped.where((s) => s.id != song.id).toList()..shuffle();
            _queue = [song, ...others];
          } else {
            _queue = List.from(deduped);
          }
        } else {
          _isPlaylistQueue = false;
          _originalPlaylistQueue = [];
          _queue = List.from(newQueue);
        }
      } else {
        _isPlaylistQueue = false;
        _originalPlaylistQueue = [];
        final pool = _queue.isNotEmpty ? _queue : MockMusicRepository.allSongs;
        final matching = pool.where((s) =>
          s.id == song.id || (
            SpotifyAlgorithmService.isSameLanguage(s, song) &&
            SpotifyAlgorithmService.isSameGenreCluster(s, song)
          )
        ).toList();
        for (final s in MockMusicRepository.allSongs) {
          if (!matching.any((m) => m.id == s.id) &&
              SpotifyAlgorithmService.isSameLanguage(s, song) &&
              SpotifyAlgorithmService.isSameGenreCluster(s, song)) {
            matching.add(s);
          }
        }
        _queue = SpotifyAlgorithmService.generateAlgorithmicQueue(song, matching);
      }
    }

    // Always start playback cleanly from 0:00 (the very beginning)
    _positionSeconds = 0;
    _durationSeconds = song.durationSeconds;
    _currentYoutubeVideoUrl = null;
    _isPlaying = true;
    ThemeColorService().updateForSong(song);
    notifyListeners();

    try {
      await _audioPlayer.stop();
      if (seqId != _playSequenceId) return;

      String? resolvedAudioUrl = song.audioUrl;

      // Resolve real YouTube audio & video streams if this is a YouTube track
      final ytVideoId = YouTubeService.extractVideoId(song);
      if (ytVideoId != null) {
        final pair = await YouTubeService.resolveStreamUrls(ytVideoId);
        // Guard against user switching songs while stream resolves
        if (seqId != _playSequenceId || _currentSong?.id != song.id) return;
        if (pair != null) {
          resolvedAudioUrl = pair.audioUrl;
          _currentYoutubeVideoUrl = pair.videoUrl;
          notifyListeners();
        }
      }

      _resolvedAudioUrl = resolvedAudioUrl;
      if (resolvedAudioUrl != null && resolvedAudioUrl.isNotEmpty && !resolvedAudioUrl.startsWith('yt://')) {
        await _audioPlayer.play(UrlSource(resolvedAudioUrl));
        if (seqId != _playSequenceId) return;
        // Apply native DSP Equalizer & Audio Effects to the active playback session
        Future.delayed(const Duration(milliseconds: 250), () {
          AudioDspService.attachToPlayerAndApply(
            bandGains: _bandGains,
            bassBoost: _bassBoost,
            virtualizer: _virtualizer,
          );
        });
        Future.delayed(const Duration(milliseconds: 650), () {
          AudioDspService.attachToPlayerAndApply(
            bandGains: _bandGains,
            bassBoost: _bassBoost,
            virtualizer: _virtualizer,
          );
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null && _queue.isNotEmpty) {
      _currentSong = _queue.first;
    }
    if (_currentSong == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _isPlaying = false;
      } else {
        final playUrl = _resolvedAudioUrl ?? _currentSong?.audioUrl;
        if (playUrl != null && playUrl.isNotEmpty && !playUrl.startsWith('yt://')) {
          if (_positionSeconds > 0) {
            await _audioPlayer.resume();
          } else {
            await _audioPlayer.play(UrlSource(playUrl));
          }
          _isPlaying = true;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  void next() {
    if (_queue.isEmpty || _currentSong == null) return;
    final current = _currentSong!;
    final currentIndex = _queue.indexWhere((s) => s.id == current.id);

    if (_isPlaylistQueue) {
      final nextIndex = currentIndex != -1 ? currentIndex + 1 : 0;
      if (nextIndex < _queue.length) {
        playSong(_queue[nextIndex], preserveQueueOrder: true);
        return;
      }
      if (_repeatMode == BitifyRepeatMode.all) {
        playSong(_queue.first, preserveQueueOrder: true);
        return;
      }
      _isPlaying = false;
      _audioPlayer.stop();
      notifyListeners();
      return;
    }

    // Algorithmic queue mode: look ahead in _queue for next matching song
    int nextIndex = currentIndex != -1 ? currentIndex + 1 : 0;
    while (nextIndex < _queue.length) {
      final candidate = _queue[nextIndex];
      if (candidate.id != current.id &&
          SpotifyAlgorithmService.isSameLanguage(candidate, current) &&
          SpotifyAlgorithmService.isSameGenreCluster(candidate, current)) {
        playSong(candidate, preserveQueueOrder: true);
        return;
      }
      nextIndex++;
    }

    if (_repeatMode == BitifyRepeatMode.all) {
      final firstMatching = _queue.firstWhere(
        (s) => SpotifyAlgorithmService.isSameLanguage(s, current) &&
               SpotifyAlgorithmService.isSameGenreCluster(s, current),
        orElse: () => _queue.first,
      );
      playSong(firstMatching, preserveQueueOrder: true);
    } else {
      final pool = MockMusicRepository.allSongs;
      final nextSong = SpotifyAlgorithmService.getNextAlgorithmicSong(
        current,
        pool,
        _history.map((s) => s.id).toSet(),
      );
      if (nextSong.id != current.id &&
          SpotifyAlgorithmService.isSameLanguage(nextSong, current) &&
          SpotifyAlgorithmService.isSameGenreCluster(nextSong, current)) {
        _queue.add(nextSong);
        playSong(nextSong, preserveQueueOrder: true);
      } else {
        _isPlaying = false;
        _audioPlayer.stop();
        notifyListeners();
      }
    }
  }

  void previous() {
    if (_queue.isEmpty || _currentSong == null) return;
    if (_positionSeconds > 3) {
      seekTo(0);
      return;
    }
    final current = _currentSong!;
    final currentIndex = _queue.indexWhere((s) => s.id == current.id);

    if (_isPlaylistQueue) {
      final prevIndex = (currentIndex != -1 ? currentIndex : _queue.length) - 1;
      if (prevIndex >= 0) {
        playSong(_queue[prevIndex], preserveQueueOrder: true);
        return;
      }
      seekTo(0);
      return;
    }

    int prevIndex = (currentIndex != -1 ? currentIndex : _queue.length) - 1;
    while (prevIndex >= 0) {
      final candidate = _queue[prevIndex];
      if (candidate.id != current.id &&
          SpotifyAlgorithmService.isSameLanguage(candidate, current) &&
          SpotifyAlgorithmService.isSameGenreCluster(candidate, current)) {
        playSong(candidate, preserveQueueOrder: true);
        return;
      }
      prevIndex--;
    }
    seekTo(0);
  }

  Future<void> seekTo(int seconds) async {
    final maxDur = durationSeconds;
    _positionSeconds = seconds.clamp(0, maxDur);
    notifyListeners();
    try {
      await _audioPlayer.seek(Duration(seconds: _positionSeconds));
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  void toggleLike(String songId) {
    if (_likedSongIds.contains(songId)) {
      _likedSongIds.remove(songId);
    } else {
      _likedSongIds.add(songId);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_currentSong != null) {
      final current = _currentSong!;
      if (_isPlaylistQueue) {
        if (_isShuffle) {
          final others = _queue.where((s) => s.id != current.id).toList()..shuffle();
          _queue = [current, ...others];
        } else if (_originalPlaylistQueue.isNotEmpty) {
          _queue = List.from(_originalPlaylistQueue);
        }
      } else {
        if (_isShuffle) {
          final matchingOthers = _queue.where((s) =>
            s.id != current.id &&
            SpotifyAlgorithmService.isSameLanguage(s, current) &&
            SpotifyAlgorithmService.isSameGenreCluster(s, current)
          ).toList()..shuffle();
          _queue = [current, ...matchingOthers];
        } else {
          _queue = SpotifyAlgorithmService.generateAlgorithmicQueue(current, _queue);
        }
      }
    }
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case BitifyRepeatMode.off:
        _repeatMode = BitifyRepeatMode.all;
        break;
      case BitifyRepeatMode.all:
        _repeatMode = BitifyRepeatMode.one;
        break;
      case BitifyRepeatMode.one:
        _repeatMode = BitifyRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void setBandGain(int index, double gain) {
    if (index >= 0 && index < _bandGains.length) {
      _bandGains[index] = gain.clamp(-12.0, 12.0);
      _currentPreset = 'Custom';
      AudioDspService.setBandGain(index, _bandGains[index]);
      notifyListeners();
    }
  }

  void setBassBoost(double value) {
    _bassBoost = value.clamp(0.0, 1.0);
    AudioDspService.setBassBoost(_bassBoost);
    notifyListeners();
  }

  void setVirtualizer(double value) {
    _virtualizer = value.clamp(0.0, 1.0);
    AudioDspService.setVirtualizer(_virtualizer);
    notifyListeners();
  }

  void applyPreset(String preset) {
    _currentPreset = preset;
    switch (preset) {
      case 'Bass Boost':
        _bandGains = [8.0, 7.0, 5.0, 2.0, 0.0, 0.0, 1.0, 2.0, 2.0, 2.0];
        _bassBoost = 0.90;
        break;
      case 'EDM / Dance':
        _bandGains = [6.0, 5.0, 2.0, 0.0, 1.0, 3.0, 5.0, 6.0, 5.0, 4.0];
        _bassBoost = 0.70;
        break;
      case 'Acoustic / Vocal':
        _bandGains = [1.0, 1.0, 2.0, 4.0, 5.0, 5.0, 4.0, 2.0, 1.0, 0.0];
        _bassBoost = 0.20;
        break;
      case 'Rock':
        _bandGains = [5.0, 4.0, 2.0, -1.0, -1.0, 1.0, 3.0, 5.0, 6.0, 6.0];
        _bassBoost = 0.60;
        break;
      case 'Flat':
        _bandGains = List.filled(10, 0.0);
        _bassBoost = 0.0;
        _virtualizer = 0.0;
        break;
      case 'Bitify Dynamic':
      default:
        _bandGains = [2.0, 3.5, 1.0, 0.0, -1.0, 2.0, 4.0, 3.0, 2.5, 3.0];
        _bassBoost = 0.55;
        _virtualizer = 0.40;
        break;
    }
    AudioDspService.attachToPlayerAndApply(
      bandGains: _bandGains,
      bassBoost: _bassBoost,
      virtualizer: _virtualizer,
    );
    notifyListeners();
  }

  void setAudioQuality(String quality) {
    _audioQuality = quality;
    notifyListeners();
  }

  void setCrossfade(int seconds) {
    _crossfadeSeconds = seconds;
    notifyListeners();
  }

  void toggleGapless(bool value) {
    _gaplessPlayback = value;
    notifyListeners();
  }

  void toggleNormalize(bool value) {
    _normalizeVolume = value;
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimerMinutes = minutes;
    _sleepTimer?.cancel();
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _isPlaying = false;
      _audioPlayer.pause();
      _sleepTimerMinutes = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = null;
    notifyListeners();
  }

  void toggleLastFm() {
    _isLastFmConnected = !_isLastFmConnected;
    notifyListeners();
  }

  void toggleSourceConnection(MusicSource source) {
    switch (source) {
      case MusicSource.spotify:
        _isSpotifyConnected = !_isSpotifyConnected;
        break;
      case MusicSource.youtube:
        _isYoutubeConnected = !_isYoutubeConnected;
        break;
      case MusicSource.jiosaavn:
        _isJiosaavnConnected = !_isJiosaavnConnected;
        break;
      case MusicSource.local:
        break;
    }
    notifyListeners();
  }

  void addToQueue(Song song) {
    if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      notifyListeners();
    }
  }

  void addAllToQueue(List<Song> songs) {
    for (final song in songs) {
      if (!_queue.any((s) => s.id == song.id)) {
        _queue.add(song);
      }
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }
}
