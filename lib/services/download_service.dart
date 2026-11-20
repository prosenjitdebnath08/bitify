import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// Singleton download manager for Bitify offline vault.
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  DownloadService._internal() {
    _seedInitialDownloads();
  }

  /// Pre-seed with sample offline songs so the Downloads tab has real content
  void _seedInitialDownloads() {
    try {
      final initial = MockMusicRepository.allSongs.take(2).toList();
      for (final s in initial) {
        _entries[s.id] = DownloadEntry(
          song: s,
          status: DownloadStatus.done,
          progress: 1.0,
        );
      }
    } catch (_) {}
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

  /// Start simulated 256kbps download for [song].
  void startDownload(Song song, {VoidCallback? onComplete}) {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    final entry = DownloadEntry(song: song, status: DownloadStatus.downloading, progress: 0.05);
    _entries[song.id] = entry;
    notifyListeners();

    // Fast & smooth 2.5s simulation (15 ticks x 160ms)
    const tickMs = 160;
    const totalTicks = 15;
    int ticks = 0;

    Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      ticks++;
      entry.progress = (ticks / totalTicks).clamp(0.0, 1.0);
      if (ticks >= totalTicks) {
        entry.status = DownloadStatus.done;
        entry.progress = 1.0;
        timer.cancel();
        onComplete?.call();
      }
      notifyListeners();
    });
  }

  /// Remove a song from downloaded offline vault.
  void deleteSong(String songId) {
    _entries.remove(songId);
    notifyListeners();
  }

  /// Clear all offline downloads.
  void clearAll() {
    _entries.clear();
    notifyListeners();
  }
}
