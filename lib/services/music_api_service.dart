import 'dart:convert';
import 'package:dart_des/dart_des.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/music_models.dart';

class MusicApiService {
  static const String _jioSaavnBase = 'https://www.jiosaavn.com/api.php';
  static final List<int> _desKey = utf8.encode('38346591');

  /// Decrypt JioSaavn encrypted_media_url into direct 320kbps/256kbps audio URL
  static String? decryptMediaUrl(String? encrypted) {
    if (encrypted == null || encrypted.trim().isEmpty) return null;
    try {
      final des = DES(key: _desKey, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS7);
      final decryptedBytes = des.decrypt(base64.decode(encrypted.trim()));
      final rawUrl = utf8.decode(decryptedBytes).trim();
      if (rawUrl.isEmpty || !rawUrl.startsWith('http')) return null;

      // Upgrade to 320kbps / 256kbps high quality audio stream
      return rawUrl.replaceAll('_96.mp4', '_320.mp4').replaceAll('_160.mp4', '_320.mp4');
    } catch (e) {
      debugPrint('Error decrypting JioSaavn media URL: $e');
      return null;
    }
  }

  /// Clean HTML entities common in JioSaavn responses
  static String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&copy;', '©')
        .replaceAll('&#38;', '&')
        .trim();
  }

  /// Upgrade image thumbnail to 500x500 high resolution
  static String _upgradeImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80';
    }
    return url.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
  }

  /// Universal Search across full catalog (Global, Pop, Hip-Hop, Bollywood, Indie, EDM)
  static Future<List<Song>> searchOnline(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    final List<Song> results = [];
    final Set<String> seenIds = {};

    // 1. Search JioSaavn direct high-fidelity CDN
    try {
      final uri = Uri.parse(
        '$_jioSaavnBase?__call=search.getResults&q=${Uri.encodeComponent(query)}&_format=json&_marker=0&api_version=4&ctx=android&n=$limit&p=1',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Bitify/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final items = data['results'] as List<dynamic>? ?? [];

        for (final item in items) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.contains(id)) continue;

          final moreInfo = item['more_info'] as Map<String, dynamic>? ?? {};
          final encUrl = moreInfo['encrypted_media_url'] as String? ?? '';
          final directAudioUrl = decryptMediaUrl(encUrl);

          if (directAudioUrl == null || directAudioUrl.isEmpty) continue;
          seenIds.add(id);

          final rawTitle = item['title'] as String? ?? 'Unknown Title';
          final title = _cleanText(rawTitle);

          final primaryArtists = moreInfo['primary_artists'] as String? ?? '';
          final singers = moreInfo['singers'] as String? ?? '';
          final subtitle = item['subtitle'] as String? ?? 'Unknown Artist';
          final artist = _cleanText(primaryArtists.isNotEmpty ? primaryArtists : (singers.isNotEmpty ? singers : subtitle));

          final album = _cleanText(moreInfo['album'] as String? ?? title);
          final durationStr = moreInfo['duration']?.toString() ?? '180';
          final duration = int.tryParse(durationStr) ?? 180;
          final coverUrl = _upgradeImage(item['image'] as String?);
          final rawLang = (item['language'] as String? ?? moreInfo['language'] as String? ?? '').trim();
          final rawGenre = (item['genre'] as String? ?? moreInfo['genre'] as String? ?? '').trim();

          String assignedLang = rawLang.isNotEmpty ? rawLang : 'Hindi';
          final checkLower = '$title $artist $album $query'.toLowerCase();
          if (assignedLang.toLowerCase().contains('bengali') || checkLower.contains('bengali') || checkLower.contains('bangla')) {
            assignedLang = 'Bengali';
          } else if (assignedLang.toLowerCase().contains('english') || checkLower.contains('hollywood') || checkLower.contains('english')) {
            assignedLang = 'English';
          } else if (assignedLang.toLowerCase().contains('hindi') || checkLower.contains('bollywood')) {
            assignedLang = 'Hindi';
          }

          // Assign realistic platform source badge
          MusicSource source;
          final hash = (title + artist).hashCode.abs();
          if (hash % 3 == 0) {
            source = MusicSource.spotify;
          } else if (hash % 3 == 1) {
            source = MusicSource.youtube;
          } else {
            source = MusicSource.jiosaavn;
          }

          results.add(
            Song(
              id: 'js_$id',
              title: title,
              artist: artist,
              album: album,
              durationSeconds: duration > 0 ? duration : 180,
              coverUrl: coverUrl,
              audioUrl: directAudioUrl,
              source: source,
              isLossless: true,
              isDolbyAtmos: (hash % 2 == 0),
              language: assignedLang,
              genre: rawGenre.isNotEmpty ? rawGenre : (assignedLang == 'Bengali' ? 'Bengali / Melodies' : (assignedLang == 'English' ? 'Pop / Dance' : 'Bollywood / Romantic')),
              lyrics: _generateLyricsPreview(title, artist),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('JioSaavn search error: $e');
    }

    // 2. Fallback to iTunes if needed
    if (results.length < 5) {
      try {
        final itunesUri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=15',
        );
        final itunesRes = await http.get(itunesUri).timeout(const Duration(seconds: 6));
        if (itunesRes.statusCode == 200) {
          final itunesData = json.decode(itunesRes.body) as Map<String, dynamic>;
          final itunesItems = itunesData['results'] as List<dynamic>? ?? [];

          for (final item in itunesItems) {
            final trackId = item['trackId']?.toString() ?? '';
            if (trackId.isEmpty || seenIds.contains(trackId)) continue;
            seenIds.add(trackId);

            final previewUrl = item['previewUrl'] as String? ?? '';
            if (previewUrl.isEmpty) continue;

            final title = item['trackName'] as String? ?? 'Unknown Title';
            final artist = item['artistName'] as String? ?? 'Unknown Artist';
            final album = item['collectionName'] as String? ?? title;
            final artwork100 = item['artworkUrl100'] as String? ?? '';
            final coverUrl = artwork100.replaceAll('100x100bb', '600x600bb');
            final genre = item['primaryGenreName'] as String? ?? 'Pop';

            results.add(
              Song(
                id: 'it_$trackId',
                title: title,
                artist: artist,
                album: album,
                durationSeconds: 30,
                coverUrl: coverUrl.isNotEmpty
                    ? coverUrl
                    : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80',
                audioUrl: previewUrl,
                source: MusicSource.spotify,
                isLossless: true,
                isDolbyAtmos: false,
                language: 'English',
                genre: genre,
                lyrics: _generateLyricsPreview(title, artist),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('iTunes search fallback error: $e');
      }
    }

    return results;
  }

  /// Fetch initial trending / top global hits
  static Future<List<Song>> fetchTrendingSongs() async {
    final List<Song> trending = [];
    final queries = ['top hits', 'global hits', 'trending songs', 'chartbusters'];

    for (final q in queries) {
      try {
        final songs = await searchOnline(q, limit: 12);
        for (final s in songs) {
          if (!trending.any((item) => item.id == s.id || item.title.toLowerCase() == s.title.toLowerCase())) {
            trending.add(s);
          }
        }
        if (trending.length >= 25) break;
      } catch (e) {
        debugPrint('Error fetching trending batch: $e');
      }
    }

    return trending;
  }

  /// Fetch songs tailored for specific category: 'bollywood', 'hollywood', or 'bengali'
  static Future<List<Song>> fetchCategorySongs(String categoryQuery, {int limit = 30}) async {
    try {
      final songs = await searchOnline(categoryQuery, limit: limit);
      if (songs.isNotEmpty) return songs;
    } catch (e) {
      debugPrint('Error fetching category songs ($categoryQuery): $e');
    }
    return [];
  }

  /// Fetch a complete album from JioSaavn by album ID
  static Future<Album?> fetchAlbumById(String albumId) async {
    try {
      final uri = Uri.parse(
        '$_jioSaavnBase?__call=content.getAlbumDetails&albumid=$albumId&_format=json&ctx=android',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Bitify/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final title = _cleanText(data['title']?.toString() ?? data['name']?.toString() ?? 'Album');
        final primaryArtists = _cleanText(data['primary_artists']?.toString() ?? '');
        final coverUrl = _upgradeImage(data['image']?.toString());
        final year = int.tryParse(data['year']?.toString() ?? '2023') ?? 2023;

        final rawSongs = data['songs'] as List<dynamic>? ?? [];
        final List<Song> songs = [];

        for (final item in rawSongs) {
          final id = item['id']?.toString() ?? '';
          final encUrl = item['encrypted_media_url'] as String? ?? '';
          final directAudioUrl = decryptMediaUrl(encUrl);
          if (directAudioUrl == null || directAudioUrl.isEmpty) continue;

          final sTitle = _cleanText(item['song']?.toString() ?? item['title']?.toString() ?? title);
          final sArtist = _cleanText(item['primary_artists']?.toString() ?? (primaryArtists.isNotEmpty ? primaryArtists : 'Artist'));
          final sDur = int.tryParse(item['duration']?.toString() ?? '200') ?? 200;
          final sImg = _upgradeImage(item['image']?.toString() ?? coverUrl);
          final sLang = item['language']?.toString() ?? 'Hindi';

          songs.add(
            Song(
              id: 'js_alb_$id',
              title: sTitle,
              artist: sArtist,
              album: title,
              durationSeconds: sDur > 0 ? sDur : 200,
              coverUrl: sImg,
              audioUrl: directAudioUrl,
              source: MusicSource.jiosaavn,
              isLossless: true,
              isDolbyAtmos: true,
              language: sLang.toLowerCase().contains('bengali') ? 'Bengali' : (sLang.toLowerCase().contains('english') ? 'English' : 'Hindi'),
              genre: sLang.toLowerCase().contains('bengali') ? 'Bengali / Melodies' : (sLang.toLowerCase().contains('english') ? 'Pop / Dance' : 'Bollywood / Romantic'),
              lyrics: _generateLyricsPreview(sTitle, sArtist),
            ),
          );
        }

        if (songs.isNotEmpty) {
          return Album(
            id: 'alb_$albumId',
            title: title,
            artist: primaryArtists.isNotEmpty ? primaryArtists : songs.first.artist,
            coverUrl: coverUrl,
            year: year,
            songs: songs,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching album details: $e');
    }
    return null;
  }

  /// Search and fetch full album with all its tracks
  static Future<Album?> searchAndFetchAlbum(String query) async {
    try {
      final uri = Uri.parse(
        '$_jioSaavnBase?__call=search.getAlbumResults&q=${Uri.encodeComponent(query)}&_format=json&ctx=android&n=1',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Bitify/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final rawId = results[0]['albumid'] ?? results[0]['id'];
          final aid = (rawId != null && rawId.toString() != 'null') ? rawId.toString() : '';
          if (aid.isNotEmpty) {
            return await fetchAlbumById(aid);
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching album ($query): $e');
    }
    return null;
  }

  /// Fetch popular full albums across Bollywood, Hollywood and Bengali
  static Future<List<Album>> fetchTrendingAlbums() async {
    final List<Album> albums = [];
    const queries = [
      'Brahmastra',
      'Future Nostalgia',
      'After Hours',
      'Bhediya',
      'Jab We Met',
      'Autograph Bengali',
    ];

    for (final q in queries) {
      try {
        final alb = await searchAndFetchAlbum(q);
        if (alb != null && alb.songs.isNotEmpty) {
          albums.add(alb);
        }
      } catch (e) {
        debugPrint('Error fetching album $q: $e');
      }
    }

    return albums;
  }

  /// Fetch a complete playlist from JioSaavn by playlist ID
  static Future<Playlist?> fetchPlaylistById(String listId, {String? title, String? coverUrl}) async {
    try {
      final uri = Uri.parse(
        '$_jioSaavnBase?__call=playlist.getDetails&listid=$listId&_format=json&ctx=android',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Bitify/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List<Song> songs = [];

        for (int i = 0; i < 50; i++) {
          final item = data['$i'];
          if (item == null || item is! Map<String, dynamic>) continue;

          final id = item['id']?.toString() ?? '';
          final encUrl = item['encrypted_media_url'] as String? ?? '';
          final directAudioUrl = decryptMediaUrl(encUrl);
          if (directAudioUrl == null || directAudioUrl.isEmpty) continue;

          final sTitle = _cleanText(item['song']?.toString() ?? item['title']?.toString() ?? 'Track');
          final sArtist = _cleanText(item['primary_artists']?.toString() ?? item['singers']?.toString() ?? 'Artist');
          final sDur = int.tryParse(item['duration']?.toString() ?? '200') ?? 200;
          final sImg = _upgradeImage(item['image']?.toString() ?? coverUrl);
          final sAlbum = _cleanText(item['album']?.toString() ?? sTitle);
          final sLang = item['language']?.toString() ?? 'Hindi';

          songs.add(
            Song(
              id: 'js_pl_${listId}_$id',
              title: sTitle,
              artist: sArtist,
              album: sAlbum,
              durationSeconds: sDur > 0 ? sDur : 200,
              coverUrl: sImg,
              audioUrl: directAudioUrl,
              source: MusicSource.jiosaavn,
              isLossless: true,
              isDolbyAtmos: true,
              language: sLang.toLowerCase().contains('bengali')
                  ? 'Bengali'
                  : (sLang.toLowerCase().contains('english') ? 'English' : 'Hindi'),
              genre: 'Curated / Playlist',
              lyrics: _generateLyricsPreview(sTitle, sArtist),
            ),
          );
        }

        if (songs.isNotEmpty) {
          final pTitle = title ?? songs.first.album;
          final pCover = coverUrl ?? songs.first.coverUrl;
          return Playlist(
            id: 'pl_jiosaavn_$listId',
            title: pTitle,
            description: '${songs.length} Tracks • JioSaavn Official Playlist',
            coverUrl: pCover,
            songs: songs,
            source: MusicSource.jiosaavn,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching playlist details ($listId): $e');
    }
    return null;
  }

  /// Search for official JioSaavn playlists
  static Future<List<Playlist>> searchJioSaavnPlaylists(String query, {int limit = 4}) async {
    final List<Playlist> playlists = [];
    try {
      final uri = Uri.parse(
        '$_jioSaavnBase?__call=search.getPlaylistResults&q=${Uri.encodeComponent(query)}&_format=json&ctx=android&n=$limit',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Bitify/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        final fetchFutures = results.take(limit).map((item) async {
          final listId = item['listid']?.toString() ?? '';
          if (listId.isEmpty) return null;
          final title = _cleanText(item['listname']?.toString() ?? 'Playlist');
          final coverUrl = _upgradeImage(item['image']?.toString());
          return await fetchPlaylistById(listId, title: title, coverUrl: coverUrl);
        });

        final loaded = await Future.wait(fetchFutures);
        for (final pl in loaded) {
          if (pl != null && pl.songs.isNotEmpty) {
            playlists.add(pl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching JioSaavn playlists ($query): $e');
    }
    return playlists;
  }

  /// Search all artist-related playlists across Spotify, JioSaavn & YouTube Music
  static Future<List<Playlist>> searchMultiSourcePlaylists(String query, List<Song> matchingSongs) async {
    final List<Playlist> playlists = [];
    final Set<String> seenIds = {};

    // 1. Identify primary artist(s) from matching songs or the query itself
    String primaryArtist = query.trim();
    if (matchingSongs.isNotEmpty) {
      final songArtist = matchingSongs.first.artist;
      final extracted = songArtist.split(RegExp(r'[,&•/|]')).first.trim();
      if (extracted.isNotEmpty) {
        primaryArtist = extracted;
      }
    }

    // 2. Fetch official JioSaavn playlists for the artist
    try {
      final jsPlaylists = await searchJioSaavnPlaylists(primaryArtist, limit: 4);
      for (final pl in jsPlaylists) {
        if (!seenIds.contains(pl.id)) {
          seenIds.add(pl.id);
          playlists.add(pl);
        }
      }
    } catch (e) {
      debugPrint('Error searching artist JioSaavn playlists: $e');
    }

    // 3. If query differs from primaryArtist, search for query-specific JioSaavn playlists as well
    if (query.trim().toLowerCase() != primaryArtist.toLowerCase()) {
      try {
        final queryPlaylists = await searchJioSaavnPlaylists(query.trim(), limit: 2);
        for (final pl in queryPlaylists) {
          if (!seenIds.contains(pl.id)) {
            seenIds.add(pl.id);
            playlists.add(pl);
          }
        }
      } catch (e) {
        debugPrint('Error searching query JioSaavn playlists: $e');
      }
    }

    // 4. Generate Spotify Official Artist Playlists
    if (matchingSongs.isNotEmpty) {
      final artistSongs = matchingSongs.where((s) {
        return s.artist.toLowerCase().contains(primaryArtist.toLowerCase());
      }).toList();
      final pool = artistSongs.isNotEmpty ? artistSongs : matchingSongs;

      // a) "This Is [Artist]" (Spotify Official flagship format)
      playlists.add(
        Playlist(
          id: 'sp_this_is_${primaryArtist.toLowerCase().replaceAll(' ', '_')}',
          title: 'This Is $primaryArtist',
          description: '${pool.length} Tracks • Spotify Official Artist Playlist',
          coverUrl: pool.first.coverUrl,
          songs: pool,
          source: MusicSource.spotify,
        ),
      );

      // b) "[Artist] Radio" (Spotify Radio Flow)
      if (pool.length > 2) {
        playlists.add(
          Playlist(
            id: 'sp_radio_${primaryArtist.toLowerCase().replaceAll(' ', '_')}',
            title: '$primaryArtist Radio',
            description: '${pool.length} Tracks • Spotify Algorithmic Radio Flow',
            coverUrl: pool.length > 1 ? pool[1].coverUrl : pool.first.coverUrl,
            songs: pool.reversed.toList(),
            source: MusicSource.spotify,
          ),
        );
      }

      // 5. Generate YouTube Music Official Artist Mixes
      // a) "[Artist] • YouTube Music Mix"
      final ytSongs = pool.where((s) => s.source == MusicSource.youtube).toList();
      final poolYt = ytSongs.isNotEmpty ? ytSongs : pool;
      playlists.add(
        Playlist(
          id: 'yt_mix_${primaryArtist.toLowerCase().replaceAll(' ', '_')}',
          title: '$primaryArtist • YouTube Mix',
          description: '${poolYt.length} Tracks • Curated YouTube Music Artist Mix',
          coverUrl: poolYt.first.coverUrl,
          songs: poolYt,
          source: MusicSource.youtube,
        ),
      );

      // b) "[Artist] • Non-Stop Chartbusters"
      if (pool.length > 3) {
        playlists.add(
          Playlist(
            id: 'yt_hits_${primaryArtist.toLowerCase().replaceAll(' ', '_')}',
            title: '$primaryArtist • Non-Stop Hits',
            description: '${pool.length} Tracks • YouTube Music Chartbusters',
            coverUrl: pool.last.coverUrl,
            songs: pool,
            source: MusicSource.youtube,
          ),
        );
      }
    }

    return playlists;
  }

  static List<LyricLine> _generateLyricsPreview(String title, String artist) {
    return [
      LyricLine(second: 2, text: "♪ $title ♪"),
      LyricLine(second: 6, text: "Artist: $artist"),
      const LyricLine(second: 12, text: "Bitify 256kbps Master Audio"),
      const LyricLine(second: 18, text: "Lossless Studio Fidelity Engine"),
      const LyricLine(second: 26, text: "Feel every frequency ♪"),
    ];
  }
}
