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
            Log.i(TAG, "🎯 [NATIF] ================================= onDetectedSCId RECU")
            Log.i(TAG, "🎯 [NATIF] Raw result: ${result.contentToString()}")
            Log.i(TAG, "🎯 [NATIF] detectedId id: " + java.lang.Long.toString(result[1]) + " / counter: " + result[2] + " / timestamp: " + "[" + java.lang.Float.toString((result[3] / 100).toFloat() / 10) + "] sec.")

            // Créer un nouveau tableau avec l'identifiant de type pour les sons normaux
            val resultWithType = longArrayOf(0L, result[1], result[2], result[3]) // 0 = Sons normaux
            Log.i(TAG, "📤 [NATIF] Envoi onDetectedId vers Flutter: ${resultWithType.contentToString()}")

            minfoChannel.invokeMethod(ON_DETECTED_ID, resultWithType)
            Log.i(TAG, "✅ [NATIF] onDetectedId envoyé avec succès (SoundCode)")
        }

        override fun onDetectedUCId(result: LongArray) {
            Log.i(TAG, "🎯 [NATIF] ================================= onDetectedUCId RECU")
            Log.i(TAG, "🎯 [NATIF] Raw result: ${result.contentToString()}")
            Log.i(TAG, "🎯 [NATIF] detectedId id: " + java.lang.Long.toString(result[1]) + " / counter: " + result[2] + " / timestamp: " + "[" + java.lang.Float.toString((result[3] / 100).toFloat() / 10) + "] sec.")

            // Créer un nouveau tableau avec l'identifiant de type pour les ultrasons
            val resultWithType = longArrayOf(1L, result[1], result[2], result[3]) // 1 = Ultrasons
            Log.i(TAG, "📤 [NATIF] Envoi onDetectedId vers Flutter: ${resultWithType.contentToString()}")

            minfoChannel.invokeMethod(ON_DETECTED_ID, resultWithType)
            Log.i(TAG, "✅ [NATIF] onDetectedId envoyé avec succès (UltraCode)")
        }

        override fun onAudioInitFailed() {
            Log.e(TAG, "❌ [NATIF] AUDIO SEARCH SERVICE_UNAVAILABLE!")
        }
    }

    // Méthodes exactes du fichier de référence
    fun startAudioCapture() {
        Log.i(TAG, "🚀 [NATIF] Démarrage startAudioCapture()...")
        try {
            Log.i(TAG, "🎤 [NATIF] Appel startSearch()...")
            SoundCodeUltraCode.instance(context).startSearch()
            Log.i(TAG, "✅ [NATIF] startSearch() appelé avec succès")
            Log.i(TAG, "✅ [NATIF] start recording ...")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [NATIF] Erreur dans startAudioCapture(): ${e.message}", e)
            throw e
        }
    }

    fun stopAudioCapture() {
        Log.i(TAG, "⏹️ [NATIF] Arrêt stopAudioCapture()...")
        try {
            Log.i(TAG, "🛑 [NATIF] Appel stopSearch()...")
            SoundCodeUltraCode.instance(context).stopSearch()
            Log.i(TAG, "✅ [NATIF] stopSearch() appelé avec succès")
            Log.i(TAG, "✅ [NATIF] stopped recording")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [NATIF] Erreur dans stopAudioCapture(): ${e.message}", e)
        }
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
            Log.i(TAG, "📥 [NATIF] Méthode reçue depuis Flutter: ${call.method}")
            when (call.method) {
                START_AUDIO_CAPTURE -> {
                    Log.i(TAG, "🚀 [NATIF] START_AUDIO_CAPTURE - Début")
                    try {
                        Log.i(TAG, "🔄 [NATIF] Arrêt et libération du moteur précédent...")
                        SoundCodeUltraCode.instance(context).stopSearch()
                        SoundCodeUltraCode.release()
                        
                        Log.i(TAG, "⚙️ [NATIF] Configuration des settings...")
                        val scucs = SoundCodeUltraCodeSettings()
                        scucs.counterLength = DEFAULT_COUNTER_LENGTH
                        scucs.counterIncrement = DEFAULT_COUNTER_INCREMENT
                        scucs.counterStartValue = DEFAULT_COUNTER_START_VALUE
                        scucs.delayAdjustment = DEFAULT_DELAY_ADJUSTMENT
                        Log.i(TAG, "⚙️ [NATIF] Settings: counterLength=${scucs.counterLength}, counterIncrement=${scucs.counterIncrement}, counterStartValue=${scucs.counterStartValue}, delayAdjustment=${scucs.delayAdjustment}")
                        
                        Log.i(TAG, "🔧 [NATIF] Préparation du moteur avec listener...")
                        SoundCodeUltraCode.instance(context).prepare(scucs, scuclistener, true)
                        Log.i(TAG, "✅ [NATIF] Moteur préparé")

                        startAudioCapture()

                        Log.i(TAG, "✅ [NATIF] START_AUDIO_CAPTURE - Succès")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ [NATIF] Erreur dans START_AUDIO_CAPTURE: ${e.message}", e)
                        result.error("START_ERROR", e.message, null)
                    }
                }
                STOP_AUDIO_CAPTURE -> {
                    Log.i(TAG, "⏹️ [NATIF] STOP_AUDIO_CAPTURE - Début")
                    stopAudioCapture()
                    Log.i(TAG, "✅ [NATIF] STOP_AUDIO_CAPTURE - Succès")
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "⚠️ [NATIF] Méthode non implémentée: ${call.method}")
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
                Log.i(TAG, "📥 [NATIF] startDetection reçu depuis Flutter")
                if (!verifyCifrasoftLibs()) {
                    Log.e(TAG, "❌ [NATIF] Libs Cifrasoft non disponibles")
                    result.error("LIBS_UNAVAILABLE", "Cifrasoft libraries not available", null)
                    return
                }
                
                try {
                    Log.i(TAG, "🔄 [NATIF] Utilisation du même système que startAudioCapture")
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
                    
                    Log.i(TAG, "✅ [NATIF] startDetection terminé avec succès")
                    result.success(null)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ [NATIF] Erreur critique dans startDetection: ${e.message}", e)
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
