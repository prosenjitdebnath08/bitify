import '../models/music_models.dart';

class SpotifyAlgorithmService {
  /// Normalize song language into a canonical code ('bengali', 'hindi', or 'english')
  static String normalizeLanguage(Song s) {
    final l = s.language.toLowerCase().trim();
    if (l.contains('bengali') || l.contains('bangla')) {
      return 'bengali';
    }

    final text = '${s.title} ${s.artist} ${s.album}'.toLowerCase();
    const bengaliWords = [
      'bengali',
      'bangla',
      'anupam',
      'hemanta',
      'rabindra',
      'moushumi',
      'jeevon',
      'mon majhi',
      'tumi robe',
      'bhalolaage',
      'parbona',
      'ke tui bol',
      'bodhuaa',
      'jannat',
      'tumi khushi',
      'bhoomi',
      'fossils',
      'rupankar',
      'nachiketa',
      'silajit',
      'shreya ghoshal bengali',
      'jeet gannguli',
    ];
    if (bengaliWords.any((w) => text.contains(w))) {
      return 'bengali';
    }

    if (l.contains('hindi') ||
        l.contains('desi') ||
        l.contains('punjabi') ||
        l.contains('bollywood') ||
        l.contains('tamil') ||
        l.contains('telugu')) {
      return 'hindi';
    }
    const desiWords = [
      'kesariya',
      'pardesiya',
      'arijit',
      'pritam',
      'shreya',
      'brahmastra',
      'kalank',
      'apna bana le',
      'tum se hi',
      'bhediya',
      'jab we met',
      'sachin-jigar',
      'mohit chauhan',
      'bollywood',
      'sufi',
      'desi',
    ];
    if (desiWords.any((w) => text.contains(w))) {
      return 'hindi';
    }
    return 'english';
  }

  /// Strictly checks if two songs share the exact same language
  static bool isSameLanguage(Song a, Song b) {
    return normalizeLanguage(a) == normalizeLanguage(b);
  }

  /// Classifies a song into a discrete, cohesive genre cluster
  static String getPrimaryGenreCluster(Song s) {
    final lang = normalizeLanguage(s);
    if (lang == 'bengali') {
      return 'bengali_melodies';
    }
    if (lang == 'hindi') {
      return 'bollywood_romantic';
    }

    final g = '${s.genre} ${s.title} ${s.album} ${s.artist}'.toLowerCase();
    if (g.contains('synth') ||
        g.contains('retro') ||
        g.contains('neon') ||
        g.contains('m83') ||
        g.contains('weeknd') ||
        g.contains('after hours') ||
        g.contains('starboy') ||
        g.contains('blinding') ||
        g.contains('electronic')) {
      return 'synthwave_electronic';
    }
    if (g.contains('pop') ||
        g.contains('dance') ||
        g.contains('disco') ||
        g.contains('dua') ||
        g.contains('styles') ||
        g.contains('stay') ||
        g.contains('laroi') ||
        g.contains('bieber') ||
        g.contains('nostalgia')) {
      return 'pop_dance';
    }
    if (g.contains('hip') ||
        g.contains('rap') ||
        g.contains('trap') ||
        g.contains('drake') ||
        g.contains('travis')) {
      return 'hiphop_rap';
    }
    if (g.contains('lo-fi') ||
        g.contains('chill') ||
        g.contains('ambient') ||
        g.contains('study') ||
        g.contains('deep focus')) {
      return 'lofi_chill';
    }
    return 'pop_dance';
  }

  /// Strictly checks if two songs share the same genre cluster
  static bool isSameGenreCluster(Song a, Song b) {
    return getPrimaryGenreCluster(a) == getPrimaryGenreCluster(b);
  }

  /// Computes a recommendation affinity score between seed and candidate.
  /// Returns 0.0 IMMEDIATELY if language or genre do not match!
  static double computeAffinity(Song seed, Song candidate) {
    if (seed.id == candidate.id) return 0.0;

    // 1. STRICT LANGUAGE MATCH (Never cross language barrier)
    if (!isSameLanguage(seed, candidate)) {
      return 0.0;
    }

    // 2. STRICT GENRE CLUSTER MATCH (Never cross genre barrier)
    if (!isSameGenreCluster(seed, candidate)) {
      return 0.0;
    }

    double score = 10.0; // Base score for matching language & genre

    // 3. Artist Affinity
    if (seed.artist.toLowerCase() == candidate.artist.toLowerCase()) {
      score += 15.0;
    } else {
      final seedArtists = seed.artist.toLowerCase().split(RegExp(r'[,&]'));
      final candArtists = candidate.artist.toLowerCase().split(RegExp(r'[,&]'));
      for (final a in seedArtists) {
        for (final b in candArtists) {
          if (a.trim().isNotEmpty && b.trim().isNotEmpty && (a.contains(b.trim()) || b.contains(a.trim()))) {
            score += 8.0;
          }
        }
      }
    }

    // 4. Source parity
    if (seed.source == candidate.source) {
      score += 2.0;
    }

    // 5. Track Duration / Tempo Proximity
    final durDiff = (seed.durationSeconds - candidate.durationSeconds).abs();
    if (durDiff < 40) {
      score += 4.0;
    } else if (durDiff < 90) {
      score += 2.0;
    }

    return score;
  }

  /// Generates a queue where every song is GUARANTEED to be in the same language and genre as seed.
  static List<Song> generateAlgorithmicQueue(Song seed, List<Song> allAvailable) {
    // Strictly filter out any song not matching language or genre
    final matchingCandidates = allAvailable.where((s) {
      if (s.id == seed.id) return false;
      if (!isSameLanguage(seed, s)) return false;
      if (!isSameGenreCluster(seed, s)) return false;
      return true;
    }).toList();

    // Sort by affinity descending
    matchingCandidates.sort((a, b) {
      final scoreA = computeAffinity(seed, a);
      final scoreB = computeAffinity(seed, b);
      return scoreB.compareTo(scoreA);
    });

    return [seed, ...matchingCandidates];
  }

  /// Get next algorithmic song that strictly matches the same language and genre
  static Song getNextAlgorithmicSong(Song current, List<Song> pool, Set<String> recentlyPlayed) {
    // Strictly filter pool to same language & same genre
    final matchingPool = pool.where((s) {
      if (s.id == current.id) return false;
      if (!isSameLanguage(current, s)) return false;
      if (!isSameGenreCluster(current, s)) return false;
      return true;
    }).toList();

    if (matchingPool.isEmpty) return current;

    final unplayed = matchingPool.where((s) => !recentlyPlayed.contains(s.id)).toList();
    final candidates = unplayed.isNotEmpty ? unplayed : matchingPool;

    candidates.sort((a, b) {
      final scoreA = computeAffinity(current, a);
      final scoreB = computeAffinity(current, b);
      return scoreB.compareTo(scoreA);
    });

    return candidates.first;
  }
}
