import 'package:flutter_test/flutter_test.dart';
import 'package:bitify/data/mock_music_repository.dart';
import 'package:bitify/services/spotify_algorithm_service.dart';

void main() {
  group('SpotifyAlgorithmService Same-Language & Same-Genre Tests', () {
    final allSongs = MockMusicRepository.allSongs;
    final starboy = allSongs.firstWhere((s) => s.id == 's1'); // English Synthwave
    final kesariya = allSongs.firstWhere((s) => s.id == 's3'); // Hindi Bollywood
    final levitating = allSongs.firstWhere((s) => s.id == 's4'); // English Pop
    final bhalolaage = allSongs.firstWhere((s) => s.id == 's13'); // Bengali Melodies

    test('Strict Language Separation', () {
      expect(SpotifyAlgorithmService.normalizeLanguage(starboy), 'english');
      expect(SpotifyAlgorithmService.normalizeLanguage(kesariya), 'hindi');
      expect(SpotifyAlgorithmService.normalizeLanguage(levitating), 'english');
      expect(SpotifyAlgorithmService.normalizeLanguage(bhalolaage), 'bengali');

      expect(SpotifyAlgorithmService.isSameLanguage(starboy, kesariya), isFalse);
      expect(SpotifyAlgorithmService.isSameLanguage(starboy, bhalolaage), isFalse);
      expect(SpotifyAlgorithmService.isSameLanguage(kesariya, bhalolaage), isFalse);
      expect(SpotifyAlgorithmService.isSameLanguage(starboy, levitating), isTrue);
    });

    test('Strict Genre Separation', () {
      expect(SpotifyAlgorithmService.getPrimaryGenreCluster(starboy), 'synthwave_electronic');
      expect(SpotifyAlgorithmService.getPrimaryGenreCluster(kesariya), 'bollywood_romantic');
      expect(SpotifyAlgorithmService.getPrimaryGenreCluster(levitating), 'pop_dance');
      expect(SpotifyAlgorithmService.getPrimaryGenreCluster(bhalolaage), 'bengali_melodies');

      expect(SpotifyAlgorithmService.isSameGenreCluster(starboy, levitating), isFalse);
      expect(SpotifyAlgorithmService.isSameGenreCluster(starboy, kesariya), isFalse);
      expect(SpotifyAlgorithmService.isSameGenreCluster(kesariya, bhalolaage), isFalse);
    });

    test('Algorithmic Queue strictly contains only same language and same genre', () {
      // Test 1: Starboy seed (English Synthwave)
      final queueStarboy = SpotifyAlgorithmService.generateAlgorithmicQueue(starboy, allSongs);
      expect(queueStarboy.first.id, starboy.id);
      for (final s in queueStarboy) {
        expect(SpotifyAlgorithmService.isSameLanguage(starboy, s), isTrue,
            reason: '${s.title} (${s.language}) does not match Starboy language');
        expect(SpotifyAlgorithmService.isSameGenreCluster(starboy, s), isTrue,
            reason: '${s.title} (${s.genre}) does not match Starboy genre');
      }

      // Test 2: Kesariya seed (Hindi Bollywood)
      final queueKesariya = SpotifyAlgorithmService.generateAlgorithmicQueue(kesariya, allSongs);
      expect(queueKesariya.first.id, kesariya.id);
      for (final s in queueKesariya) {
        expect(SpotifyAlgorithmService.isSameLanguage(kesariya, s), isTrue,
            reason: '${s.title} (${s.language}) does not match Kesariya language');
        expect(SpotifyAlgorithmService.isSameGenreCluster(kesariya, s), isTrue,
            reason: '${s.title} (${s.genre}) does not match Kesariya genre');
      }

      // Test 3: Levitating seed (English Pop)
      final queueLevitating = SpotifyAlgorithmService.generateAlgorithmicQueue(levitating, allSongs);
      expect(queueLevitating.first.id, levitating.id);
      for (final s in queueLevitating) {
        expect(SpotifyAlgorithmService.isSameLanguage(levitating, s), isTrue,
            reason: '${s.title} (${s.language}) does not match Levitating language');
        expect(SpotifyAlgorithmService.isSameGenreCluster(levitating, s), isTrue,
            reason: '${s.title} (${s.genre}) does not match Levitating genre');
      }
    });

    test('Next Algorithmic Song never crosses language or genre barrier', () {
      final nextHindi = SpotifyAlgorithmService.getNextAlgorithmicSong(kesariya, allSongs, {kesariya.id});
      expect(SpotifyAlgorithmService.isSameLanguage(kesariya, nextHindi), isTrue);
      expect(SpotifyAlgorithmService.isSameGenreCluster(kesariya, nextHindi), isTrue);

      final nextSynth = SpotifyAlgorithmService.getNextAlgorithmicSong(starboy, allSongs, {starboy.id});
      expect(SpotifyAlgorithmService.isSameLanguage(starboy, nextSynth), isTrue);
      expect(SpotifyAlgorithmService.getPrimaryGenreCluster(nextSynth), 'synthwave_electronic');
    });

    test('Single Song Mode vs Playlist Mode', () {
      final playlist = MockMusicRepository.bollywoodPlaylists.first;
      expect(playlist.songs.isNotEmpty, isTrue);

      // Verify that playlist has multiple tracks
      expect(playlist.songs.length > 1, isTrue);
    });
  });
}
