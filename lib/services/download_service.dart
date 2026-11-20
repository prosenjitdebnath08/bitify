import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// Singleton download manager — simulates downloads with a progress bar.
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// songId → entry
  final Map<String, DownloadEntry> _entries = {};

  List<DownloadEntry> get all => _entries.values.toList();

  List<DownloadEntry> get downloaded =>
      _entries.values.where((e) => e.status == DownloadStatus.done).toList();

  List<DownloadEntry> get downloading =>
      _entries.values.where((e) => e.status == DownloadStatus.downloading).toList();

  bool isDownloaded(String songId) =>
      _entries[songId]?.status == DownloadStatus.done;

  bool isDownloading(String songId) =>
      _entries[songId]?.status == DownloadStatus.downloading;

  double progress(String songId) => _entries[songId]?.progress ?? 0.0;

  /// Start a simulated download for [song].
  void startDownload(Song song) {
    if (_entries.containsKey(song.id)) return; // already downloading or done

    final entry = DownloadEntry(song: song);
    _entries[song.id] = entry;
    notifyListeners();

    // Simulate download: tick every 300 ms, finish in ~6 s (20 ticks × 5%)
    const tickMs = 300;
    const totalTicks = 20;
    int ticks = 0;

    Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      ticks++;
      entry.progress = (ticks / totalTicks).clamp(0.0, 1.0);
      if (ticks >= totalTicks) {
        entry.status = DownloadStatus.done;
        entry.progress = 1.0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  /// Remove / delete a downloaded (or in-progress) song.
  void deleteSong(String songId) {
    _entries.remove(songId);
    notifyListeners();
  }
}
