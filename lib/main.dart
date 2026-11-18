import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/onboarding_screen.dart';
import 'state/music_player_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090A11),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BitifyApp());
}

class BitifyApp extends StatefulWidget {
  const BitifyApp({super.key});

  @override
  State<BitifyApp> createState() => _BitifyAppState();
}

class _BitifyAppState extends State<BitifyApp> {
  late final MusicPlayerState _playerState;

  @override
  void initState() {
    super.initState();
    _playerState = MusicPlayerState();
  }

  @override
  void dispose() {
    _playerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: OnboardingScreen(state: _playerState),
    );
  }
}
