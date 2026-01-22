package com.minfo_sdk

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.cifrasoft.services.SoundCodeUltraCode
import com.cifrasoft.services.SoundCodeUltraCodeListener
import com.cifrasoft.services.SoundCodeUltraCodeSettings

class MinfoSdkPlugin: FlutterPlugin, MethodCallHandler {
    // Constantes exactes du fichier de référence
    private val DEFAULT_COUNTER_LENGTH: Int = 1
    private val DEFAULT_COUNTER_INCREMENT: Int = 1
    private val DEFAULT_COUNTER_START_VALUE: Int = 0
    private val DEFAULT_DELAY_ADJUSTMENT: Float = +0.6f

    // Channels
    private lateinit var channel: MethodChannel
    private lateinit var minfoChannel: MethodChannel
    private lateinit var context: Context

    // Constantes pour le channel audioCapture
    private val CHANNEL = "com.gzone.campaign/audioCapture"
    private val START_AUDIO_CAPTURE = "startAudioCapture"
    private val STOP_AUDIO_CAPTURE = "stopAudioCapture"
    private val ON_DETECTED_ID = "onDetectedId"

    // Listener exact du fichier de référence
    private val scuclistener = object : SoundCodeUltraCodeListener {
        override fun onDetectedSCId(result: LongArray) {
            Log.i(TAG, "=================================override fun onDetectedSCId")
            Log.i(TAG, "detectedId id: " + java.lang.Long.toString(result[1]) + " / counter: " + result[2] + " / timestamp: " + "[" + java.lang.Float.toString((result[3] / 100).toFloat() / 10) + "] sec.")

            // Créer un nouveau tableau avec l'identifiant de type pour les sons normaux
            val resultWithType = longArrayOf(0L, result[1], result[2], result[3]) // 0 = Sons normaux

            minfoChannel.invokeMethod(ON_DETECTED_ID, resultWithType)
        }

        override fun onDetectedUCId(result: LongArray) {
            Log.i(TAG, "=================================override fun onDetectedUCId")
            Log.i(TAG, "detectedId id: " + java.lang.Long.toString(result[1]) + " / counter: " + result[2] + " / timestamp: " + "[" + java.lang.Float.toString((result[3] / 100).toFloat() / 10) + "] sec.")

            // Créer un nouveau tableau avec l'identifiant de type pour les ultrasons
            val resultWithType = longArrayOf(1L, result[1], result[2], result[3]) // 1 = Ultrasons

            minfoChannel.invokeMethod(ON_DETECTED_ID, resultWithType)
        }

        override fun onAudioInitFailed() {
            Log.i(TAG, "AUDIO SEARCH\nSERVICE_UNAVAILABLE!")
        }
    }

    // Méthodes exactes du fichier de référence
    fun startAudioCapture() {
        SoundCodeUltraCode.instance(context).startSearch()
        Log.i(TAG, "start recording ...")
    }

    fun stopAudioCapture() {
        SoundCodeUltraCode.instance(context).stopSearch()
        Log.i(TAG, "stopped recording")
    }

    companion object {
        private const val TAG = "MinfoSDK"
    }

    private fun getAudioEngine(): SoundCodeUltraCode {
        try {
            return SoundCodeUltraCode.instance(context)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Cifrasoft libs non disponibles: ${e.message}")
            throw RuntimeException("Cifrasoft SoundCode library not available: ${e.message}")
        }
    }

    private fun verifyCifrasoftLibs(): Boolean {
        return try {
            // Test de création d'instance
            val engine = SoundCodeUltraCode.instance(context)
            val settings = com.cifrasoft.services.SoundCodeUltraCodeSettings()
            Log.d(TAG, "✅ Cifrasoft libs disponibles")
            true
        } catch (e: ClassNotFoundException) {
            Log.e(TAG, "❌ Classes Cifrasoft manquantes: ${e.message}")
            false
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "❌ Libs natives Cifrasoft manquantes: ${e.message}")
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur Cifrasoft: ${e.message}")
            false
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Channel pour AudioQREngine (méthodes initialise, startDetection)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.minfo_sdk/audioqr")
        channel.setMethodCallHandler(this)
        
        // Channel exact du fichier de référence pour format app Minfo
        minfoChannel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        minfoChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                START_AUDIO_CAPTURE -> {
                    SoundCodeUltraCode.instance(context).stopSearch()
                    SoundCodeUltraCode.release()
                    val scucs = SoundCodeUltraCodeSettings()
                    scucs.counterLength = DEFAULT_COUNTER_LENGTH
                    scucs.counterIncrement = DEFAULT_COUNTER_INCREMENT
                    scucs.counterStartValue = DEFAULT_COUNTER_START_VALUE
                    scucs.delayAdjustment = DEFAULT_DELAY_ADJUSTMENT
                    SoundCodeUltraCode.instance(context).prepare(scucs, scuclistener, true)

                    startAudioCapture()

                    result.success(null)
                }
                STOP_AUDIO_CAPTURE -> {
                    stopAudioCapture()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialise" -> {
                if (!verifyCifrasoftLibs()) {
                    result.success(mapOf(
                        "version" to "2.3.0-no-cifrasoft", 
                        "available" to false,
                        "error" to "Cifrasoft libraries not found"
                    ))
                    return
                }
                
                try {
                    val engine = getAudioEngine()
                    val version = engine.javaClass.simpleName
                    
                    // Diagnostic complet des libs Cifrasoft
                    Log.d(TAG, "🔍 DIAGNOSTIC COMPLET CIFRASOFT:")
                    Log.d(TAG, "   - Classe moteur: ${engine.javaClass.name}")
                    Log.d(TAG, "   - Package: ${engine.javaClass.`package`?.name}")
                    
                    // Test des méthodes disponibles
                    val methods = engine.javaClass.methods
                    Log.d(TAG, "   - Méthodes disponibles: ${methods.size}")
                    methods.filter { it.name.contains("prepare") || it.name.contains("start") || it.name.contains("search") }
                        .forEach { Log.d(TAG, "     * ${it.name}(${it.parameterTypes.joinToString { p -> p.simpleName }})") }
                    
                    // Test des settings
                    val settings = com.cifrasoft.services.SoundCodeUltraCodeSettings()
                    Log.d(TAG, "   - Settings classe: ${settings.javaClass.name}")
                    
                    // Test du listener
                    Log.d(TAG, "   - Listener interface: ${scuclistener.javaClass.interfaces.joinToString { it.name }}")
                    
                    Log.d(TAG, "✅ Moteur Cifrasoft disponible: $version")
                    
                    result.success(mapOf(
                        "version" to "2.3.0-cifrasoft-$version", 
                        "available" to true,
                        "diagnostic" to "Libs OK mais détection échoue - Possible incompatibilité de version"
                    ))
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Erreur initialisation Cifrasoft: ${e.message}")
                    result.success(mapOf(
                        "version" to "2.3.0-cifrasoft-error", 
                        "available" to false,
                        "error" to e.message
                    ))
                }
            }

            "startDetection" -> {
                if (!verifyCifrasoftLibs()) {
                    result.error("LIBS_UNAVAILABLE", "Cifrasoft libraries not available", null)
                    return
                }
                
                try {
                    // Utiliser exactement le même système que startAudioCapture
                    SoundCodeUltraCode.instance(context).stopSearch()
                    SoundCodeUltraCode.release()
                    val scucs = SoundCodeUltraCodeSettings()
                    scucs.counterLength = DEFAULT_COUNTER_LENGTH
                    scucs.counterIncrement = DEFAULT_COUNTER_INCREMENT
                    scucs.counterStartValue = DEFAULT_COUNTER_START_VALUE
                    scucs.delayAdjustment = DEFAULT_DELAY_ADJUSTMENT
                    SoundCodeUltraCode.instance(context).prepare(scucs, scuclistener, true)

                    startAudioCapture()
                    
                    result.success(null)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Erreur critique: ${e.message}", e)
                    result.error("DETECTION_ERROR", e.message, null)
                }
            }
            "stopDetection" -> {
                stopAudioCapture()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopAudioCapture()
        SoundCodeUltraCode.release()
        channel.setMethodCallHandler(null)
        minfoChannel.setMethodCallHandler(null)
    }
}
