package com.bitify.bitify

import android.content.Context
import android.content.Intent
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "BitifyDSP"
    private val CHANNEL = "com.bitify.bitify/audio_dsp"

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var currentSessionId: Int = 0

    // Cached audio DSP state to re-apply whenever a new song plays
    private val savedBandGains = mutableMapOf<Int, Double>()
    private var savedBassBoost: Double = 0.55
    private var savedVirtualizer: Double = 0.40

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
                    savedBandGains[band] = gain
                    checkAndReattachIfSessionChanged(flutterEngine)
                    applyBandGain(band, gain)
                    result.success(true)
                }
                "setBassBoost" -> {
                    val strength = call.argument<Double>("strength") ?: 0.0 // 0.0 to 1.0
                    savedBassBoost = strength
                    checkAndReattachIfSessionChanged(flutterEngine)
                    applyBassBoost(strength)
                    result.success(true)
                }
                "setVirtualizer" -> {
                    val strength = call.argument<Double>("strength") ?: 0.0 // 0.0 to 1.0
                    savedVirtualizer = strength
                    checkAndReattachIfSessionChanged(flutterEngine)
                    applyVirtualizer(strength)
                    result.success(true)
                }
                "setLoudness" -> {
                    val gainMb = call.argument<Int>("gainMb") ?: 0
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            loudnessEnhancer?.setTargetGain(gainMb.coerceIn(0, 1000))
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOUD_ERROR", e.message, null)
                    }
                }
                "attachToPlayer" -> {
                    val sessionId = getActiveAudioSessionId(flutterEngine)
                    if (sessionId != 0 && sessionId != currentSessionId) {
                        initAudioEffects(sessionId)
                    } else if (equalizer == null) {
                        initAudioEffects(sessionId)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndReattachIfSessionChanged(flutterEngine: FlutterEngine) {
        val sid = getActiveAudioSessionId(flutterEngine)
        if (sid != 0 && sid != currentSessionId) {
            initAudioEffects(sid)
        }
    }

    private fun getActiveAudioSessionId(flutterEngine: FlutterEngine): Int {
        try {
            val registryClass = Class.forName("io.flutter.embedding.engine.plugins.PluginRegistry")
            val getMethod = registryClass.getMethod("get", Class::class.java)
            getMethod.isAccessible = true
            val pluginClass = Class.forName("xyz.luan.audioplayers.AudioplayersPlugin")
            val plugin = getMethod.invoke(flutterEngine.plugins, pluginClass) ?: return 0

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
                    if (sid > 0) {
                        Log.d(TAG, "Discovered active MediaPlayer audioSessionId: $sid")
                        return sid
                    }
                }
            }
        } catch (e: Throwable) {
            Log.e(TAG, "Error looking up audioSessionId: ${e.message}")
        }
        return 0
    }

    private fun initAudioEffects(sessionId: Int) {
        releaseEffects()
        currentSessionId = sessionId
        Log.d(TAG, "Initializing hardware audio effects on session: $sessionId")

        try {
            // Broadcast intent to inform Android audio manager of the effect session
            if (sessionId > 0) {
                val intent = Intent("android.media.action.OPEN_AUDIO_EFFECT_CONTROL_SESSION").apply {
                    putExtra("android.media.extra.AUDIO_SESSION", sessionId)
                    putExtra("android.media.extra.PACKAGE_NAME", packageName)
                }
                sendBroadcast(intent)
            }

            equalizer = Equalizer(0, sessionId).apply {
                enabled = true
            }
            Log.d(TAG, "Hardware Equalizer initialized with ${equalizer?.numberOfBands} bands")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Equalizer on session $sessionId: ${e.message}")
            if (sessionId != 0) {
                try {
                    equalizer = Equalizer(0, 0).apply { enabled = true }
                } catch (_: Exception) {}
            }
        }

        try {
            bassBoost = BassBoost(0, sessionId).apply {
                if (strengthSupported) {
                    enabled = true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create BassBoost on session $sessionId: ${e.message}")
        }

        try {
            virtualizer = Virtualizer(0, sessionId).apply {
                if (strengthSupported) {
                    enabled = true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create Virtualizer on session $sessionId: ${e.message}")
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
                    enabled = true
                }
            }
        } catch (_: Exception) {}

        // Immediately re-apply cached band gains, bass boost, and virtualizer
        for ((band, gain) in savedBandGains) {
            applyBandGain(band, gain)
        }
        applyBassBoost(savedBassBoost)
        applyVirtualizer(savedVirtualizer)
    }

    private fun applyBandGain(band: Int, gainDb: Double) {
        val eq = equalizer ?: return
        try {
            val numBands = eq.numberOfBands.toInt()
            if (band in 0 until numBands) {
                val range = eq.bandLevelRange
                val maxMb = range[1].toDouble()
                val mB = (gainDb / 12.0 * maxMb).toInt().coerceIn(range[0].toInt(), range[1].toInt()).toShort()
                eq.setBandLevel(band.toShort(), mB)
                Log.d(TAG, "Set band $band ($gainDb dB) -> $mB mB")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting band $band: ${e.message}")
        }
    }

    private fun applyBassBoost(strength: Double) {
        val bb = bassBoost ?: return
        try {
            if (bb.strengthSupported) {
                val str = (strength * 1000).toInt().coerceIn(0, 1000).toShort()
                bb.setStrength(str)
                Log.d(TAG, "Set BassBoost strength -> $str")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting BassBoost: ${e.message}")
        }
    }

    private fun applyVirtualizer(strength: Double) {
        val virt = virtualizer ?: return
        try {
            if (virt.strengthSupported) {
                val str = (strength * 1000).toInt().coerceIn(0, 1000).toShort()
                virt.setStrength(str)
                Log.d(TAG, "Set Virtualizer strength -> $str")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting Virtualizer: ${e.message}")
        }
    }

    private fun getEqualizerInfo(): Map<String, Any> {
        val eq = equalizer ?: return emptyMap()
        val numBands = eq.numberOfBands.toInt()
        val freqs = mutableListOf<Int>()
        for (i in 0 until numBands) {
            freqs.add(eq.getCenterFreq(i.toShort()) / 1000)
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
