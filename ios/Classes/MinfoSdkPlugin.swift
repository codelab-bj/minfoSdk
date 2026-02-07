import Flutter
import UIKit

// Constantes identiques à l'app principale (SCSSettings.h)
private let SCS_AUDIO_MANAGER_NOTIFICATION = "scsAudioManagerNotification"
private let SCS_SEARCH_MANAGER_NOTIFICATION = "scsSearchManagerNotification"
private let SCS_SEARCH_MANAGER_NOTIFICATION_RESULT_KEY = "scsSearchManagerNotificationResultKey"

@objc public class MinfoSdkPlugin: NSObject, FlutterPlugin {
    static var sharedInstance: MinfoSdkPlugin?
    
    private var isDetecting = false
    private var minfoChannel: FlutterMethodChannel?

    private let TAG = "MinfoSDK-iOS"

    public static func register(with registrar: FlutterPluginRegistrar) {
        print("[MinfoSDK-iOS] ✅ EXECUTION NOTRE CODE: MinfoSdkPlugin.register() appelé")
        let channel = FlutterMethodChannel(name: "com.minfo_sdk/audioqr", binaryMessenger: registrar.messenger())
        let minfoChannel = FlutterMethodChannel(name: "com.gzone.campaign/audioCapture", binaryMessenger: registrar.messenger())

        let instance = MinfoSdkPlugin()
        MinfoSdkPlugin.sharedInstance = instance  // ← GARDER EN MÉMOIRE
        instance.minfoChannel = minfoChannel

        // Comme l'app principale : configurer SCSManager au "lancement" (enregistrement du plugin)
        SCSManagerWrapper.shared().ensureConfigured()
        // Même observers que l'app principale (SCS_AUDIO_MANAGER + SCS_SEARCH_MANAGER)
        instance.setupNotifications()

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: minfoChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[MinfoSDK-iOS] ✅ EXECUTION NOTRE CODE: handle(\(call.method))")
        switch call.method {
        case "initialise":
            handleInitialise(result: result)
        case "startDetection":
            handleStartDetection(result: result)
        case "stopDetection":
            handleStopDetection(result: result)
        case "startAudioCapture":
            handleStartAudioCapture(result: result)
        case "stopAudioCapture":
            handleStopAudioCapture(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialise(result: @escaping FlutterResult) {
        print("[\(TAG)] 🚀 Initialisation iOS avec Cifrasoft")
        result([
            "version": "2.3.0-ios-cifrasoft",
            "available": true
        ])
    }

    private func handleStartDetection(result: @escaping FlutterResult) {
        print("[\(TAG)] 🎧 Démarrage détection Cifrasoft iOS")
        isDetecting = true
        SCSManagerWrapper.shared().startSearching()
        result(nil)
    }

    private func handleStopDetection(result: @escaping FlutterResult) {
        print("[\(TAG)] ⏹️ Arrêt détection Cifrasoft iOS")
        isDetecting = false
        SCSManagerWrapper.shared().stopSearching()
        result(nil)
    }

    private func handleStartAudioCapture(result: @escaping FlutterResult) {
        print("[\(TAG)] 🎧 startAudioCapture - même logique que l'app principale")
        isDetecting = true
        SCSManagerWrapper.shared().startSearching()
        result("")
    }

    private func handleStopAudioCapture(result: @escaping FlutterResult) {
        print("[\(TAG)] ⏹️ stopAudioCapture - même logique que l'app principale")
        isDetecting = false
        SCSManagerWrapper.shared().stopSearching()
        result("")
    }

    private func setupNotifications() {
        // Exactement comme l'app principale : les 2 observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(eventsAudioManager(_:)),
            name: NSNotification.Name(rawValue: SCS_AUDIO_MANAGER_NOTIFICATION),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSearchResult(_:)),
            name: NSNotification.Name(rawValue: SCS_SEARCH_MANAGER_NOTIFICATION),
            object: nil
        )
        print("[\(TAG)] Écoute: \(SCS_AUDIO_MANAGER_NOTIFICATION) et \(SCS_SEARCH_MANAGER_NOTIFICATION)")
    }

    @objc private func eventsAudioManager(_ notification: Notification) {
        print("[\(TAG)] 📢 SCS_AUDIO_MANAGER_NOTIFICATION reçue (comme app principale)")
    }

    // Même logique que l'app principale : eventsSearchManger
    @objc private func handleSearchResult(_ notification: Notification) {
        // Log à chaque réception pour diagnostiquer
        print("[\(TAG)] 📥 Notification reçue: \(notification.name.rawValue)")
        if let userInfo = notification.userInfo {
            print("[\(TAG)] 📦 userInfo: \(userInfo)")
            let resultKey = userInfo[AnyHashable(SCS_SEARCH_MANAGER_NOTIFICATION_RESULT_KEY)]
            let offsetKey = userInfo[AnyHashable("scsSearchManagerNotificationOffsetKey")]
            print("[\(TAG)] RESULT_KEY=\(String(describing: resultKey)) OFFSET_KEY=\(String(describing: offsetKey))")
        }

        guard isDetecting else {
            print("[\(TAG)] ⚠️ isDetecting=false, ignoré")
            return
        }

        // Comme l'app principale : utiliser RESULT_KEY comme detectedAudioId
        let detectedAudioId = notification.userInfo?[AnyHashable(SCS_SEARCH_MANAGER_NOTIFICATION_RESULT_KEY)]

        let audioIdValue: Int
        if let num = detectedAudioId as? NSNumber {
            audioIdValue = num.intValue
        } else if let intVal = detectedAudioId as? Int {
            audioIdValue = intVal
        } else {
            audioIdValue = -1
        }

        // Ne pas envoyer -1 à Flutter (pas de signal valide)
        if audioIdValue < 0 {
            print("[\(TAG)] ⚠️ audioIdValue=\(audioIdValue), non envoyé")
            return
        }

        let resultWithType: [Int] = [0, audioIdValue, 0, 0]
        print("[\(TAG)] 🎯 onDetectedId -> \(resultWithType)")
        minfoChannel?.invokeMethod("onDetectedId", arguments: resultWithType)
    }
}