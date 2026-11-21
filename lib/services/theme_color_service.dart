import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_models.dart';

enum ThemeModeOption {
  system,
  light,
  dark,
}

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
  final bool isDark;

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
    required this.isDark,
  });

  static SongColorPalette defaultPalette([ThemeModeOption mode = ThemeModeOption.system]) {
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final isDark = mode == ThemeModeOption.dark || (mode == ThemeModeOption.system && isPlatformDark);
    if (isDark) {
      return SongColorPalette.createDark(const Color(0xFF0284C7));
    } else {
      return SongColorPalette.createLight(const Color(0xFF0284C7));
    }
  }

  factory SongColorPalette.createDark(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);

    // Deep rich dark background with subtle tint of the song's hue
    final bg = HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 0.35).clamp(0.08, 0.28),
      0.09, // ~9% lightness
    ).toColor();

    // Slightly elevated surface for cards and capsules
    final surface = HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 0.30).clamp(0.08, 0.25),
      0.14, // ~14% lightness
    ).toColor();

    // Dual shadows for dark neumorphism
    final shadowDark = Colors.black.withOpacity(0.85);
    final shadowLight = HSLColor.fromAHSL(
      1.0,
      hsl.hue,
      (hsl.saturation * 0.20).clamp(0.05, 0.22),
      0.24,
    ).toColor().withOpacity(0.35);

    // Vibrant accent and glowing rim
    final vibrant = hsl.withSaturation(0.90).withLightness(0.55).toColor();
    final accent = hsl.withHue((hsl.hue + 35) % 360).withSaturation(0.85).withLightness(0.60).toColor();
    final glow = vibrant.withOpacity(0.65);

    // High contrast text for dark mode
    const textPrimary = Color(0xFFF8FAFC); // Slate-50 pure crisp white
    const textSecondary = Color(0xFF94A3B8); // Slate-400 clear readable gray

    return SongColorPalette(
      primary: vibrant,
      accent: accent,
      background: bg,
      surface: surface,
      shadowDark: shadowDark,
      shadowLight: shadowLight,
      glow: glow,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      isDark: true,
    );
  }

  factory SongColorPalette.createLight(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);

    // Soft neumorphic pastel background derived from song thumbnail hue
    final bgHsl = hsl.withSaturation((hsl.saturation * 0.28).clamp(0.12, 0.35)).withLightness(0.89);
    final bg = bgHsl.toColor();

    // Surface is slightly lighter
    final surface = bgHsl.withLightness(0.93).toColor();

    // Neumorphic shadows: dark bottom-right, light top-left
    final shadowDark = bgHsl.withLightness(0.75).toColor().withOpacity(0.85);
    final shadowLight = Colors.white.withOpacity(0.95);

    // Vibrant accent and glowing effect
    final vibrant = hsl.withSaturation(0.85).withLightness(0.48).toColor();
    final accent = hsl.withHue((hsl.hue + 30) % 360).withSaturation(0.80).withLightness(0.55).toColor();
    final glow = vibrant.withOpacity(0.45);

    // High-contrast clean dark text for light mode
    const textPrimary = Color(0xFF0F172A); // Slate-900 high contrast dark
    const textSecondary = Color(0xFF475569); // Slate-600

    return SongColorPalette(
      primary: vibrant,
      accent: accent,
      background: bg,
      surface: surface,
      shadowDark: shadowDark,
      shadowLight: shadowLight,
      glow: glow,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      isDark: false,
    );
  }

  factory SongColorPalette.fromColor(
    Color baseColor, {
    ThemeModeOption themeMode = ThemeModeOption.system,
  }) {
    bool shouldBeDark;
    switch (themeMode) {
      case ThemeModeOption.dark:
        shouldBeDark = true;
        break;
      case ThemeModeOption.light:
        shouldBeDark = false;
        break;
      case ThemeModeOption.system:
        final isThumbnailDark = baseColor.computeLuminance() < 0.35 ||
            HSLColor.fromColor(baseColor).lightness < 0.40;
        final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        // In system default: dark if thumbnail itself is dark or if platform is dark
        shouldBeDark = isThumbnailDark || isPlatformDark;
        break;
    }

    if (shouldBeDark) {
      return SongColorPalette.createDark(baseColor);
    } else {
      return SongColorPalette.createLight(baseColor);
    }
  }
}

class ThemeColorService extends ChangeNotifier {
  static final ThemeColorService _instance = ThemeColorService._internal();
  factory ThemeColorService() => _instance;

  static const String _prefThemeKey = 'bitify_theme_mode_preference';

  ThemeModeOption _themeMode = ThemeModeOption.system;
  ThemeModeOption get themeMode => _themeMode;

  Song? _lastSong;
  Song? get lastSong => _lastSong;

  SongColorPalette _currentPalette = SongColorPalette.defaultPalette();
  SongColorPalette get palette => _currentPalette;

  final Map<String, Color> _baseColorCache = {
    's1': const Color(0xFF1E070B), // Starboy -> Dark Crimson / Obsidian
    's2': const Color(0xFF0284C7), // Midnight City -> Sky Blue
    's3': const Color(0xFFD97706), // Kesariya -> Saffron / Warm Amber
    's4': const Color(0xFF3B0764), // Levitating -> Dark Electric Purple
    's5': const Color(0xFF180306), // After Hours -> Midnight Crimson
    's6': const Color(0xFF0D9488), // As It Was -> Teal
  };

  ThemeColorService._internal() {
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_prefThemeKey);
      if (modeStr == 'dark') {
        _themeMode = ThemeModeOption.dark;
      } else if (modeStr == 'light') {
        _themeMode = ThemeModeOption.light;
      } else {
        _themeMode = ThemeModeOption.system;
      }
      _recalculateCurrentPalette();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, mode.name);
    } catch (_) {}
    _recalculateCurrentPalette();
  }

  /// Cycles between System -> Light -> Dark -> System
  Future<void> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeModeOption.system:
        await setThemeMode(ThemeModeOption.light);
        break;
      case ThemeModeOption.light:
        await setThemeMode(ThemeModeOption.dark);
        break;
      case ThemeModeOption.dark:
        await setThemeMode(ThemeModeOption.system);
        break;
    }
  }

  void _recalculateCurrentPalette() {
    if (_lastSong != null && _baseColorCache.containsKey(_lastSong!.id)) {
      _currentPalette = SongColorPalette.fromColor(
        _baseColorCache[_lastSong!.id]!,
        themeMode: _themeMode,
      );
    } else {
      _currentPalette = SongColorPalette.defaultPalette(_themeMode);
    }
    notifyListeners();
  }

  Future<void> updateForSong(Song? song) async {
    if (song == null) return;
    _lastSong = song;

    if (_baseColorCache.containsKey(song.id)) {
      _currentPalette = SongColorPalette.fromColor(
        _baseColorCache[song.id]!,
        themeMode: _themeMode,
      );
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

      _baseColorCache[song.id] = dominant;
      _currentPalette = SongColorPalette.fromColor(dominant, themeMode: _themeMode);
      notifyListeners();
    } catch (_) {
      // Fallback
      const fallback = Color(0xFF0284C7);
      _baseColorCache[song.id] = fallback;
      _currentPalette = SongColorPalette.fromColor(fallback, themeMode: _themeMode);
      notifyListeners();
    }
  }
}
