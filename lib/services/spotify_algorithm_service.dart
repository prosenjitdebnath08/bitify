import '../models/music_models.dart';

class SpotifyAlgorithmService {
  /// Computes a recommendation score between a seed song and a candidate song
  /// based on Spotify's acoustic and collaborative filtering heuristics.
  static double computeAffinity(Song seed, Song candidate) {
    if (seed.id == candidate.id) return 0.0;
    double score = 0.0;

    // 1. Artist Affinity
    if (seed.artist.toLowerCase() == candidate.artist.toLowerCase()) {
      score += 12.0;
    } else {
      final seedArtists = seed.artist.toLowerCase().split(RegExp(r'[,&]'));
      final candArtists = candidate.artist.toLowerCase().split(RegExp(r'[,&]'));
      for (final a in seedArtists) {
        for (final b in candArtists) {
          if (a.trim().isNotEmpty && b.trim().isNotEmpty && (a.contains(b.trim()) || b.contains(a.trim()))) {
            score += 7.0;
          }
        }
      }
    }

    // 2. Genre / Mood Affinity Heuristic
    final textSeed = '${seed.title} ${seed.album} ${seed.artist}'.toLowerCase();
    final textCand = '${candidate.title} ${candidate.album} ${candidate.artist}'.toLowerCase();

    final synthWaveKeywords = ['starboy', 'hours', 'midnight', 'm83', 'weeknd', 'synth', 'retro', 'neon'];
    final popDanceKeywords = ['levitating', 'nostalgia', 'dua', 'styles', 'dancing', 'stay', 'laroi', 'bieber'];
    final desiSoulKeywords = ['kesariya', 'pardesiya', 'arijit', 'pritam', 'shreya', 'brahmastra', 'kalank'];

    if (_hasMatch(textSeed, synthWaveKeywords) && _hasMatch(textCand, synthWaveKeywords)) {
      score += 10.0;
    }
    if (_hasMatch(textSeed, popDanceKeywords) && _hasMatch(textCand, popDanceKeywords)) {
      score += 9.0;
    }
    if (_hasMatch(textSeed, desiSoulKeywords) && _hasMatch(textCand, desiSoulKeywords)) {
      score += 11.0;
    }

    // 3. Audio Source Affinity
    if (seed.source == candidate.source) {
      score += 3.0;
    }

    // 4. Track Duration / Tempo Clustering
    final durDiff = (seed.durationSeconds - candidate.durationSeconds).abs();
    if (durDiff < 45) {
      score += 4.0;
    } else if (durDiff < 100) {
      score += 2.0;
    }

    // 5. Audio Quality parity
    if (seed.isLossless && candidate.isLossless) score += 2.0;
    if (seed.isDolbyAtmos && candidate.isDolbyAtmos) score += 2.0;

    return score;
  }

  static bool _hasMatch(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Sorts a playlist or candidate songs according to Spotify's song transition affinity
  static List<Song> generateAlgorithmicQueue(Song seed, List<Song> allAvailable) {
    final candidates = allAvailable.where((s) => s.id != seed.id).toList();

    candidates.sort((a, b) {
      final scoreA = computeAffinity(seed, a);
      final scoreB = computeAffinity(seed, b);
      return scoreB.compareTo(scoreA);
    });

    return [seed, ...candidates];
  }

  /// Get the next recommended song when current song finishes
  static Song getNextAlgorithmicSong(Song current, List<Song> pool, Set<String> recentlyPlayed) {
    final unplayed = pool.where((s) => !recentlyPlayed.contains(s.id) && s.id != current.id).toList();
    final candidates = unplayed.isNotEmpty ? unplayed : pool.where((s) => s.id != current.id).toList();

    if (candidates.isEmpty) return current;

    candidates.sort((a, b) {
      final scoreA = computeAffinity(current, a);
      final scoreB = computeAffinity(current, b);
      return scoreB.compareTo(scoreA);
    });

    return candidates.first;
  }
}
