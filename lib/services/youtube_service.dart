import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/music_models.dart';

class YoutubeStreamPair {
  final String audioUrl;
  final String? videoUrl;

  const YoutubeStreamPair({
    required this.audioUrl,
    this.videoUrl,
  });
}

/// Service for fetching real YouTube music metadata, playlists, and playable audio/video streams.
class YouTubeService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, YoutubeStreamPair> _streamCache = {};

  /// Extract raw YouTube video ID from a song ID (`yt_<id>`) or `yt://<id>` URL.
  static String? extractVideoId(Song song) {
    if (song.audioUrl != null && song.audioUrl!.startsWith('yt://')) {
      return song.audioUrl!.substring(5).trim();
    }
    if (song.id.startsWith('yt_')) {
      final raw = song.id.substring(3).trim();
      // Ensure it's a valid 11-char or non-mock YouTube ID
      if (raw.isNotEmpty && !raw.startsWith('mix_') && !raw.startsWith('hits_')) {
        return raw;
      }
    }
    return null;
  }

  /// Search real YouTube videos/songs for the given query.
  static Future<List<Song>> searchSongs(String query, {int limit = 15}) async {
    if (query.trim().isEmpty) return [];
    final List<Song> results = [];

    try {
      final searchList = await _yt.search
          .search(query.trim())
          .timeout(const Duration(seconds: 8));

      for (final video in searchList.take(limit)) {
        final vid = video.id.value;
        if (vid.isEmpty) continue;

        final durationSec = video.duration?.inSeconds ?? 210;
        // Skip ultra-short clips (< 30s) or 2+ hour compilations if looking for songs
        if (durationSec < 30 || durationSec > 1800) continue;

        final title = video.title.trim();
        final author = video.author.trim().isNotEmpty ? video.author.trim() : 'YouTube Music';
        final coverUrl = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';

        final checkLower = '$title $author $query'.toLowerCase();
        String lang = 'English';
        String genre = 'Pop / Dance';
        if (checkLower.contains('hindi') ||
            checkLower.contains('bollywood') ||
            checkLower.contains('arijit') ||
            checkLower.contains('pritam') ||
            checkLower.contains('lofi hindi')) {
          lang = 'Hindi';
          genre = 'Bollywood / Romantic';
        } else if (checkLower.contains('bengali') || checkLower.contains('bangla')) {
          lang = 'Bengali';
          genre = 'Bengali / Melodies';
        }

        results.add(
          Song(
            id: 'yt_$vid',
            title: title,
            artist: author,
            album: 'YouTube',
            durationSeconds: durationSec > 0 ? durationSec : 210,
            coverUrl: coverUrl,
            audioUrl: 'yt://$vid',
            source: MusicSource.youtube,
            isLossless: false,
            isDolbyAtmos: false,
            language: lang,
            genre: genre,
            lyrics: [
              LyricLine(second: 2, text: '♪ $title ♪'),
              LyricLine(second: 6, text: 'Channel: $author'),
              const LyricLine(second: 12, text: 'Streaming from YouTube'),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('YouTubeService.searchSongs error: $e');
    }

    return results;
  }

  /// Fetch real YouTube playlists or build a YouTube playlist from search results.
  static Future<List<Playlist>> searchPlaylists(String query, {int limit = 3}) async {
    final List<Playlist> playlists = [];
    try {
      final songs = await searchSongs('$query music playlist', limit: 15);
      if (songs.isNotEmpty) {
        playlists.add(
          Playlist(
            id: 'yt_real_${query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
            title: '$query • YouTube Mix',
            description: '${songs.length} Tracks • Live from YouTube',
            coverUrl: songs.first.coverUrl,
            songs: songs,
            source: MusicSource.youtube,
          ),
        );
      }
    } catch (e) {
      debugPrint('YouTubeService.searchPlaylists error: $e');
    }
    return playlists.take(limit).toList();
  }

  /// Resolve direct playable audio & video stream URLs for a YouTube video ID.
  static Future<YoutubeStreamPair?> resolveStreamUrls(String videoId) async {
    if (videoId.trim().isEmpty) return null;
    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId];
    }

    try {
      final manifest = await _yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 10));

      String? audioUrl;
      String? videoUrl;

      if (manifest.audioOnly.isNotEmpty) {
        audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
      }
      if (manifest.muxed.isNotEmpty) {
        // Prefer 360p/720p mp4 muxed stream for smooth mobile video playback
        final mp4Muxed = manifest.muxed
            .where((s) => s.container.name.toLowerCase() == 'mp4')
            .toList();
        if (mp4Muxed.isNotEmpty) {
          mp4Muxed.sort((a, b) => b.videoResolution.height.compareTo(a.videoResolution.height));
          final preferred = mp4Muxed.firstWhere(
            (s) => s.videoResolution.height <= 720,
            orElse: () => mp4Muxed.first,
          );
          videoUrl = preferred.url.toString();
        } else {
          videoUrl = manifest.muxed.withHighestBitrate().url.toString();
        }
        audioUrl ??= videoUrl;
      }

      if (audioUrl != null && audioUrl.isNotEmpty) {
        final pair = YoutubeStreamPair(audioUrl: audioUrl, videoUrl: videoUrl);
        _streamCache[videoId] = pair;
        return pair;
      }
    } catch (e) {
      debugPrint('YouTubeService.resolveStreamUrls error ($videoId): $e');
    }
    return null;
  }
}
