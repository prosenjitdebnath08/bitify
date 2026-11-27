import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
/// directly via YouTube's InnerTube API (www.youtube.com, not YouTube Music),
/// with a local loopback Range-proxy so Android MediaPlayer & VideoPlayer
/// can stream YouTube adaptive formats without 403 errors.
class YouTubeService {
  static const String _searchEndpoint =
      'https://www.youtube.com/youtubei/v1/search?prettyPrint=false';
  static const String _visitorEndpoint =
      'https://www.youtube.com/youtubei/v1/visitor_id?prettyPrint=false';
  static const String _playerEndpoint =
      'https://www.youtube.com/youtubei/v1/player?prettyPrint=false';

  static const String _visionOsUa =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15';
  static const String _androidVrUa =
      'com.google.android.apps.youtube.vr.oculus/1.65.10 '
      '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';

  static final Map<String, YoutubeStreamPair> _streamCache = {};
  static final Map<String, Future<YoutubeStreamPair?>> _inFlightResolves = {};
  static final Map<String, ({String url, String mimeType, String ua})> _proxyTargets = {};
  static HttpServer? _proxyServer;
  static int? _proxyPort;
  static int _tokenCounter = 0;
  static String? _cachedVisitorData;

  /// Ensure the local loopback HTTP proxy is running and return its port.
  static Future<int> _ensureProxyServer() async {
    if (_proxyServer != null && _proxyPort != null) {
      return _proxyPort!;
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _proxyServer = server;
    _proxyPort = server.port;
    server.listen(_handleProxyRequest, onError: (e) {
      debugPrint('YouTube proxy server error: $e');
    });
    return server.port;
  }

  static Future<void> _handleProxyRequest(HttpRequest req) async {
    final token = req.uri.queryParameters['token'];
    final target = token != null ? _proxyTargets[token] : null;
    if (target == null) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      return;
    }

    // Parse incoming Range header (e.g. "bytes=0-" or "bytes=1024-2047")
    final incomingRange = req.headers.value(HttpHeaders.rangeHeader);
    final bool hasIncomingRange = incomingRange != null && incomingRange.isNotEmpty;
    int start = 0;
    int? requestedEnd;
    if (hasIncomingRange && incomingRange.startsWith('bytes=')) {
      final rangePart = incomingRange.substring(6).split(',').first.trim();
      final parts = rangePart.split('-');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        start = int.tryParse(parts[0]) ?? 0;
      }
      if (parts.length > 1 && parts[1].isNotEmpty) {
        requestedEnd = int.tryParse(parts[1]);
      }
    }

    const int chunkSize = 512 * 1024; // 512 KB bounded chunks (YouTube 403s open-ended bytes=0-)
    final client = http.Client();
    bool headersSent = false;

    try {
      int offset = start;
      int? totalSize;

      while (true) {
        final int upperBound = requestedEnd != null
            ? ((offset + chunkSize - 1) < requestedEnd ? (offset + chunkSize - 1) : requestedEnd)
            : (totalSize != null && (offset + chunkSize - 1) >= totalSize
                ? totalSize - 1
                : offset + chunkSize - 1);

        if (upperBound < offset) break;

        final upstreamReq = http.Request('GET', Uri.parse(target.url));
        upstreamReq.headers['User-Agent'] = target.ua;
        upstreamReq.headers['Range'] = 'bytes=$offset-$upperBound';

        final upstreamRes = await client.send(upstreamReq).timeout(const Duration(seconds: 12));

        if (upstreamRes.statusCode >= 400) {
          debugPrint('YouTube proxy upstream ${upstreamRes.statusCode} for ${target.mimeType} (bytes=$offset-$upperBound)');
          if (!headersSent) {
            req.response.statusCode = upstreamRes.statusCode;
          }
          break;
        }

        // Parse total size from Content-Range: bytes 0-524287/3456789
        final cr = upstreamRes.headers['content-range'];
        if (cr != null && cr.contains('/')) {
          final totalStr = cr.split('/').last.trim();
          totalSize ??= int.tryParse(totalStr);
        }

        if (!headersSent) {
          headersSent = true;
          final effectiveEnd = requestedEnd ?? (totalSize != null ? totalSize - 1 : null);
          req.response.statusCode = hasIncomingRange ? HttpStatus.partialContent : HttpStatus.ok;
          req.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
          req.response.headers.set(
            HttpHeaders.contentTypeHeader,
            upstreamRes.headers['content-type'] ?? target.mimeType,
          );
          if (totalSize != null && effectiveEnd != null) {
            final totalToSend = effectiveEnd - start + 1;
            req.response.headers.set(HttpHeaders.contentLengthHeader, '$totalToSend');
            if (hasIncomingRange) {
              req.response.headers.set(
                HttpHeaders.contentRangeHeader,
                'bytes $start-$effectiveEnd/$totalSize',
              );
            }
          }
        }

        int bytesInChunk = 0;
        await for (final data in upstreamRes.stream) {
          req.response.add(data);
          bytesInChunk += data.length;
        }

        if (bytesInChunk == 0) break;
        offset += bytesInChunk;

        if (requestedEnd != null && offset > requestedEnd) break;
        if (totalSize != null && offset >= totalSize) break;
      }

      await req.response.flush();
      await req.response.close();
    } catch (e) {
      debugPrint('YouTube proxy stream error: $e');
      try {
        if (!headersSent) {
          req.response.statusCode = HttpStatus.badGateway;
        }
        await req.response.close();
      } catch (_) {}
    } finally {
      client.close();
    }
  }

  static Future<String> _registerProxyUrl(String remoteUrl, String mimeType, String ua) async {
    final port = await _ensureProxyServer();
    final token = 'yt_${++_tokenCounter}_${DateTime.now().millisecondsSinceEpoch}';
    _proxyTargets[token] = (url: remoteUrl, mimeType: mimeType, ua: ua);
    // Keep cache bounded
    if (_proxyTargets.length > 40) {
      _proxyTargets.remove(_proxyTargets.keys.first);
    }
    return 'http://127.0.0.1:$port/yt?token=$token';
  }

  /// Extract raw YouTube video ID from a song ID (`yt_<id>`) or `yt://<id>` URL.
  static String? extractVideoId(Song song) {
    if (song.audioUrl != null && song.audioUrl!.startsWith('yt://')) {
      return song.audioUrl!.substring(5).trim();
    }
    if (song.id.startsWith('yt_')) {
      final raw = song.id.substring(3).trim();
      if (raw.isNotEmpty &&
          !raw.startsWith('mix_') &&
          !raw.startsWith('hits_') &&
          !raw.startsWith('mock_')) {
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
                  'clientName': 'VISIONOS',
                  'clientVersion': '0.1',
                  'deviceMake': 'Apple',
                  'deviceModel': 'RealityDevice14,1',
                  'osName': 'visionOS',
                  'osVersion': '1.3.21O771',
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

  static Future<Map<String, dynamic>?> _fetchPlayerData({
    required String videoId,
    required String? visitorData,
    required bool useVisionOs,
  }) async {
    final ua = useVisionOs ? _visionOsUa : _androidVrUa;
    final clientPayload = useVisionOs
        ? {
            'clientName': 'VISIONOS',
            'clientVersion': '0.1',
            'deviceMake': 'Apple',
            'deviceModel': 'RealityDevice14,1',
            'osName': 'visionOS',
            'osVersion': '1.3.21O771',
            'visitorData': ?visitorData,
          }
        : {
            'clientName': 'ANDROID_VR',
            'clientVersion': '1.65.10',
            'deviceMake': 'Oculus',
            'deviceModel': 'Quest 3',
            'osName': 'Android',
            'osVersion': '12L',
            'androidSdkVersion': '32',
            'visitorData': ?visitorData,
          };

    final res = await http
        .post(
          Uri.parse(_playerEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': ua,
            'X-YouTube-Client-Name': useVisionOs ? '101' : '28',
            'X-YouTube-Client-Version': useVisionOs ? '0.1' : '1.65.10',
            'X-Goog-Visitor-Id': ?visitorData,
          },
          body: jsonEncode({
            'context': {'client': clientPayload},
            'videoId': videoId,
            'contentCheckOk': true,
            'racyCheckOk': true,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Pre-warm stream URLs for an upcoming YouTube track in the background.
  static void prewarmStream(String videoId) {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty ||
        _streamCache.containsKey(cleanId) ||
        _inFlightResolves.containsKey(cleanId)) {
      return;
    }
    unawaited(resolveStreamUrls(cleanId));
  }

  /// Resolve direct playable audio & video stream URLs (proxied via localhost Range proxy)
  /// using VISIONOS client (unthrottled full-song & video streams) with ANDROID_VR fallback.
  static Future<YoutubeStreamPair?> resolveStreamUrls(String videoId) {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return Future.value(null);
    final cached = _streamCache[cleanId];
    if (cached != null) return Future.value(cached);

    final inFlight = _inFlightResolves[cleanId];
    if (inFlight != null) return inFlight;

    final future = _resolveStreamUrlsInternal(cleanId).whenComplete(() {
      _inFlightResolves.remove(cleanId);
    });
    _inFlightResolves[cleanId] = future;
    return future;
  }

  static Future<YoutubeStreamPair?> _resolveStreamUrlsInternal(String videoId) async {
    if (videoId.isEmpty) return null;
    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId];
    }

    try {
      final visitorData = await _getVisitorData();
      String usedUa = _visionOsUa;
      var data = await _fetchPlayerData(
        videoId: videoId,
        visitorData: visitorData,
        useVisionOs: true,
      );

      var streamingData = data?['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) {
        usedUa = _androidVrUa;
        data = await _fetchPlayerData(
          videoId: videoId,
          visitorData: visitorData,
          useVisionOs: false,
        );
        streamingData = data?['streamingData'] as Map<String, dynamic>?;
      }
      if (streamingData == null) return null;

      final adaptive = (streamingData['adaptiveFormats'] as List?) ?? [];

      // Pick best audio/mp4 (AAC) stream from adaptiveFormats
      String? bestAudioUrl;
      String audioMime = 'audio/mp4';
      int bestAudioBitrate = -1;
      for (final f in adaptive) {
        final mime = (f['mimeType']?.toString() ?? '').toLowerCase();
        final url = f['url']?.toString();
        if (url == null || url.isEmpty) continue;
        if (mime.startsWith('audio/')) {
          final bitrate = int.tryParse(f['bitrate']?.toString() ?? '0') ?? 0;
          final bonus = mime.startsWith('audio/mp4') ? 1000000 : 0;
          if (bitrate + bonus > bestAudioBitrate) {
            bestAudioBitrate = bitrate + bonus;
            bestAudioUrl = url;
            audioMime = mime.split(';').first.trim();
          }
        }
      }

      // Pick H.264 (avc1) video/mp4 <= 720p for broad Android hardware decode compatibility
      String? bestVideoUrl;
      int bestVideoHeight = -1;
      for (final f in adaptive) {
        final mime = (f['mimeType']?.toString() ?? '').toLowerCase();
        final url = f['url']?.toString();
        final height = int.tryParse(f['height']?.toString() ?? '0') ?? 0;
        if (url != null && url.isNotEmpty && mime.startsWith('video/mp4') && height <= 720) {
          final isAvc1 = mime.contains('avc1') ? 1000 : 0;
          if (height + isAvc1 > bestVideoHeight) {
            bestVideoHeight = height + isAvc1;
            bestVideoUrl = url;
          }
        }
      }

      if (bestAudioUrl != null && bestAudioUrl.isNotEmpty) {
        final proxiedAudio = await _registerProxyUrl(bestAudioUrl, audioMime, usedUa);
        final proxiedVideo = (bestVideoUrl != null && bestVideoUrl.isNotEmpty)
            ? await _registerProxyUrl(bestVideoUrl, 'video/mp4', usedUa)
            : null;

        final pair = YoutubeStreamPair(
          audioUrl: proxiedAudio,
          videoUrl: proxiedVideo,
          userAgent: usedUa,
        );
        _streamCache[videoId] = pair;
        return pair;
      }
    } catch (e) {
      debugPrint('YouTubeService.resolveStreamUrls error ($videoId): $e');
    }
    return null;
  }
}
