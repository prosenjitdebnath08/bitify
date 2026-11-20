package com.bitify.bitify

import android.content.Context
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bitify.bitify/audio_dsp"

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var currentSessionId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    val sessionId = getActiveAudioSessionId(flutterEngine)
                    initAudioEffects(sessionId)
                    result.success(getEqualizerInfo())
                }
                "setBandGain" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val gain = call.argument<Double>("gain") ?: 0.0 // in dB (-12.0 to +12.0)
                    try {
                        val eq = equalizer
                        if (eq != null) {
                            val numBands = eq.numberOfBands.toInt()
                            if (band in 0 until numBands) {
                                val mB = (gain * 100).toInt().coerceIn(-1500, 1500).toShort()
                                eq.setBandLevel(band.toShort(), mB)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EQ_ERROR", e.message, null)
                    }
                }
                "setBassBoost" -> {
                    val strength = call.argument<Double>("strength") ?: 0.0 // 0.0 to 1.0
                    try {
                        val str = (strength * 1000).toInt().coerceIn(0, 1000).toShort()
                        bassBoost?.let {
                            if (it.strengthSupported) {
                                it.setStrength(str)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BASS_ERROR", e.message, null)
                    }
                }
                "setVirtualizer" -> {
                    val strength = call.argument<Double>("strength") ?: 0.0 // 0.0 to 1.0
                    try {
                        val str = (strength * 1000).toInt().coerceIn(0, 1000).toShort()
                        virtualizer?.let {
                            if (it.strengthSupported) {
                                it.setStrength(str)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("VIRT_ERROR", e.message, null)
                    }
                }
                "setLoudness" -> {
                    val gainMb = call.argument<Int>("gainMb") ?: 0
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            loudnessEnhancer?.setTargetGain(gainMb.coerceIn(0, 800))
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOUD_ERROR", e.message, null)
                    }
                }
                "attachToPlayer" -> {
                    val sessionId = getActiveAudioSessionId(flutterEngine)
                    if (sessionId != currentSessionId && sessionId != 0) {
                        initAudioEffects(sessionId)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getActiveAudioSessionId(flutterEngine: FlutterEngine): Int {
        try {
            // Retrieve MediaPlayer from Audioplayers plugin via reflection
            val pluginClass = Class.forName("xyz.luan.audioplayers.AudioplayersPlugin")
            val plugin = flutterEngine.plugins.get(pluginClass) ?: return 0
            val playersField = pluginClass.getDeclaredField("players")
            playersField.isAccessible = true
            val players = playersField.get(plugin) as? Map<*, *> ?: return 0

            for (wrappedPlayer in players.values) {
                if (wrappedPlayer != null) {
                    val playerField = wrappedPlayer.javaClass.getDeclaredField("player")
                    playerField.isAccessible = true
                    val player = playerField.get(wrappedPlayer) ?: continue

                    val mpField = player.javaClass.getDeclaredField("mediaPlayer")
                    mpField.isAccessible = true
                    val mp = mpField.get(player) as? android.media.MediaPlayer ?: continue

                    val sid = mp.audioSessionId
                    if (sid > 0) return sid
                }
            }
        } catch (_: Throwable) {}
        return 0
    }

    private fun initAudioEffects(sessionId: Int) {
        try {
            releaseEffects()
            currentSessionId = sessionId

            equalizer = Equalizer(1000, sessionId).apply {
                enabled = true
            }

            bassBoost = BassBoost(1000, sessionId).apply {
                if (strengthSupported) {
                    enabled = true
                }
            }

            virtualizer = Virtualizer(1000, sessionId).apply {
                if (strengthSupported) {
                    enabled = true
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
                    enabled = true
                }
            }
        } catch (e: Exception) {
            // Fallback to session 0 if specific session ID instantiation failed
            if (sessionId != 0) {
                try {
                    initAudioEffects(0)
                } catch (_: Exception) {}
            }
        }
    }

    private fun getEqualizerInfo(): Map<String, Any> {
        val eq = equalizer ?: return emptyMap()
        val numBands = eq.numberOfBands.toInt()
        val freqs = mutableListOf<Int>()
        for (i in 0 until numBands) {
            freqs.add(eq.getCenterFreq(i.toShort()) / 1000) // in Hz
        }
        val range = eq.bandLevelRange
        return mapOf(
            "numberOfBands" to numBands,
            "centerFreqs" to freqs,
            "minLevel" to range[0].toInt(),
            "maxLevel" to range[1].toInt(),
            "sessionId" to currentSessionId
        )
    }

    private fun releaseEffects() {
        try {
            equalizer?.release()
            equalizer = null
            bassBoost?.release()
            bassBoost = null
            virtualizer?.release()
            virtualizer = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer?.release()
                loudnessEnhancer = null
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        releaseEffects()
        super.onDestroy()
    }
}
