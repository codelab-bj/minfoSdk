# Documentation Minfo SDK v2.3.0


## 1. Contenu du Package
Le package contient tout ce qu'il faut pour ajouter la fonctionnalité AudioQR Minfo à votre app :

| Dossier | Contenu |
|---------|---------|
| `android/` | SDK Kotlin complet pour Android avec librairies Cifrasoft |
| `ios/` | SDK Swift complet pour iPhone/iPad avec frameworks natifs |
| `lib/` | SDK Dart pour Flutter (cœur du système) |
| `example/` | Application de démonstration complète |
| `test/` | Tests automatiques du SDK |

## 2. Quel Dossier Utiliser ?
*Le SDK est spécialement conçu pour Flutter :**

| l' App Utilise  | Utilisez Ces Dossiers |
|----------------|----------------------|
| Flutter (Dart) | `lib/` + `android/` + `ios/` |
| Test/Démo      | `example/` |

## 3. Ce Que Fait Réellement le SDK
Le SDK gère tout le processus de "connexion" AudioQR :

1. **L'utilisateur** appuie sur "DÉTECTER LE SON"
2. **Le SDK** active le micro et écoute un signal AudioQR (sons **audibles** dans TV/radio/magasin)
3. **Le moteur Cifrasoft** décode le signal en temps réel
4. **Le SDK** envoie la signature aux serveurs Minfo
5. **Le serveur** répond avec le contenu de la campagne (page web)
6. **Le SDK** ouvre le contenu dans une WebView intégrée

**Important :** Les signaux AudioQR sont **audibles** (séquences de bips), pas des ultrasons. Aucun audio n'est enregistré.

## 4. Les Librairies Natives Intégrées
**Le SDK inclut déjà les vrais moteurs de production :**

| Plateforme | Fichiers Natifs | Rôle |
|------------|-----------------|------|
| Android | `soundCode2UltraCodeLib-release.aar` (307KB) | Moteur de détection Cifrasoft |
| Android | `audioRecordLib-release.aar` (13KB) | Gestion du microphone |
| Android | Fichiers `.so` (toutes architectures) | Librairies C++ compilées |
| iOS | `SCSTB_LibraryU.a` (1.14MB) | Moteur de détection Cifrasoft |
| iOS | `SCSManager.h` + `SCSSettings.h` | Headers de configuration |

**Pas de stub à remplacer** - tout est prêt pour la production !

## 5. Implémentation Étape par Étape

### Flutter (Votre Plateforme)
1. **Ajoutez** le SDK comme dépendance locale dans `pubspec.yaml`
2. **Permissions micro** - configurées dans votre `AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
   ```
3. **Installez** les dépendances : `flutter pub get`
4. **Initialisez** dans `main.dart` :
   ```dart
   // Option 1: Avec JWT/API Key
   await MinfoSdk.instance.init(
     apiKey: "VOTRE_JWT_TOKEN",
   );
   
   // Option 2: Avec clés publique/privée
   await MinfoSdk.instance.init(
     publicKey: "VOTRE_CLE_PUBLIQUE",
     privateKey: "VOTRE_CLE_PRIVEE",
   );
   ```
5. **Lancez** la détection :
   ```dart
   final result = await MinfoSdk.instance.audioEngine.startDetection();
   ```

## 6. Fichiers Clés et Leur Rôle

### Cœur du SDK (`lib/`)
| Fichier | Rôle |
|---------|------|
| `minfo_sdk.dart` | Point d'entrée - exporte toutes les classes |
| `src/minfo_sdk.dart` | Classe principale - coordonne tout |
| `src/audio_qr_engine.dart` | **Moteur de détection** - communication native |
| `src/api_client.dart` | Client HTTP - communication serveurs Minfo |
| `src/models.dart` | Structures de données (400+ lignes) |
| `src/config_manager.dart` | Gestion configuration et cache |
| `src/secure_storage.dart` | Stockage sécurisé des clés API |
| `minfo_web_view.dart` | WebView intégrée pour afficher les campagnes |

### Code Natif Android (`android/`)
| Fichier | Rôle |
|---------|------|
| `src/main/kotlin/.../MinfoSdkPlugin.kt` | **Cerveau Android** - gère la détection |
| `libs/soundCode2UltraCodeLib-release.aar` | Moteur Cifrasoft principal |
| `libs/audioRecordLib-release.aar` | Gestion microphone |
| `extracted_libs/jni/` | Librairies C++ pour tous processeurs |

### Code Natif iOS (`ios/`)
| Fichier | Rôle |
|---------|------|
| `Classes/MinfoSdkPlugin.swift` | **Cerveau iOS** - gère la détection |
| `Frameworks/SCSTB_LibraryU.a` | Moteur Cifrasoft principal |
| `Frameworks/SCSManager.h` | Interface du moteur |


## 7. Architecture de Communication

### Flux de Détection
```
Flutter (Dart)
    ↓ MethodChannel
Kotlin/Swift (Natif)
    ↓ JNI/C++
Librairies Cifrasoft
    ↓ Callback
Kotlin/Swift
    ↓ MethodChannel
Flutter → API Minfo
```

### Canaux de Communication
| Canal | Rôle |
|-------|------|
| `com.minfo.sdk/audioqr` | Communication Flutter ↔ Natif |
| `onSignalDetected` | Notification de détection en temps réel |
| HTTP Client | Communication avec API Minfo |


## 8. Checklist Mise en Production

### Technique  
- ✅ Librairies natives Cifrasoft intégrées
- ✅ Permissions microphone configurées
- ✅ Communication native fonctionnelle
- ✅ Gestion du cycle de vie
- ✅ Interface utilisateur complète
- ✅ Système de diagnostic intégré



### Architecture Mature
Le SDK est **techniquement complet** et prêt pour la production. 


**Document version:** 2.3.0 | **Généré:** Janvier 2026  
