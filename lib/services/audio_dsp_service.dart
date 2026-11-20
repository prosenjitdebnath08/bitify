import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioDspService {
  static const MethodChannel _channel = MethodChannel('com.bitify.bitify/audio_dsp');

  static bool _isAvailable = false;
  static int _numberOfBands = 5;
  static List<int> _centerFreqs = [60, 230, 910, 3600, 14000];

  static bool get isAvailable => _isAvailable;
  static int get numberOfBands => _numberOfBands;
  static List<int> get centerFreqs => _centerFreqs;

  static Future<void> init() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('init');
      if (res != null) {
        _isAvailable = true;
        _numberOfBands = (res['numberOfBands'] as int?) ?? 5;
        final freqs = res['centerFreqs'] as List<dynamic>?;
        if (freqs != null && freqs.isNotEmpty) {
          _centerFreqs = freqs.map((f) => (f as num).toInt()).toList();
        }
      }
    } catch (e) {
      debugPrint('AudioDspService init error (platform may not be Android): $e');
    }
  }

  static Future<void> setBandGain(int band, double gainDb) async {
    try {
      await _channel.invokeMethod('setBandGain', {
        'band': band,
        'gain': gainDb,
      });
    } catch (_) {}
  }

  static Future<void> setBassBoost(double strength) async {
    try {
      await _channel.invokeMethod('setBassBoost', {
        'strength': strength,
      });
    } catch (_) {}
  }

  static Future<void> setVirtualizer(double strength) async {
    try {
      await _channel.invokeMethod('setVirtualizer', {
        'strength': strength,
      });
    } catch (_) {}
  }

  static Future<void> setLoudness(int gainMb) async {
    try {
      await _channel.invokeMethod('setLoudness', {
        'gainMb': gainMb,
      });
    } catch (_) {}
  }

  static Future<void> attachToPlayerAndApply({
    required List<double> bandGains,
    required double bassBoost,
    required double virtualizer,
  }) async {
    try {
      await _channel.invokeMethod('attachToPlayer');
      for (int i = 0; i < bandGains.length && i < _numberOfBands; i++) {
        await setBandGain(i, bandGains[i]);
      }
      await setBassBoost(bassBoost);
      await setVirtualizer(virtualizer);
    } catch (_) {}
  }
}
