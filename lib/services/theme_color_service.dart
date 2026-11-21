import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/music_models.dart';

class SongColorPalette {
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color shadowDark;
  final Color shadowLight;
  final Color glow;
  final Color textPrimary;
  final Color textSecondary;

  const SongColorPalette({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.shadowDark,
    required this.shadowLight,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
  });

  static SongColorPalette defaultPalette() {
    return const SongColorPalette(
      primary: Color(0xFF3880FF),
      accent: Color(0xFF06B6D4),
      background: Color(0xFFD6E6F2),
      surface: Color(0xFFDCEAF5),
      shadowDark: Color(0xFFB5C9D8),
      shadowLight: Color(0xFFFFFFFF),
      glow: Color(0x6606B6D4),
      textPrimary: Color(0xFF1E293B),
      textSecondary: Color(0xFF64748B),
    );
  }

  factory SongColorPalette.fromColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    
    // Create soft neumorphic pastel background derived from baseColor
    final bgHsl = hsl.withSaturation((hsl.saturation * 0.35).clamp(0.12, 0.38)).withLightness(0.88);
    final bg = bgHsl.toColor();
    
    // Surface is slightly lighter
    final surface = bgHsl.withLightness(0.92).toColor();
    
    // Shadows: dark bottom-right, light top-left
    final shadowDark = bgHsl.withLightness(0.76).toColor();
    final shadowLight = Colors.white.withOpacity(0.9);
    
    // Vibrant accent and glowing effect
    final vibrant = hsl.withSaturation(0.85).withLightness(0.50).toColor();
    final glow = vibrant.withOpacity(0.55);
    
    // High-contrast clean dark text
    final textPrimary = bgHsl.withSaturation(0.20).withLightness(0.15).toColor();
    final textSecondary = bgHsl.withSaturation(0.15).withLightness(0.42).toColor();

    return SongColorPalette(
      primary: vibrant,
      accent: hsl.withHue((hsl.hue + 30) % 360).withSaturation(0.80).withLightness(0.55).toColor(),
      background: bg,
      surface: surface,
      shadowDark: shadowDark,
      shadowLight: shadowLight,
      glow: glow,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
  }
}

class ThemeColorService extends ChangeNotifier {
  static final ThemeColorService _instance = ThemeColorService._internal();
  factory ThemeColorService() => _instance;
  ThemeColorService._internal();

  SongColorPalette _currentPalette = SongColorPalette.defaultPalette();
  SongColorPalette get palette => _currentPalette;

  final Map<String, SongColorPalette> _paletteCache = {
    's1': SongColorPalette.fromColor(const Color(0xFFE11D48)), // Starboy -> Ruby/Crimson
    's2': SongColorPalette.fromColor(const Color(0xFF0284C7)), // Midnight City -> Sky Blue (matches reference screenshot!)
    's3': SongColorPalette.fromColor(const Color(0xFFD97706)), // Kesariya -> Saffron/Amber
    's4': SongColorPalette.fromColor(const Color(0xFF7C3AED)), // Levitating -> Electric Violet
    's5': SongColorPalette.fromColor(const Color(0xFFBE123C)), // After Hours -> Deep Crimson
    's6': SongColorPalette.fromColor(const Color(0xFF0D9488)), // As It Was -> Teal
  };

  Future<void> updateForSong(Song? song) async {
    if (song == null) return;

    if (_paletteCache.containsKey(song.id)) {
      _currentPalette = _paletteCache[song.id]!;
      notifyListeners();
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(song.coverUrl),
        size: const Size(64, 64),
        maximumColorCount: 8,
      );

      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFF0284C7);

      final newPalette = SongColorPalette.fromColor(dominant);
      _paletteCache[song.id] = newPalette;
      _currentPalette = newPalette;
      notifyListeners();
    } catch (_) {
      // Fallback
      final newPalette = SongColorPalette.fromColor(const Color(0xFF0284C7));
      _currentPalette = newPalette;
      notifyListeners();
    }
  }
}
