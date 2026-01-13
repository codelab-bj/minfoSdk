package com.minfo_sdk

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MinfoSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // CORRECTION: Utilise le nom exact défini dans ton code Dart
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.minfo.sdk/audioqr")
        channel.setMethodCallHandler(this)
    }

    // UNE SEULE fonction onMethodCall qui regroupe tous les cas
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "initialise" -> {
                result.success(mapOf("version" to "2.3.0-native", "available" to true))
            }
            "startDetection" -> {
                // C'est ici que tu appelleras plus tard ton moteur de détection réel
                val mockSignal = mapOf(
                    "signature" to "REAL_SOUND_DETECTED_123",
                    "confidence" to 0.98,
                    "signalId" to "sig_android_test"
                )
                result.success(mockSignal)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}