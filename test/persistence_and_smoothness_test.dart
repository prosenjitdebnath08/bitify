import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitify/models/music_models.dart';
import 'package:bitify/state/music_player_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
      const EventChannel('xyz.luan/audioplayers.global/events'),
      MockStreamHandler.inline(onListen: (_, __) {}),
    );
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
      final args = call.arguments;
      if (args is Map && args['playerId'] != null) {
        final pid = args['playerId'].toString();
        messenger.setMockStreamHandler(
          EventChannel('xyz.luan/audioplayers/events/$pid'),
          MockStreamHandler.inline(onListen: (_, __) {}),
        );
      }
      return null;
    });
    for (final channelName in [
      'xyz.luan/audioplayers.global',
      'com.bitify.bitify/audio_dsp',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channelName), (call) async {
        return null;
      });
    }
  });

  group('Last Played Persistence & Smooth Tick Tests', () {
    testWidgets('Restores last played YouTube song instead of defaulting to Starboy', (tester) async {
      const savedSong = Song(
        id: 'yt_osui2894',
        title: 'Sabrina Carpenter - Espresso',
        artist: 'Sabrina Carpenter',
        album: 'YouTube',
        durationSeconds: 200,
        coverUrl: '',
        audioUrl: 'yt://osui2894',
        source: MusicSource.youtube,
        lyrics: [LyricLine(second: 2, text: 'Streaming from YouTube')],
      );

      SharedPreferences.setMockInitialValues({
        'bitify_last_song_v1': jsonEncode(savedSong.toJson()),
        'bitify_last_position_v1': 47,
        'bitify_last_duration_v1': 200,
        'bitify_is_playlist_queue_v1': true,
        'bitify_last_queue_v1': jsonEncode([savedSong.toJson()]),
      });

      final state = MusicPlayerState();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      expect(state.currentSong?.id, 'yt_osui2894');
      expect(state.currentSong?.title, 'Sabrina Carpenter - Espresso');
      expect(state.currentSong?.source, MusicSource.youtube);
      expect(state.currentSong?.lyrics.length, 1);
      expect(state.positionSeconds, 47);
      expect(state.isPlaylistQueue, isTrue);

      state.dispose();
    });

    testWidgets('Falls back cleanly when no previous song was saved', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final state = MusicPlayerState();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      expect(state.currentSong, isNotNull);
      expect(state.currentSong?.title, 'Starboy');

      state.dispose();
    });

    testWidgets('seekTo updates positionNotifier without spamming whole-state ChangeNotifier', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final state = MusicPlayerState();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));

      int wholeStateNotifications = 0;
      int positionNotifications = 0;
      state.addListener(() => wholeStateNotifications++);
      state.positionNotifier.addListener(() => positionNotifications++);

      // seekTo updates positionNotifier immediately before awaiting platform channel seek
      final seekFuture = state.seekTo(42);
      expect(state.positionSeconds, 42);
      expect(positionNotifications, 1);
      expect(wholeStateNotifications, 0);
      await tester.runAsync(() => seekFuture.timeout(const Duration(milliseconds: 200), onTimeout: () {}));

      state.dispose();
    });
  });
}
