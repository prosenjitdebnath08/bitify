import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_models.dart';
import '../data/mock_music_repository.dart';
import '../services/audio_dsp_service.dart';
import '../services/music_api_service.dart';
import '../services/spotify_algorithm_service.dart';
import '../services/theme_color_service.dart';

enum BitifyRepeatMode { off, all, one }

class MusicPlayerState extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Song? _currentSong;
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

  // Categorized Catalogs and Playlists (Bollywood, Hollywood, Bengali)
  List<Song> _bollywoodSongs = [];
  List<Song> _hollywoodSongs = [];
  List<Song> _bengaliSongs = [];
  List<Playlist> _bollywoodPlaylists = [];
  List<Playlist> _hollywoodPlaylists = [];
  List<Playlist> _bengaliPlaylists = [];

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
      // 1. Fetch Bollywood
      final bWood = await MusicApiService.fetchCategorySongs('Bollywood Hits', limit: 20);
      if (bWood.isNotEmpty) {
        _bollywoodSongs = bWood;
        _bollywoodPlaylists = [
          Playlist(
            id: 'bp_live_top',
            title: 'Bollywood Top 50',
            description: 'Live trending chartbusters from JioSaavn & Spotify',
            coverUrl: bWood.first.coverUrl,
            songs: bWood,
          ),
          Playlist(
            id: 'bp_live_romance',
            title: 'Bollywood Romance',
            description: 'Soulful love anthems & acoustic duets',
            coverUrl: bWood.length > 1 ? bWood[1].coverUrl : bWood.first.coverUrl,
            songs: bWood.reversed.toList(),
          ),
          ...MockMusicRepository.bollywoodPlaylists.skip(1),
        ];
      }

      // 2. Fetch Hollywood
      final hWood = await MusicApiService.fetchCategorySongs('The Weeknd Dua Lipa Pop Hits', limit: 20);
      if (hWood.isNotEmpty) {
        _hollywoodSongs = hWood;
        _hollywoodPlaylists = [
          Playlist(
            id: 'hp_live_top',
            title: "Today's Top Hits",
            description: 'Global pop & international hits on Spotify',
            coverUrl: hWood.first.coverUrl,
            songs: hWood,
          ),
          Playlist(
            id: 'hp_live_synth',
            title: 'Synthwave & Retro',
            description: 'Late night cyberpunk rhythms & neon pop',
            coverUrl: hWood.length > 1 ? hWood[1].coverUrl : hWood.first.coverUrl,
            songs: hWood.reversed.toList(),
          ),
          ...MockMusicRepository.hollywoodPlaylists.skip(1),
        ];
      }

      // 3. Fetch Bengali
      final bGali = await MusicApiService.fetchCategorySongs('Bengali Hits Arijit Singh', limit: 20);
      if (bGali.isNotEmpty) {
        _bengaliSongs = bGali;
        _bengaliPlaylists = [
          Playlist(
            id: 'beng_live_top',
            title: 'Bangla Top Hits',
            description: 'Trending Bengali melodies and film chartbusters',
            coverUrl: bGali.first.coverUrl,
            songs: bGali,
          ),
          Playlist(
            id: 'beng_live_arijit',
            title: 'Arijit Bengali Melodies',
            description: 'Heartwarming acoustic Bengali songs',
            coverUrl: bGali.length > 1 ? bGali[1].coverUrl : bGali.first.coverUrl,
            songs: bGali.reversed.toList(),
          ),
          ...MockMusicRepository.bengaliPlaylists.skip(1),
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

  Future<void> playSingleSong(Song song) async {
    _isSingleSongMode = true;
    await playSong(song, newQueue: [song], isSingleSong: true);
  }

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    _isSingleSongMode = false;
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
    final pool = (contextPlaylist != null && contextPlaylist.isNotEmpty)
        ? contextPlaylist
        : MockMusicRepository.allSongs;
    final algorithmicQueue = SpotifyAlgorithmService.generateAlgorithmicQueue(seedSong, pool);
    playSong(seedSong, newQueue: algorithmicQueue, isSingleSong: false);
  }

  Future<void> playSong(Song song, {List<Song>? newQueue, bool? isSingleSong}) async {
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

    // Strictly preserve same-language and same-genre consistency across the queue
    if (newQueue != null && newQueue.isNotEmpty) {
      final matching = newQueue.where((s) =>
        s.id == song.id || (
          SpotifyAlgorithmService.isSameLanguage(s, song) &&
          SpotifyAlgorithmService.isSameGenreCluster(s, song)
        )
      ).toList();
      _queue = SpotifyAlgorithmService.generateAlgorithmicQueue(song, matching);
    } else {
      final pool = _queue.isNotEmpty ? _queue : MockMusicRepository.allSongs;
      final matching = pool.where((s) =>
        s.id == song.id || (
          SpotifyAlgorithmService.isSameLanguage(s, song) &&
          SpotifyAlgorithmService.isSameGenreCluster(s, song)
        )
      ).toList();
      // Ensure candidate depth by adding matching songs from repository
      for (final s in MockMusicRepository.allSongs) {
        if (!matching.any((m) => m.id == s.id) &&
            SpotifyAlgorithmService.isSameLanguage(s, song) &&
            SpotifyAlgorithmService.isSameGenreCluster(s, song)) {
          matching.add(s);
        }
      }
      _queue = SpotifyAlgorithmService.generateAlgorithmicQueue(song, matching);
    }

    // Always start playback cleanly from 0:00 (the very beginning)
    _positionSeconds = 0;
    _durationSeconds = song.durationSeconds;
    _isPlaying = true;
    ThemeColorService().updateForSong(song);
    notifyListeners();

    try {
      await _audioPlayer.stop();
      if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        await _audioPlayer.play(UrlSource(song.audioUrl!));
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
        if (_currentSong?.audioUrl != null && _currentSong!.audioUrl!.isNotEmpty) {
          if (_positionSeconds > 0) {
            await _audioPlayer.resume();
          } else {
            await _audioPlayer.play(UrlSource(_currentSong!.audioUrl!));
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

    // Look ahead in _queue for next matching song
    int nextIndex = currentIndex != -1 ? currentIndex + 1 : 0;
    while (nextIndex < _queue.length) {
      final candidate = _queue[nextIndex];
      if (candidate.id != current.id &&
          SpotifyAlgorithmService.isSameLanguage(candidate, current) &&
          SpotifyAlgorithmService.isSameGenreCluster(candidate, current)) {
        playSong(candidate, newQueue: _queue);
        return;
      }
      nextIndex++;
    }

    if (_repeatMode == BitifyRepeatMode.all) {
      // Loop back to the first song in queue matching same language & genre
      final firstMatching = _queue.firstWhere(
        (s) => SpotifyAlgorithmService.isSameLanguage(s, current) &&
               SpotifyAlgorithmService.isSameGenreCluster(s, current),
        orElse: () => _queue.first,
      );
      playSong(firstMatching, newQueue: _queue);
    } else {
      // Continuously discover next track matching same language and genre
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
        playSong(nextSong, newQueue: _queue);
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

    int prevIndex = (currentIndex != -1 ? currentIndex : _queue.length) - 1;
    while (prevIndex >= 0) {
      final candidate = _queue[prevIndex];
      if (candidate.id != current.id &&
          SpotifyAlgorithmService.isSameLanguage(candidate, current) &&
          SpotifyAlgorithmService.isSameGenreCluster(candidate, current)) {
        playSong(candidate, newQueue: _queue);
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
