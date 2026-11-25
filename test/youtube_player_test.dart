import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitify/models/music_models.dart';
import 'package:bitify/screens/now_playing_screen.dart';
import 'package:bitify/services/youtube_service.dart';
import 'package:bitify/state/music_player_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YouTubeService & Player Rectangle Mode Tests', () {
    test('extractVideoId parses yt:// and yt_ IDs accurately', () {
      const ytSong = Song(
        id: 'yt_dQw4w9WgXcQ',
        title: 'Test Video',
        artist: 'Test Artist',
        album: 'YouTube',
        durationSeconds: 212,
        coverUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        audioUrl: 'yt://dQw4w9WgXcQ',
        source: MusicSource.youtube,
      );
      expect(YouTubeService.extractVideoId(ytSong), 'dQw4w9WgXcQ');

      const spotifySong = Song(
        id: 's1',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        durationSeconds: 230,
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
        source: MusicSource.spotify,
      );
      expect(YouTubeService.extractVideoId(spotifySong), isNull);
    });

    test('YouTubeService.parseSearchResponse parses InnerTube videoRenderer JSON', () {
      const sampleJson = '''
      {
        "contents": {
          "twoColumnSearchResultsRenderer": {
            "primaryContents": {
              "sectionListRenderer": {
                "contents": [
                  {
                    "itemSectionRenderer": {
                      "contents": [
                        {
                          "videoRenderer": {
                            "videoId": "34Na4j8AVgA",
                            "title": {"runs": [{"text": "The Weeknd - Starboy ft. Daft Punk"}]},
                            "ownerText": {"runs": [{"text": "The Weeknd"}]},
                            "lengthText": {"simpleText": "4:33"}
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
      ''';

      final songs = YouTubeService.parseSearchResponse(sampleJson, query: 'Starboy');
      expect(songs.length, 1);
      expect(songs.first.id, 'yt_34Na4j8AVgA');
      expect(songs.first.title, 'The Weeknd - Starboy ft. Daft Punk');
      expect(songs.first.artist, 'The Weeknd');
      expect(songs.first.durationSeconds, 273);
      expect(songs.first.audioUrl, 'yt://34Na4j8AVgA');
      expect(songs.first.source, MusicSource.youtube);
    });

    test('Playlist queue advances sequentially 0->1->2->3->4 without jumping back to first two songs', () {
      final state = MusicPlayerState();
      final songs = List.generate(
        5,
        (i) => Song(
          id: 'pl_song_$i',
          title: 'Track $i',
          artist: i.isEven ? 'Artist A' : 'Artist B',
          album: 'Album',
          durationSeconds: 180 + i,
          coverUrl: 'https://example.com/$i.jpg',
          language: 'Hindi',
          genre: 'Bollywood',
        ),
      );

      state.setCurrentSongForTest(songs[0], queue: songs, isPlaylistQueue: true);
      expect(state.currentSong?.id, 'pl_song_0');

      state.next();
      expect(state.currentSong?.id, 'pl_song_1');

      state.next();
      expect(state.currentSong?.id, 'pl_song_2');

      state.next();
      expect(state.currentSong?.id, 'pl_song_3');

      state.next();
      expect(state.currentSong?.id, 'pl_song_4');

      // With default RepeatMode.all, wraps cleanly to index 0
      state.next();
      expect(state.currentSong?.id, 'pl_song_0');
    });

    testWidgets('NowPlayingScreen switches rotary disc to rectangle box with fullscreen for YouTube songs', (tester) async {
      final state = MusicPlayerState();

      const spotifySong = Song(
        id: 's1',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        durationSeconds: 230,
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
        source: MusicSource.spotify,
      );

      state.setCurrentSongForTest(spotifySong);

      await tester.pumpWidget(
        MaterialApp(
          home: NowPlayingScreen(state: state),
        ),
      );
      await tester.pump();

      // Spotify song should show rotary disc (ClipOval) and NOT fullscreen button
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.text('FULLSCREEN'), findsNothing);

      // Switch to YouTube song
      const ytSong = Song(
        id: 'yt_mock_1',
        title: 'YouTube Track',
        artist: 'YouTube Artist',
        album: 'YouTube',
        durationSeconds: 210,
        coverUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        source: MusicSource.youtube,
      );

      state.setCurrentSongForTest(ytSong);
      await tester.pump();

      // YouTube song should replace rotary disc with rectangle box + FULLSCREEN button
      expect(find.byType(ClipOval), findsNothing);
      expect(find.text('FULLSCREEN'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

      // Tap FULLSCREEN to open fullscreen player
      await tester.tap(find.text('FULLSCREEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);

      // Exit fullscreen
      await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FULLSCREEN'), findsOneWidget);
    });
  });
}
