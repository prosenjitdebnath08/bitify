import 'package:flutter/material.dart';
import '../state/music_player_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class EqualizerScreen extends StatelessWidget {
  final MusicPlayerState state;

  const EqualizerScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final presets = [
      'Bitify Dynamic',
      'Bass Boost',
      'EDM / Dance',
      'Acoustic / Vocal',
      'Rock',
      'Flat',
    ];

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Equalizer & Audio DSP'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: () => state.applyPreset('Flat'),
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Presets horizontal scroll
                const Text(
                  'PRESETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = presets[i];
                      final isSelected = state.currentPreset == p;

                      return GestureDetector(
                        onTap: () => state.applyPreset(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryLight
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 10-Band EQ Glass Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '10-Band Graphic Equalizer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              state.currentPreset,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Slider row
                      SizedBox(
                        height: 230,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(state.eqFrequencies.length, (index) {
                            final freq = state.eqFrequencies[index];
                            final gain = state.bandGains[index];

                            return Column(
                              children: [
                                // dB readout
                                Text(
                                  '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: gain != 0
                                        ? AppTheme.secondary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Vertical Slider
                                Expanded(
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        activeTrackColor: AppTheme.primary,
                                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: gain,
                                        min: -12.0,
                                        max: 12.0,
                                        onChanged: (newGain) {
                                          state.setBandGain(index, newGain);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Freq label
                                Text(
                                  freq,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Audio Enhancers: Bass Boost & 3D Spatial Virtualizer
                const Text(
                  'ACOUSTIC ENHANCEMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                GlassCard(
                  child: Column(
                    children: [
                      // Bass Boost
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.speaker_rounded,
                              color: AppTheme.accentPink,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Sub-Bass Boost',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${(state.bassBoost * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: AppTheme.accentPink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.bassBoost,
                                  activeColor: AppTheme.accentPink,
                                  inactiveColor: Colors.white12,
                                  onChanged: state.setBassBoost,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 28),

                      // 3D Virtualizer
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.surround_sound_rounded,
                              color: AppTheme.secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '3D Spatial Virtualizer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${(state.virtualizer * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.virtualizer,
                                  activeColor: AppTheme.secondary,
                                  inactiveColor: Colors.white12,
                                  onChanged: state.setVirtualizer,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
