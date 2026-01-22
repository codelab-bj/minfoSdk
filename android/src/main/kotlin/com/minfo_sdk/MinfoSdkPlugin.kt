package com.minfo_sdk

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.os.Handler
import android.os.Looper

import com.cifrasoft.services.SoundCodeUltraCode
import com.cifrasoft.services.SoundCodeUltraCodeListener
import java.util.UUID

class MinfoSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var minfoChannel: MethodChannel
    private lateinit var context: Context

    private var isDetecting = false
    private var pendingResult: Result? = null
    private val handler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null
    
    // Thread-safe cleanup
    private fun cleanupHandler() {
        timeoutRunnable?.let { 
            handler.removeCallbacks(it)
            timeoutRunnable = null
        }
    }

    private val audioListener = object : SoundCodeUltraCodeListener {
        override fun onDetectedSCId(codes: LongArray?) {
            Log.d(TAG, "🎯 SIGNAL SOUNDCODE DÉTECTÉ ! Codes: ${codes?.contentToString()}")
            processDetection("SoundCode", codes)
        }

        override fun onDetectedUCId(codes: LongArray?) {
            Log.d(TAG, "🎯 SIGNAL ULTRACODE DÉTECTÉ ! Codes: ${codes?.contentToString()}")
            processDetection("UltraCode", codes)
        }

        override fun onAudioInitFailed() {
            Log.e(TAG, "❌ Échec d'initialisation audio")
            cancelTimeout()
            val currentResult = pendingResult
            pendingResult = null
            isDetecting = false
            handler.post {
                currentResult?.error("AUDIO_INIT_FAILED", "Microphone initialization failed", null)
            }
        }
    }

    private fun processDetection(type: String, codes: LongArray?) {
        Log.d(TAG, "🔄 Traitement détection: $type, codes: ${codes?.contentToString()}")
        
        if (codes != null && codes.isNotEmpty()) {
            Log.d(TAG, "✅ Signal valide détecté!")
            
            val audioId = codes[0].toInt()
            val soundType = if (type == "UltraCode") 1 else 0 // 0=Sons normaux, 1=Ultrasons
            val counter = 1 // Compteur de détection
            val timestamp = System.currentTimeMillis().toInt() / 1000 // Timestamp Unix
            
            // Format exact de l'app Minfo : [soundType, audioId, counter, timestamp]
            val detectedData = intArrayOf(soundType, audioId, counter, timestamp)
            
            Log.d(TAG, "📤 Format app Minfo: $detectedData")
            
            handler.post {
                // Envoyer sur le channel AudioQREngine
                channel.invokeMethod("onSignalDetected", mapOf("type" to type, "codes" to codes.joinToString("_")))
                
                // Envoyer sur le channel app Minfo
                minfoChannel.invokeMethod("onDetectedId", detectedData)
                Log.d(TAG, "🏁 Signal envoyé sur les deux channels")
            }

            if (pendingResult != null) {
                cancelTimeout()
                val resultData = HashMap<String, Any>()
                resultData["signature"] = audioId.toString()
                resultData["confidence"] = 0.98
                resultData["signalId"] = java.util.UUID.randomUUID().toString()

                val currentResult = pendingResult
                pendingResult = null
                isDetecting = false

                handler.post {
                    getAudioEngine().stopSearch()
                    currentResult?.success(resultData)
                }
            }
        } else {
            Log.w(TAG, "⚠️ Signal détecté mais codes vides ou null")
        }
    }

    companion object {
        private const val TAG = "MinfoSDK"
        private const val DETECTION_TIMEOUT_MS = 45000L // 45 secondes pour plus de temps
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
        
        // Channel pour format app Minfo (onDetectedId)
        minfoChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.gzone.campaign/audioCapture")
        
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
                    Log.d(TAG, "   - Listener interface: ${audioListener.javaClass.interfaces.joinToString { it.name }}")
                    
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
                    isDetecting = true
                    pendingResult = result

                    Log.d(TAG, "🔧 Configuration du moteur audio...")
                    
                    // Configuration exacte de l'app Minfo officielle
                    val settings = com.cifrasoft.services.SoundCodeUltraCodeSettings().apply {
                        counterLength = 1
                        counterIncrement = 1
                        delayAdjustment = 0.3f  // Plus sensible
                    }
                    
                    Log.d(TAG, "📋 Config Minfo officielle:")
                    Log.d(TAG, "   - counterLength: ${settings.counterLength}")
                    Log.d(TAG, "   - counterIncrement: ${settings.counterIncrement}")
                    Log.d(TAG, "   - delayAdjustment: ${settings.delayAdjustment}")
                    
                    val listener = object : com.cifrasoft.services.SoundCodeUltraCodeListener {
                        override fun onDetectedSCId(codes: LongArray) {
                            val intCodes = codes.map { it.toInt() }.toIntArray()
                            Log.d(TAG, "🎯 SIGNAL DÉTECTÉ ! Codes: ${intCodes.joinToString(",")}")
                            handleDetection(0, intCodes)
                        }
                        
                        override fun onDetectedUCId(codes: LongArray) {
                            val intCodes = codes.map { it.toInt() }.toIntArray()
                            Log.d(TAG, "🎯 SIGNAL UC DÉTECTÉ ! Codes: ${intCodes.joinToString(",")}")
                            handleDetection(1, intCodes)
                        }
                        
                        override fun onAudioInitFailed() {
                            Log.e(TAG, "❌ Échec initialisation audio")
                        }
                    }
                    
                    // Préparer le moteur
                    getAudioEngine().prepare(settings, listener, true)
                    Log.d(TAG, "✅ Moteur préparé avec config Minfo")
                    
                    // Démarrer l'enregistrement et la recherche
//                    getAudioEngine().startAudioRecord()
                    getAudioEngine().startSearch()
                    
                    Log.d(TAG, "🎤 Détection démarrée - Écoute en continu...")
                    
//                    // Timeout de 30 secondes
//                    timeoutRunnable = Runnable {
//                        Log.d(TAG, "⏰ Timeout - Aucun signal détecté")
//                        stopDetection()
//                        pendingResult?.success(null)
//                        pendingResult = null
//                    }
//                    handler.postDelayed(timeoutRunnable!!, 30000)
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Erreur critique: ${e.message}", e)
                    isDetecting = false
                    pendingResult = null
                    result.error("DETECTION_ERROR", e.message, null)
                }
            }
            "stopDetection" -> {
                stopDetection()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun stopDetection() {
        timeoutRunnable?.let { handler.removeCallbacks(it) }
        try {
            getAudioEngine().stopSearch()
        } catch (e: Exception) { 
            Log.w(TAG, "Error stopping audio engine: ${e.message}")
        }
        isDetecting = false
        pendingResult = null
    }

    private fun handleDetection(type: Int, codes: IntArray) {
        if (!isDetecting) return
        
        timeoutRunnable?.let { handler.removeCallbacks(it) }
        
        val audioId = codes.firstOrNull() ?: return
        val soundType = 0 // 0=Sons normaux (SoundCode)
        val counter = 1
        val timestamp = System.currentTimeMillis() / 1000
        
        // Format exact de l'app Minfo : [soundType, audioId, counter, timestamp]
        val detectedData = listOf(soundType, audioId, counter, timestamp)
        
        Log.d(TAG, "🔔 [MINFO FORMAT] Signal détecté ! Type: $soundType, ID: $audioId, Counter: $counter, Timestamp: $timestamp")
        
        handler.post {
            // Envoyer sur le channel AudioQREngine
            channel.invokeMethod("onSignalDetected", mapOf("type" to type, "codes" to codes.joinToString("_")))
            
            // Envoyer sur le channel app Minfo
            minfoChannel.invokeMethod("onDetectedId", detectedData)
            Log.d(TAG, "🏁 Signal envoyé sur les deux channels")
        }
        
        val signal = mapOf(
            "signature" to audioId.toString(),
            "confidence" to 0.95,
            "signalId" to java.util.UUID.randomUUID().toString()
        )
        
        pendingResult?.success(signal)
        stopDetection()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopDetection()
        channel.setMethodCallHandler(null)
    }

    private fun cancelTimeout() {
        timeoutRunnable?.let { handler.removeCallbacks(it) }
    }
}
