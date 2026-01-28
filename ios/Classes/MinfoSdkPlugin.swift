import Flutter
import UIKit

@objc public class MinfoSdkPlugin: NSObject, FlutterPlugin {
    private var isDetecting = false
    private var pendingResult: FlutterResult?
    private var minfoChannel: FlutterMethodChannel?
    
    private let TAG = "MinfoSDK-iOS"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.minfo_sdk/audioqr", binaryMessenger: registrar.messenger())
        let minfoChannel = FlutterMethodChannel(name: "com.gzone.campaign/audioCapture", binaryMessenger: registrar.messenger())
        
        let instance = MinfoSdkPlugin()
        instance.minfoChannel = minfoChannel
        
        // Setup Cifrasoft notifications
        instance.setupNotifications()
        
        // Enregistrer sur les deux channels
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: minfoChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
        result(["success": true])
    }
    
    private func handleStopDetection(result: @escaping FlutterResult) {
        print("[\(TAG)] ⏹️ Arrêt détection Cifrasoft iOS")
        isDetecting = false
        SCSManagerWrapper.shared().stopSearching()
        result(["success": true])
    }
    
    private func handleStartAudioCapture(result: @escaping FlutterResult) {
        print("[\(TAG)] 🎧 Capture audio Cifrasoft iOS")
        isDetecting = true
        SCSManagerWrapper.shared().startSearching()
        result(["success": true])
    }
    
    private func handleStopAudioCapture(result: @escaping FlutterResult) {
        print("[\(TAG)] ⏹️ Arrêt capture audio Cifrasoft iOS")
        isDetecting = false
        SCSManagerWrapper.shared().stopSearching()
        result(["success": true])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSearchResult(_:)),
            name: NSNotification.Name("scsSearchManagerNotification"),
            object: nil
        )
    }
    
    @objc private func handleSearchResult(_ notification: Notification) {
        guard isDetecting else { return }
        
        if let userInfo = notification.userInfo,
           let result = userInfo["scsSearchManagerNotificationResultKey"] as? NSNumber,
           result.intValue == 1 { // SCSSearchManagerResultFound
            
            print("[\(TAG)] 🎯 Détection Cifrasoft iOS réussie")
            
            // Extraire les données de détection
            let band = userInfo["scsSearchManagerNotificationBandKey"] as? NSNumber ?? 0
            let offset = userInfo["scsSearchManagerNotificationOffsetKey"] as? NSNumber ?? 0
            
            // Format similaire à Android: [type, id, counter, timestamp]
            let detectedData = [
                band.intValue, // Type de bande (0 ou 1)
                12345, // ID détecté (à extraire des vraies données)
                1, // Counter
                Int(Date().timeIntervalSince1970) // Timestamp
            ]
            
            minfoChannel?.invokeMethod("onDetectedId", arguments: detectedData)
        }
    }
}
