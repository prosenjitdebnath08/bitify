import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../services/update_service.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/update_dialog.dart';
import 'equalizer_screen.dart';

class SettingsScreen extends StatelessWidget {
  final MusicPlayerState state;

  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Settings & Engine',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // User Profile Banner
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryLight, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Carter',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bitify Ultra • Lossless Subscriber',
                            style: TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('PRO', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Audio Fidelity & Engine
              _buildSectionTitle('AUDIO FIDELITY & ENGINE'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.high_quality_rounded, color: AppTheme.primaryLight),
                      title: const Text('Streaming Quality', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(state.audioQuality, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                        color: AppTheme.surfaceElevated,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: state.setAudioQuality,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'High Quality (256 kbps MP3)',
                            child: Text('High Quality (256 kbps MP3) • Recommended'),
                          ),
                          const PopupMenuItem(
                            value: 'Lossless FLAC (24-bit/96kHz)',
                            child: Text('Lossless FLAC (24-bit/96kHz) • Audiophile'),
                          ),
                          const PopupMenuItem(
                            value: 'Standard (160 kbps)',
                            child: Text('Standard (160 kbps)'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppTheme.secondary),
                      title: const Text('Graphic Equalizer', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Preset: ${state.currentPreset}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EqualizerScreen(state: state),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.waves_rounded, size: 20, color: AppTheme.accentPink),
                                  SizedBox(width: 10),
                                  Text('Crossfade Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text('${state.crossfadeSeconds}s', style: const TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Slider(
                            value: state.crossfadeSeconds.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            activeColor: AppTheme.accentPink,
                            onChanged: (val) => state.setCrossfade(val.toInt()),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.space_bar_rounded, color: Colors.white70),
                      title: const Text('Gapless Playback', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Seamless transition between tracks', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      value: state.gaplessPlayback,
                      activeColor: AppTheme.primary,
                      onChanged: state.toggleGapless,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.equalizer_rounded, color: Colors.white70),
                      title: const Text('Normalize Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Balance loudness across different platforms', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      value: state.normalizeVolume,
                      activeColor: AppTheme.primary,
                      onChanged: state.toggleNormalize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Connected Music Sources (Replicating BitChord aggregation)
              _buildSectionTitle('CONNECTED MUSIC SOURCES'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    _buildSourceTile(
                      title: 'YouTube Music Engine',
                      subtitle: state.isYoutubeConnected ? 'Connected & Synced' : 'Disconnected',
                      icon: Icons.play_arrow_rounded,
                      iconColor: const Color(0xFFEF4444),
                      isConnected: state.isYoutubeConnected,
                      onToggle: () => state.toggleSourceConnection(MusicSource.youtube),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSourceTile(
                      title: 'Spotify Integration',
                      subtitle: state.isSpotifyConnected ? 'Token Bridge Active' : 'Disconnected',
                      icon: Icons.graphic_eq_rounded,
                      iconColor: const Color(0xFF10B981),
                      isConnected: state.isSpotifyConnected,
                      onToggle: () => state.toggleSourceConnection(MusicSource.spotify),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _buildSourceTile(
                      title: 'JioSaavn API Engine',
                      subtitle: state.isJiosaavnConnected ? 'Lossless Direct Stream' : 'Disconnected',
                      icon: Icons.library_music_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      isConnected: state.isJiosaavnConnected,
                      onToggle: () => state.toggleSourceConnection(MusicSource.jiosaavn),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.share_rounded, color: Colors.redAccent),
                      title: const Text('Last.fm Scrobbler', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Auto-scrobble all played tracks to Last.fm', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Switch(
                        value: state.isLastFmConnected,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          state.toggleLastFm();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(val ? 'Last.fm Scrobbler enabled' : 'Last.fm Scrobbler disabled')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: App Updates
              _buildSectionTitle('UPDATES & VERSIONS'),
              const SizedBox(height: 8),
              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.system_update_rounded, color: AppTheme.secondary, size: 22),
                  ),
                  title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Current: ${UpdateService.currentVersion} • GitHub Auto-Sync', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking GitHub for updates...'),
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

              // Section: About & Info
              _buildSectionTitle('APPLICATION INFO'),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.album_rounded, color: AppTheme.primaryLight, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bitify', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('Version 2.0.0 (Fresh Architecture)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Re-engineered from BitChord with a fresh, modern dark neon UI, glassmorphism, multi-source aggregation (YouTube Music, Spotify, JioSaavn), and real-time audio DSP.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textMuted,
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.white10 : AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onToggle,
        child: Text(isConnected ? 'Disconnect' : 'Connect', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
