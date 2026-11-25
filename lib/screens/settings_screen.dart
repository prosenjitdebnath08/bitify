import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/theme_color_service.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/update_dialog.dart';
import 'equalizer_screen.dart';

class SettingsScreen extends StatelessWidget {
  final MusicPlayerState state;

  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([state, ThemeColorService(), ProfileService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;
        final themeService = ThemeColorService();
        final profile = ProfileService();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Settings & Engine',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
            children: [
              // User Profile Banner (Editable)
              GestureDetector(
                onTap: () => _showEditProfileDialog(context, profile, p),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [p.primary, p.accent],
                          ),
                          border: Border.all(color: p.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: p.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit_rounded,
                                  color: p.primary,
                                  size: 14,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.tier,
                              style: TextStyle(
                                fontSize: 12,
                                color: p.accent,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'VIP',
                          style: TextStyle(
                            color: p.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Theme & Dynamic Color Adaptation (NEW)
              _buildSectionTitle('DYNAMIC THEME & APPEARANCE', p),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeService.themeMode == ThemeModeOption.dark
                              ? Icons.dark_mode_rounded
                              : (themeService.themeMode == ThemeModeOption.light
                                  ? Icons.light_mode_rounded
                                  : Icons.brightness_auto_rounded),
                          color: p.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adaptive Color Theme',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                themeService.themeMode == ThemeModeOption.dark
                                    ? 'Dark Mode • Song thumbnail adaptive dark tone'
                                    : (themeService.themeMode == ThemeModeOption.light
                                        ? 'Light Mode • Song thumbnail pastel adaptive'
                                        : 'System Default • Auto adapts to thumbnail & OS'),
                                style: TextStyle(color: p.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Theme Mode Selector
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeOptionButton(
                            title: 'Light',
                            icon: Icons.light_mode_rounded,
                            isSelected: themeService.themeMode == ThemeModeOption.light,
                            palette: p,
                            onTap: () => themeService.setThemeMode(ThemeModeOption.light),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeOptionButton(
                            title: 'Dark',
                            icon: Icons.dark_mode_rounded,
                            isSelected: themeService.themeMode == ThemeModeOption.dark,
                            palette: p,
                            onTap: () => themeService.setThemeMode(ThemeModeOption.dark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeOptionButton(
                            title: 'System',
                            icon: Icons.brightness_auto_rounded,
                            isSelected: themeService.themeMode == ThemeModeOption.system,
                            palette: p,
                            onTap: () => themeService.setThemeMode(ThemeModeOption.system),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Audio Fidelity & Engine
              _buildSectionTitle('AUDIO FIDELITY & ENGINE', p),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.high_quality_rounded, color: p.primary),
                      title: Text(
                        'Streaming Quality',
                        style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
                      ),
                      subtitle: Text(
                        state.audioQuality,
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.arrow_drop_down_rounded, color: p.textSecondary),
                        color: p.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: state.setAudioQuality,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'High Quality (256 kbps MP3)',
                            child: Text('High Quality (256 kbps MP3) • Recommended', style: TextStyle(color: p.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: 'Lossless FLAC (24-bit/96kHz)',
                            child: Text('Lossless FLAC (24-bit/96kHz) • Audiophile', style: TextStyle(color: p.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: 'Standard (160 kbps)',
                            child: Text('Standard (160 kbps)', style: TextStyle(color: p.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    ListTile(
                      leading: Icon(Icons.tune_rounded, color: p.accent),
                      title: Text(
                        'Graphic Equalizer',
                        style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
                      ),
                      subtitle: Text(
                        'Preset: ${state.currentPreset}',
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EqualizerScreen(state: state),
                          ),
                        );
                      },
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.waves_rounded, size: 20, color: p.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Crossfade Duration',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
                                  ),
                                ],
                              ),
                              Text(
                                '${state.crossfadeSeconds}s',
                                style: TextStyle(color: p.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Slider(
                            value: state.crossfadeSeconds.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            activeColor: p.primary,
                            onChanged: (val) => state.setCrossfade(val.toInt()),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.space_bar_rounded, color: p.textSecondary),
                      title: Text(
                        'Gapless Playback',
                        style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
                      ),
                      subtitle: Text(
                        'Seamless transition between tracks',
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                      value: state.gaplessPlayback,
                      activeColor: p.primary,
                      onChanged: state.toggleGapless,
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.equalizer_rounded, color: p.textSecondary),
                      title: Text(
                        'Normalize Volume',
                        style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
                      ),
                      subtitle: Text(
                        'Balance loudness across different platforms',
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                      value: state.normalizeVolume,
                      activeColor: p.primary,
                      onChanged: state.toggleNormalize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Connected Music Sources
              _buildSectionTitle('CONNECTED MUSIC SOURCES', p),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    _buildSourceTile(
                      title: 'YouTube API',
                      subtitle: 'Active Stream Source & Catalog',
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: const Color(0xFFFF0000),
                      isConnected: true,
                      onToggle: () {},
                      palette: p,
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    _buildSourceTile(
                      title: 'Spotify Web API',
                      subtitle: 'Metadata & Playlist Matching',
                      icon: Icons.graphic_eq_rounded,
                      iconColor: const Color(0xFF1DB954),
                      isConnected: true,
                      onToggle: () {},
                      palette: p,
                    ),
                    Divider(color: p.textSecondary.withOpacity(0.15), height: 1),
                    _buildSourceTile(
                      title: 'JioSaavn / iTunes Fallback',
                      subtitle: 'Lossless audio streaming proxy',
                      icon: Icons.music_note_rounded,
                      iconColor: const Color(0xFF2B5797),
                      isConnected: true,
                      onToggle: () {},
                      palette: p,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Software Updates
              _buildSectionTitle('SOFTWARE UPDATES', p),
              const SizedBox(height: 8),
              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.system_update_rounded, color: p.primary, size: 28),
                  title: Text(
                    'Check for Updates',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                  ),
                  subtitle: Text(
                    'Direct auto-updater with background APK installation',
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking for Bitify updates...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final info = await UpdateService.checkForUpdate();
                      if (context.mounted) {
                        showBitifyUpdateDialog(context, info);
                      }
                    },
                    child: const Text('Check Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Application Info (UPDATED WITH EXACT USER TEXT)
              _buildSectionTitle('APPLICATION INFO', p),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.album_rounded, color: p.primary, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitify',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              'Version 2.0.0 (Bitify Dynamic)',
                              style: TextStyle(color: p.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bitify is an independent high-fidelity Android music player and streaming application built with Flutter. It pairs a fluid glassmorphic and neumorphic UI with BitChord-inspired spring animations and dynamic wash playlist architecture, adaptive color theming (Bitify Dynamic), endless multi-platform playlist streaming from Spotify, YouTube, and JioSaavn, built-in studio audio DSP/equalizer controls, custom playlist creation and library management, offline download support, and high-bitrate Master Audio playback.',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, SongColorPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: p.textSecondary.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildThemeOptionButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required SongColorPalette palette,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.primary : palette.textSecondary.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.glow,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : palette.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isConnected,
    required VoidCallback onToggle,
    required SongColorPalette palette,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: palette.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: palette.textSecondary, fontSize: 12),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? palette.surface : palette.primary,
          foregroundColor: isConnected ? palette.textPrimary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onToggle,
        child: Text(isConnected ? 'Active' : 'Connect', style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileService profile, SongColorPalette p) {
    final nameController = TextEditingController(text: profile.name);
    final tierController = TextEditingController(text: profile.tier);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: p.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Edit Subscriber Profile',
              style: TextStyle(color: p.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display Name', style: TextStyle(color: p.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: TextStyle(color: p.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: p.background,
                hintText: 'Enter your name...',
                hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.textSecondary.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Subscriber Status / Bio', style: TextStyle(color: p.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: tierController,
              style: TextStyle(color: p.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: p.background,
                hintText: 'e.g. Bitify Ultra • Premium Subscriber',
                hintStyle: TextStyle(color: p.textSecondary.withOpacity(0.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.textSecondary.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              profile.updateProfile(
                name: nameController.text,
                tier: tierController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
