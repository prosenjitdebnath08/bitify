import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';

class MusicApiService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  /// Search online music catalog across millions of songs worldwide
  static Future<List<Song>> searchOnline(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl?term=${Uri.encodeComponent(query)}&entity=song&limit=$limit',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((item) {
          final trackId = item['trackId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          final title = item['trackName'] as String? ?? 'Unknown Title';
          final artist = item['artistName'] as String? ?? 'Unknown Artist';
          final album = item['collectionName'] as String? ?? title;
          final durationMs = item['trackTimeMillis'] as int? ?? 180000;
          final artwork100 = item['artworkUrl100'] as String? ?? '';
          final coverUrl = artwork100.replaceAll('100x100bb', '600x600bb');
          final previewUrl = item['previewUrl'] as String? ?? '';
          final primaryGenre = item['primaryGenreName'] as String? ?? '';

          // Assign realistic source based on genre/artist
          MusicSource source;
          if (primaryGenre.toLowerCase().contains('indian') ||
              primaryGenre.toLowerCase().contains('bollywood') ||
              artist.toLowerCase().contains('arijit') ||
              artist.toLowerCase().contains('singh')) {
            source = MusicSource.jiosaavn;
          } else if (title.hashCode % 2 == 0) {
            source = MusicSource.spotify;
          } else {
            source = MusicSource.youtube;
          }

          return Song(
            id: trackId,
            title: title,
            artist: artist,
            album: album,
            durationSeconds: (durationMs / 1000).round(),
            coverUrl: coverUrl.isNotEmpty
                ? coverUrl
                : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
            audioUrl: previewUrl,
            source: source,
            isLossless: true,
            isDolbyAtmos: (trackId.hashCode % 3 == 0),
            lyrics: _generateLyricsPreview(title, artist),
          );
        }).where((s) => s.audioUrl != null && s.audioUrl!.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('MusicApiService search error: $e');
    }

    return [];
  }

  /// Fetch initial trending tracks across pop, hip hop, bollywood, and rock
  static Future<List<Song>> fetchTrendingSongs() async {
    final queries = ['Trending Hits 2026', 'Top Pop Global', 'Bollywood Trending', 'Synthwave Beats'];
    final List<Song> combined = [];
    final Set<String> seenIds = {};

    for (final q in queries) {
      try {
        final songs = await searchOnline(q, limit: 12);
        for (final s in songs) {
          if (!seenIds.contains(s.id)) {
            seenIds.add(s.id);
            combined.add(s);
          }
        }
      } catch (e) {
        debugPrint('Error fetching trending category $q: $e');
      }
    }

    return combined;
  }

  /// Generate synchronized lyrics placeholder for any online song
  static List<LyricLine> _generateLyricsPreview(String title, String artist) {
    return [
      LyricLine(second: 2, text: "♪ $title ♪"),
      LyricLine(second: 6, text: "Performed by $artist"),
      const LyricLine(second: 10, text: "Feel the rhythm in the dark"),
      const LyricLine(second: 14, text: "Every beat that sets a spark"),
      LyricLine(second: 18, text: "Sing along with $title"),
      const LyricLine(second: 24, text: "High fidelity lossless sound"),
      const LyricLine(second: 28, text: "Only on Bitify ♪"),
    ];
  }
}
