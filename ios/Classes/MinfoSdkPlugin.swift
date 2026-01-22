import Flutter
import UIKit
import AVFoundation

public class MinfoSdkPlugin: NSObject, FlutterPlugin {
    private var audioEngine: SCSManager?
    private var isDetecting = false
    private var pendingResult: FlutterResult?
    private var timeoutTimer: Timer?
    private var minfoChannel: FlutterMethodChannel?
    
    private let TAG = "MinfoSDK-iOS"
    private let DETECTION_TIMEOUT: TimeInterval = 45.0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Channel pour AudioQREngine
        let channel = FlutterMethodChannel(name: "com.minfo_sdk/audioqr", binaryMessenger: registrar.messenger())
        
        // Channel pour format app Minfo  
        let minfoChannel = FlutterMethodChannel(name: "com.gzone.campaign/audioCapture", binaryMessenger: registrar.messenger())
        
        let instance = MinfoSdkPlugin()
        instance.minfoChannel = minfoChannel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public override init() {
        super.init()
        setupNotifications()
    }
    
    private func verifyCifrasoftFramework() -> (available: Bool, version: String?, error: String?) {
        do {
            // Vérifier que SCSManager est disponible
            guard let manager = SCSManager.shared() else {
                return (false, nil, "SCSManager.shared() returned nil")
            }
            
            // Tester les méthodes essentielles
            let version = manager.getVersionName() ?? "unknown"
            
            // Vérifier que les constantes sont disponibles
            let _ = SCS_SEARCH_MANAGER_NOTIFICATION
            let _ = SCS_AUDIO_MANAGER_NOTIFICATION
            
            print("[\(TAG)] ✅ Framework Cifrasoft disponible - Version: \(version)")
            return (true, version, nil)
            
        } catch {
            print("[\(TAG)] ❌ Framework Cifrasoft non disponible: \(error)")
            return (false, nil, error.localizedDescription)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Écouter les notifications de recherche
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSearchNotification(_:)),
            name: NSNotification.Name(rawValue: SCS_SEARCH_MANAGER_NOTIFICATION),
            object: nil
        )
        
        // Écouter les notifications audio
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioNotification(_:)),
            name: NSNotification.Name(rawValue: SCS_AUDIO_MANAGER_NOTIFICATION),
            object: nil
        )
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[\(TAG)] 📞 Appel méthode: \(call.method)")
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "initialise":
            handleInitialise(result: result)
            
        case "startDetection":
            handleStartDetection(result: result)
            
        case "stopDetection":
            handleStopDetection(result: result)
            
        case "discardQueuedSignals":
            pendingResult = nil
            result(nil)
            
        default:
            print("[\(TAG)] ❓ Méthode inconnue: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Initialisation
    
    private func handleInitialise(result: @escaping FlutterResult) {
        print("[\(TAG)] 🚀 Initialisation du moteur AudioQR...")
        
        let verification = verifyCifrasoftFramework()
        
        if !verification.available {
            print("[\(TAG)] ❌ Framework non disponible: \(verification.error ?? "unknown")")
            result([
                "version": "2.3.0-no-cifrasoft-ios",
                "available": false,
                "error": verification.error ?? "Cifrasoft framework not available"
            ])
            return
        }
        
        do {
            audioEngine = SCSManager.shared()
            guard let engine = audioEngine else {
                throw NSError(domain: "MinfoSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create SCSManager"])
            }
            
            let version = verification.version ?? "unknown"
            print("[\(TAG)] ✅ Moteur AudioQR créé avec succès - Version: \(version)")
            
            result([
                "version": "2.3.0-cifrasoft-ios-\(version)",
                "available": true
            ])
        } catch {
            print("[\(TAG)] ❌ Erreur initialisation: \(error.localizedDescription)")
            result([
                "version": "2.3.0-cifrasoft-error-ios",
                "available": false,
                "error": error.localizedDescription
            ])
        }
    }
    
    // MARK: - Détection
    
    private func handleStartDetection(result: @escaping FlutterResult) {
        print("[\(TAG)] 👂 Démarrage détection...")
        
        let verification = verifyCifrasoftFramework()
        if !verification.available {
            result(FlutterError(code: "FRAMEWORK_UNAVAILABLE",
                              message: "Cifrasoft framework not available: \(verification.error ?? "unknown")",
                              details: nil))
            return
        }
        
        guard let engine = audioEngine else {
            print("[\(TAG)] ❌ Moteur non initialisé")
            result(FlutterError(code: "NOT_INITIALIZED",
                              message: "AudioQR engine not initialized",
                              details: nil))
            return
        }
        
        if isDetecting {
            print("[\(TAG)] ⚠️ Détection déjà en cours - Arrêt forcé")
            stopDetectionInternal()
        }
        
        // Vérifier permission micro
        checkMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            
            if !granted {
                print("[\(self.TAG)] ❌ Permission micro refusée")
                result(FlutterError(code: "PERMISSION_DENIED",
                                  message: "Microphone permission denied",
                                  details: nil))
                return
            }
            
            self.isDetecting = true
            self.pendingResult = result
            
            print("[\(self.TAG)] 🎯 Configuration des paramètres...")
            
            // Configuration optimisée pour détection
            var settingsLO = scsSettingsStruct(
                userSearchInterval: 50, // Plus fréquent
                userLengthCounter: Int32(2), // Plus long
                userPeriodIncrementCounter: Int32(1),
                userOffsetCounterAdjustment: Int32(0),
                userOffsetDelayAdjustment: 0.0 // Pas d'ajustement
            )
            
            var settingsHI = scsSettingsStruct(
                userSearchInterval: 50, // Plus fréquent
                userLengthCounter: Int32(2), // Plus long
                userPeriodIncrementCounter: Int32(1),
                userOffsetCounterAdjustment: Int32(0),
                userOffsetDelayAdjustment: 0.0 // Pas d'ajustement
            )
            
            engine.settingsSearching(&settingsLO, &settingsHI)
            engine.startSearching()
            
            print("[\(self.TAG)] 🎧 Détection AudioQR réelle démarrée !")
            
            // Démarrer le timeout
            self.startTimeout()
        }
    }
    
    private func handleStopDetection(result: @escaping FlutterResult) {
        print("[\(TAG)] 🛑 Arrêt détection...")
        stopDetectionInternal()
        result(nil)
    }
    
    // MARK: - Notifications
    
    @objc private func handleSearchNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // Vérifier changement d'état
        if let stateChange = userInfo[SCS_SEARCH_MANAGER_NOTIFICATION_STATE_CHANGE_KEY] as? NSNumber {
            let state = SCSSearchManagerState(rawValue: stateChange.uintValue) ?? SCSSearchManagerState(rawValue: 0)
            print("[\(TAG)] 🔄 État recherche: \(state.rawValue)")
        }
        
        // Vérifier résultat
        if let resultValue = userInfo[SCS_SEARCH_MANAGER_NOTIFICATION_RESULT_KEY] as? NSNumber {
            let searchResult = SCSSearchManagerResult(rawValue: resultValue.int64Value) ?? SCSSearchManagerResult(rawValue: 0)
            
            if searchResult.rawValue == 1 { // SCSSearchManagerResultFound
                // Signal détecté !
                if let offset = userInfo[SCS_SEARCH_MANAGER_NOTIFICATION_OFFSET_KEY] as? NSNumber,
                   let band = userInfo[SCS_SEARCH_MANAGER_NOTIFICATION_BAND_KEY] as? String {
                    
                    print("[\(TAG)] 🔊 Signal détecté ! Band: \(band), Offset: \(offset)")
                    
                    cancelTimeout()
                    
                    let audioId = offset.intValue
                    let soundType = 0 // 0=Sons normaux (SoundCode)
                    let counter = 1
                    let timestamp = Int(Date().timeIntervalSince1970)
                    
                    // Format exact de l'app Minfo : [soundType, audioId, counter, timestamp]
                    let detectedData = [soundType, audioId, counter, timestamp]
                    
                    print("[\(TAG)] 📤 Format app Minfo: \(detectedData)")
                    
                    // Envoyer sur le channel app Minfo
                    minfoChannel?.invokeMethod("onDetectedId", detectedData)
                    
                    let signal: [String: Any] = [
                        "signature": "\(audioId)",
                        "confidence": 0.95,
                        "signalId": UUID().uuidString
                    ]
                    
                    pendingResult?(signal)
                    pendingResult = nil
                    isDetecting = false
                    audioEngine?.stopSearching()
                }
            }
        }
        
        // Vérifier erreur
        if let error = userInfo[SCS_SEARCH_MANAGER_NOTIFICATION_ERROR_KEY] as? NSNumber {
            print("[\(TAG)] ❌ Erreur recherche: \(error)")
            cancelTimeout()
            pendingResult?(FlutterError(code: "SEARCH_ERROR",
                                       message: "Search error: \(error)",
                                       details: nil))
            pendingResult = nil
            isDetecting = false
        }
    }
    
    @objc private func handleAudioNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let stateChange = userInfo[SCS_AUDIO_MANAGER_NOTIFICATION_STATE_CHANGE_KEY] as? NSNumber {
            let state = SCSAudioManagerState(rawValue: stateChange.uintValue) ?? SCSAudioManagerState(rawValue: 0)
            print("[\(TAG)] 🎤 État audio: \(state.rawValue)")
            
            if state.rawValue == 5 { // SCSAudioManagerStatePermDenied
                print("[\(TAG)] ❌ Permission micro refusée par le système")
                cancelTimeout()
                pendingResult?(FlutterError(code: "PERMISSION_DENIED",
                                           message: "Microphone permission denied",
                                           details: nil))
                pendingResult = nil
                isDetecting = false
            } else if state.rawValue == 4 { // SCSAudioManagerStateError
                print("[\(TAG)] ❌ Erreur audio")
                cancelTimeout()
                pendingResult?(FlutterError(code: "AUDIO_ERROR",
                                           message: "Audio initialization failed",
                                           details: nil))
                pendingResult = nil
                isDetecting = false
            }
        }
    }
    
    // MARK: - Timeout
    
    private func startTimeout() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: DETECTION_TIMEOUT, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
    }
    
    private func cancelTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    @objc private func handleTimeout() {
        print("[\(TAG)] ⏱️ Timeout détection (\(Int(DETECTION_TIMEOUT))s)")
        
        if isDetecting && pendingResult != nil {
            pendingResult?(FlutterError(code: "TIMEOUT",
                                       message: "No AudioQR signal detected within timeout period",
                                       details: nil))
            pendingResult = nil
            isDetecting = false
            audioEngine?.stopSearching()
        }
    }
    
    private func stopDetectionInternal() {
        cancelTimeout()
        audioEngine?.stopSearching()
        isDetecting = false
        pendingResult = nil
        print("[\(TAG)] ✅ Détection arrêtée")
    }
    
    // MARK: - Permissions
    
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}
