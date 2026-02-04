import Flutter
import UIKit
import AVFoundation

@objc public class MinfoSdkPlugin: NSObject, FlutterPlugin {
    private var minfoChannel: FlutterMethodChannel?
    private let TAG = "MinfoSDK-iOS"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.gzone.campaign/audioCapture", binaryMessenger: registrar.messenger())
        let instance = MinfoSdkPlugin()
        instance.minfoChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialise":
            result(["version": "2.3.0-ios", "available": true])
        case "startDetection", "startAudioCapture":
            handleStartDetection(result: result)
        case "stopDetection", "stopAudioCapture":
            handleStopDetection(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleStartDetection(result: @escaping FlutterResult) {
        let status = AVAudioSession.sharedInstance().recordPermission
        if status == .granted {
            startSCS(result: result)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.startSCS(result: result) }
                    else { result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone access denied", details: nil)) }
                }
            }
        }
    }

    private func startSCS(result: @escaping FlutterResult) {
        do {
            // 1. ACTIVATION de l'AudioSession (Critique sur iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("\(TAG): ✅ AudioSession activée")

            let wrapper = SCSManagerWrapper.shared()

            // 2. PRÉPARATION (Activation moteur) - Vérifier l'initialisation des ressources
            wrapper.prepareWithSettings()
            print("\(TAG): ✅ Moteur préparé")

            // 3. ÉCOUTEUR (Control) - On nettoie l'ancien avant d'ajouter
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("MinfoDetectionForFlutter"), object: nil)
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("MinfoDetectionForFlutter"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let data = notification.userInfo?["detectedData"] as? [Any] {
                    print("\(self?.TAG ?? "MinfoSDK-iOS"): 🎯 Signal détecté: \(data)")
                    self?.minfoChannel?.invokeMethod("onDetectedId", arguments: data)
                }
            }
            print("\(TAG): ✅ Écouteur (notifications) configuré")

            // 4. DÉMARRAGE DU DÉCODAGE
            print("\(TAG): 🚀 Démarrage du décodage...")
            wrapper.startSearching()
            print("\(TAG): ✅ Décodage en cours")
            
            result(["success": true])
        } catch {
            let errorMsg = "Erreur AudioSession: \(error.localizedDescription)"
            print("\(TAG): ❌ \(errorMsg)")
            result(FlutterError(code: "AUDIO_ERROR", message: errorMsg, details: nil))
        }
    }

    private func handleStopDetection(result: @escaping FlutterResult) {
        SCSManagerWrapper.shared().stopSearching()
        try? AVAudioSession.sharedInstance().setActive(false)
        result(["success": true])
    }
}