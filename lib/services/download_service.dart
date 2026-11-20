import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_music_repository.dart';
import '../models/music_models.dart';

enum DownloadStatus { idle, downloading, done }

class DownloadEntry {
  final Song song;
  DownloadStatus status;
  double progress; // 0.0 – 1.0

  DownloadEntry({
    required this.song,
    this.status = DownloadStatus.downloading,
    this.progress = 0.0,
  });
}

/// Persistent download manager for Bitify offline audio vault.
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  static const String _prefKey = 'bitify_downloaded_songs_v2';

  DownloadService._internal() {
    _loadFromPrefs();
  }

  /// songId -> DownloadEntry
  final Map<String, DownloadEntry> _entries = {};

  List<DownloadEntry> get all => _entries.values.toList();

  List<DownloadEntry> get downloaded =>
      _entries.values.where((e) => e.status == DownloadStatus.done).toList();

  List<Song> get downloadedSongs =>
      downloaded.map((e) => e.song).toList();

  List<DownloadEntry> get downloading =>
      _entries.values.where((e) => e.status == DownloadStatus.downloading).toList();

  bool isDownloaded(String songId) =>
      _entries[songId]?.status == DownloadStatus.done;

  bool isDownloading(String songId) =>
      _entries[songId]?.status == DownloadStatus.downloading;

  double progress(String songId) => _entries[songId]?.progress ?? 0.0;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _entries.clear();
        for (final item in list) {
          final s = Song.fromJson(item as Map<String, dynamic>);
          _entries[s.id] = DownloadEntry(
            song: s,
            status: DownloadStatus.done,
            progress: 1.0,
          );
        }
      } else {
        // Pre-seed with mock songs on first launch
        _seedDefaults();
        await _saveToPrefs();
      }
    } catch (_) {
      _seedDefaults();
    }
    notifyListeners();
  }

  void _seedDefaults() {
    try {
      final initial = MockMusicRepository.allSongs.take(4).toList();
      for (final s in initial) {
        _entries[s.id] = DownloadEntry(
          song: s,
          status: DownloadStatus.done,
          progress: 1.0,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = downloaded.map((e) => e.song.toJson()).toList();
      await prefs.setString(_prefKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Start simulated 256kbps download for [song].
  void startDownload(Song song, {VoidCallback? onComplete}) {
    if (isDownloaded(song.id)) return;

    final entry = DownloadEntry(
      song: song,
      status: DownloadStatus.downloading,
      progress: 0.2,
    );
    _entries[song.id] = entry;
    notifyListeners();

    // Fast 1-second progress animation (5 ticks × 200ms)
    const tickMs = 200;
    const totalTicks = 5;
    int ticks = 1;

    Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      ticks++;
      entry.progress = (ticks / totalTicks).clamp(0.0, 1.0);
      if (ticks >= totalTicks) {
        entry.status = DownloadStatus.done;
        entry.progress = 1.0;
        timer.cancel();
        _saveToPrefs();
        try {
          onComplete?.call();
        } catch (_) {}
      }
      notifyListeners();
    });
  }

  /// Remove a song from downloaded offline vault.
  void deleteSong(String songId) {
    _entries.remove(songId);
    _saveToPrefs();
    notifyListeners();
  }

  /// Clear all offline downloads.
  void clearAll() {
    _entries.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
