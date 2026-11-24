import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitify/models/music_models.dart';
import 'package:bitify/services/theme_color_service.dart';
import 'package:bitify/state/music_player_state.dart';
import 'package:bitify/screens/playlist_detail_screen.dart';
import 'package:bitify/widgets/bitchord_card_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockSongs = [
    const Song(
      id: 'test_s1',
      title: 'Kesariya',
      artist: 'Arijit Singh, Pritam',
      album: 'Brahmastra',
      durationSeconds: 268,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      audioUrl: 'https://actions.google.com/sounds/v1/ambiences/rain_heavy.ogg',
      language: 'Hindi',
      genre: 'Bollywood',
    ),
    const Song(
      id: 'test_s2',
      title: 'Apna Bana Le',
      artist: 'Arijit Singh, Sachin-Jigar',
      album: 'Bhediya',
      durationSeconds: 261,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      audioUrl: 'https://actions.google.com/sounds/v1/ambiences/rain_heavy.ogg',
      language: 'Hindi',
      genre: 'Bollywood',
    ),
  ];

  final mockPlaylist = Playlist(
    id: 'test_pl_1',
    title: 'Bollywood Romance Flow',
    description: 'Soulful love songs, acoustic feelings, and heartwarming duets.',
    coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
    songs: mockSongs,
    source: MusicSource.spotify,
  );

  group('BitChord v1.9 Component & Playlist Tests', () {
    testWidgets('BitChordCardMotion responds to touch and scales smoothly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BitChordCardMotion(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 150,
                  height: 150,
                  child: Text('Card Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);

      // Tap on card
      await tester.tap(find.text('Card Content'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('PlaylistDetailScreen renders BitChord header, action pills and tracks', (tester) async {
      final state = MusicPlayerState();

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistDetailScreen(
            playlist: mockPlaylist,
            state: state,
            initialPalette: SongColorPalette.defaultPalette(),
          ),
        ),
      );

      // Verify playlist title and metadata
      expect(find.text('Bollywood Romance Flow'), findsAtLeastNWidgets(1));
      expect(find.text('2 Tracks'), findsOneWidget);
      expect(find.text('LOSSLESS'), findsOneWidget);

      // Verify ActionPills
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      // Verify song titles in CompactSongRow
      expect(find.text('Kesariya'), findsOneWidget);
      expect(find.text('Apna Bana Le'), findsOneWidget);

      // Test tapping search icon toggles DetailSearchField
      await tester.tap(find.byIcon(Icons.search_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter search query 'Apna'
      await tester.enterText(find.byType(TextField), 'Apna');
      await tester.pumpAndSettle();

      // Kesariya filtered out, Apna Bana Le visible
      expect(find.text('Apna Bana Le'), findsOneWidget);
      expect(find.text('Kesariya'), findsNothing);
    });
  });
}
