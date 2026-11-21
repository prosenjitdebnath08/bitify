import 'package:flutter/material.dart';
import '../services/theme_color_service.dart';
import '../state/music_player_state.dart';
import '../widgets/glass_card.dart';

class EqualizerScreen extends StatelessWidget {
  final MusicPlayerState state;

  const EqualizerScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final presets = [
      'Flat',
      'Bass Boost',
      'Vocal Boost',
      'Electronic',
      'Rock',
      'Hip Hop',
      'Acoustic',
      'Treble Boost',
      'Classical',
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([state, ThemeColorService()]),
      builder: (context, _) {
        final p = ThemeColorService().palette;

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Equalizer & Audio DSP',
              style: TextStyle(
                color: p.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: p.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: () => state.applyPreset('Flat'),
                child: Text(
                  'Reset',
                  style: TextStyle(color: p.primary, fontWeight: FontWeight.w700),
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
                Text(
                  'PRESETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: p.textSecondary,
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
                      final presetName = presets[i];
                      final isSelected = state.currentPreset == presetName;

                      return GestureDetector(
                        onTap: () => state.applyPreset(presetName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? p.primary : p.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? p.primary
                                  : p.textSecondary.withOpacity(0.2),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: p.glow,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            presetName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : p.textPrimary,
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
                          Text(
                            '10-Band Graphic Equalizer',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              state.currentPreset,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.primary,
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
                                    color: gain != 0 ? p.primary : p.textSecondary,
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
                                        activeTrackColor: p.primary,
                                        inactiveTrackColor: p.textSecondary.withOpacity(0.2),
                                        thumbColor: p.primary,
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
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: p.textSecondary,
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
                Text(
                  'ACOUSTIC ENHANCEMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: p.textSecondary,
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
                              color: p.accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.speaker_rounded,
                              color: p.accent,
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
                                    Text(
                                      'Sub-Bass Boost',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${(state.bassBoost * 100).toInt()}%',
                                      style: TextStyle(
                                        color: p.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.bassBoost,
                                  activeColor: p.accent,
                                  inactiveColor: p.textSecondary.withOpacity(0.2),
                                  onChanged: state.setBassBoost,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: p.textSecondary.withOpacity(0.15), height: 28),

                      // 3D Virtualizer
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: p.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.surround_sound_rounded,
                              color: p.primary,
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
                                    Text(
                                      '3D Spatial Virtualizer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${(state.virtualizer * 100).toInt()}%',
                                      style: TextStyle(
                                        color: p.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.virtualizer,
                                  activeColor: p.primary,
                                  inactiveColor: p.textSecondary.withOpacity(0.2),
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
