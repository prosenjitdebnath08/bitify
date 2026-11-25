import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';

class YoutubeStreamPair {
  final String audioUrl;
  final String? videoUrl;
  final String? userAgent;

  const YoutubeStreamPair({
    required this.audioUrl,
    this.videoUrl,
    this.userAgent,
  });
}

/// Service for fetching real YouTube videos, playlists, and playable streams
/// directly via YouTube's InnerTube API (www.youtube.com, not YouTube Music).
class YouTubeService {
  static const String _searchEndpoint =
      'https://www.youtube.com/youtubei/v1/search?prettyPrint=false';
  static const String _visitorEndpoint =
      'https://www.youtube.com/youtubei/v1/visitor_id?prettyPrint=false';
  static const String _playerEndpoint =
      'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';

  static const String _androidVrUa =
      'com.google.android.apps.youtube.vr.oculus/1.65.10 '
      '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';

  static final Map<String, YoutubeStreamPair> _streamCache = {};
  static String? _cachedVisitorData;

  /// Extract raw YouTube video ID from a song ID (`yt_<id>`) or `yt://<id>` URL.
  static String? extractVideoId(Song song) {
    if (song.audioUrl != null && song.audioUrl!.startsWith('yt://')) {
      return song.audioUrl!.substring(5).trim();
    }
    if (song.id.startsWith('yt_')) {
      final raw = song.id.substring(3).trim();
      if (raw.isNotEmpty && !raw.startsWith('mix_') && !raw.startsWith('hits_') && !raw.startsWith('mock_')) {
        return raw;
      }
    }
    return null;
  }

  /// Parse duration text like "3:45" or "1:02:10" into seconds.
  static int _parseDurationText(String? text) {
    if (text == null || text.trim().isEmpty) return 210;
    final parts = text.trim().split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    } else if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    }
    return 210;
  }

  /// Recursively collect `videoRenderer` maps from YouTube InnerTube search JSON.
  static void _collectVideoRenderers(dynamic node, List<Map<String, dynamic>> out) {
    if (node is Map<String, dynamic>) {
      if (node.containsKey('videoRenderer') && node['videoRenderer'] is Map<String, dynamic>) {
        out.add(node['videoRenderer'] as Map<String, dynamic>);
      } else {
        for (final val in node.values) {
          _collectVideoRenderers(val, out);
        }
      }
    } else if (node is List) {
      for (final item in node) {
        _collectVideoRenderers(item, out);
      }
    }
  }

  /// Parse YouTube InnerTube search JSON body into `Song` objects.
  @visibleForTesting
  static List<Song> parseSearchResponse(String body, {String query = '', int limit = 15}) {
    final List<Song> results = [];
    final Set<String> seen = {};
    final data = jsonDecode(body) as Map<String, dynamic>;
    final renderers = <Map<String, dynamic>>[];
    _collectVideoRenderers(data, renderers);

    for (final v in renderers) {
      if (results.length >= limit) break;
      final vid = v['videoId']?.toString() ?? '';
      if (vid.isEmpty || seen.contains(vid)) continue;

      final titleRuns = v['title']?['runs'] as List?;
      final title = (titleRuns != null && titleRuns.isNotEmpty)
          ? titleRuns.map((r) => r['text']?.toString() ?? '').join().trim()
          : (v['title']?['simpleText']?.toString() ?? '').trim();
      if (title.isEmpty) continue;

      final ownerRuns = (v['ownerText']?['runs'] ?? v['longBylineText']?['runs']) as List?;
      final author = (ownerRuns != null && ownerRuns.isNotEmpty)
          ? ownerRuns.first['text']?.toString().trim() ?? 'YouTube'
          : 'YouTube';

      final lengthText = v['lengthText']?['simpleText']?.toString();
      // Skip live streams without lengthText
      if (lengthText == null || lengthText.isEmpty) continue;
      final durationSec = _parseDurationText(lengthText);
      if (durationSec < 30 || durationSec > 1800) continue;

      seen.add(vid);
      final coverUrl = 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';

      final checkLower = '$title $author $query'.toLowerCase();
      String lang = 'English';
      String genre = 'Pop / Dance';
      if (checkLower.contains('hindi') ||
          checkLower.contains('bollywood') ||
          checkLower.contains('arijit') ||
          checkLower.contains('pritam') ||
          checkLower.contains('shreya')) {
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
          durationSeconds: durationSec,
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

    return results;
  }

  /// Search real YouTube videos/songs for the given query.
  static Future<List<Song>> searchSongs(String query, {int limit = 15}) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await http
          .post(
            Uri.parse(_searchEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            body: jsonEncode({
              'context': {
                'client': {
                  'clientName': 'WEB',
                  'clientVersion': '2.20241120.01.00',
                  'hl': 'en',
                  'gl': 'IN',
                },
              },
              'query': query.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        return parseSearchResponse(res.body, query: query, limit: limit);
      }
    } catch (e) {
      debugPrint('YouTubeService.searchSongs error: $e');
    }
    return [];
  }

  /// Build real YouTube playlists from YouTube search results.
  static Future<List<Playlist>> searchPlaylists(String query, {int limit = 3}) async {
    final List<Playlist> playlists = [];
    try {
      final songs = await searchSongs('$query songs', limit: 15);
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

  static Future<String?> _getVisitorData() async {
    if (_cachedVisitorData != null) return _cachedVisitorData;
    try {
      final res = await http
          .post(
            Uri.parse(_visitorEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'context': {
                'client': {
                  'clientName': 'ANDROID_VR',
                  'clientVersion': '1.65.10',
                  'deviceMake': 'Oculus',
                  'deviceModel': 'Quest 3',
                  'osName': 'Android',
                  'osVersion': '12L',
                  'androidSdkVersion': '32',
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _cachedVisitorData = data['responseContext']?['visitorData']?.toString();
      }
    } catch (e) {
      debugPrint('YouTubeService._getVisitorData error: $e');
    }
    return _cachedVisitorData;
  }

  /// Resolve direct playable audio & video stream URLs for a YouTube video ID
  /// using BitChord's ANDROID_VR 1.65.10 InnerTube player client.
  static Future<YoutubeStreamPair?> resolveStreamUrls(String videoId) async {
    if (videoId.trim().isEmpty) return null;
    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId];
    }

    try {
      final visitorData = await _getVisitorData();
      final res = await http
          .post(
            Uri.parse(_playerEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': _androidVrUa,
              'X-YouTube-Client-Name': '28',
              'X-YouTube-Client-Version': '1.65.10',
              'X-Goog-Visitor-Id': ?visitorData,
            },
            body: jsonEncode({
              'context': {
                'client': {
                  'clientName': 'ANDROID_VR',
                  'clientVersion': '1.65.10',
                  'deviceMake': 'Oculus',
                  'deviceModel': 'Quest 3',
                  'osName': 'Android',
                  'osVersion': '12L',
                  'androidSdkVersion': '32',
                  'visitorData': ?visitorData,
                },
              },
              'videoId': videoId,
              'contentCheckOk': true,
              'racyCheckOk': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final streamingData = data['streamingData'] as Map<String, dynamic>?;
        if (streamingData == null) return null;

        final formats = (streamingData['formats'] as List?) ?? [];
        final adaptive = (streamingData['adaptiveFormats'] as List?) ?? [];

        // Pick best audio/mp4 or audio/webm stream from adaptiveFormats
        String? bestAudioUrl;
        int bestAudioBitrate = -1;
        for (final f in adaptive) {
          final mime = (f['mimeType']?.toString() ?? '').toLowerCase();
          final url = f['url']?.toString();
          if (url == null || url.isEmpty) continue;
          if (mime.startsWith('audio/mp4') || mime.startsWith('audio/')) {
            final bitrate = int.tryParse(f['bitrate']?.toString() ?? '0') ?? 0;
            // Prefer m4a (audio/mp4) for broad Android AudioPlayer compatibility
            final bonus = mime.startsWith('audio/mp4') ? 1000000 : 0;
            if (bitrate + bonus > bestAudioBitrate) {
              bestAudioBitrate = bitrate + bonus;
              bestAudioUrl = url;
            }
          }
        }

        // Pick best muxed mp4 or adaptive mp4 video stream for the 16:9 rectangle box
        String? bestVideoUrl;
        for (final f in formats) {
          final mime = (f['mimeType']?.toString() ?? '').toLowerCase();
          final url = f['url']?.toString();
          if (url != null && url.isNotEmpty && mime.contains('mp4')) {
            bestVideoUrl = url;
            break;
          }
        }
        if (bestVideoUrl == null) {
          for (final f in adaptive) {
            final mime = (f['mimeType']?.toString() ?? '').toLowerCase();
            final url = f['url']?.toString();
            final height = int.tryParse(f['height']?.toString() ?? '0') ?? 0;
            if (url != null && url.isNotEmpty && mime.startsWith('video/mp4') && height <= 720) {
              bestVideoUrl = url;
              break;
            }
          }
        }

        bestAudioUrl ??= bestVideoUrl;
        if (bestAudioUrl != null && bestAudioUrl.isNotEmpty) {
          final pair = YoutubeStreamPair(
            audioUrl: bestAudioUrl,
            videoUrl: bestVideoUrl,
            userAgent: _androidVrUa,
          );
          _streamCache[videoId] = pair;
          return pair;
        }
      }
    } catch (e) {
      debugPrint('YouTubeService.resolveStreamUrls error ($videoId): $e');
    }
    return null;
  }
}
