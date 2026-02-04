# 🧪 Guide de Test et Validation

## 📋 Avant le Test

Avant de tester, assurez-vous que:

1. ✅ Tous les fichiers sont en place:
```bash
./verify_implementation.sh
```

2. ✅ Les fichiers de données Cifrasoft sont placés:
```bash
ls -la ios/Resources/
# Doit contenir: PrivacyInfo.xcprivacy et vos fichiers de données
```

## 🚀 Procédure de Build et Test

### 1. Nettoyage Complet (RECOMMANDÉ)

```bash
# Arrêtez tout d'abord
# Ctrl+C dans le terminal si flutter run est actif

cd /Users/macbook/StudioProjects/minfo_sdk

# Nettoyage Flutter
flutter clean
rm -rf .dart_tool pubspec.lock
flutter pub get

# Nettoyage iOS
cd example/ios
rm -rf Pods Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework Flutter/Flutter.podspec
rm -rf build/
rm -rf Runner.xcworkspace

# Réinstallation CocoaPods
pod deintegrate 2>/dev/null || true
pod install --repo-update

cd ../..
```

### 2. Construction pour le Simulateur

```bash
# Option A: Depuis la racine du projet
cd /Users/macbook/StudioProjects/minfo_sdk/example
flutter run -v

# Option B: Depuis Xcode
open ios/Runner.xcworkspace
# Sélectionner: Product → Scheme → Runner
# Product → Run (⌘R)
```

### 3. Construction pour Appareil Réel

```bash
# Branchez votre iPhone et vérifiez sa détection
flutter devices

# Lancez sur l'appareil
cd example
flutter run -d <device_id> -v
```

## 📊 Vérifications lors du Test

### Log dans Xcode (Très Important)

En exécutant l'app, vous **DEVEZ** voir ces messages:

```
[SCSManagerWrapper] ✅ Ressources initialisées
[ResourceManager] ✅ Ressources vérifiées: /path/to/bundle/Resources
[ResourceManager] 📋 Fichiers disponibles: [...]
[SCSManagerWrapper] ✅ Moteur configuré
[MinfoSdk-iOS] ✅ AudioSession activée
[MinfoSdk-iOS] ✅ Moteur préparé
[MinfoSdk-iOS] ✅ Écouteur configuré
[MinfoSdk-iOS] 🚀 Décodage en cours...
```

### Flux de L'App

1. **Écran initial**: "Prêt pour la détection"
2. **Clic sur Démarrer**: 
   - Demande permission microphone (autoriser)
   - Affiche "Écoute en cours..."
3. **Jouer un son AudioQR**: 
   - Doit afficher: "✅ Campagne détectée"
   - Affiche le nom de la campagne

### Cas d'Erreur

#### ❌ "❌ Erreur inconnue"
**Cause**: Problème au démarrage
- Vérifier les logs Xcode
- Chercher: `[ResourceManager] ❌` ou `[SCSManagerWrapper] ❌`
- Vérifier que les fichiers de données existent

#### ❌ "Timeout"
**Cause**: L'app démarre mais ne détecte rien
- Les fichiers de données peuvent manquer
- Le moteur démarre mais est "sourd"
- Chercher dans les logs Xcode

#### ❌ "Permission microphone nécessaire"
**Cause**: Permission non donnée
- La demande de permission a été refusée
- Accepter la permission
- Réessayer

## 🧪 Cas de Test Recommandés

### Test 1: Vérification des Ressources
```dart
// Dans main.dart
import 'package:flutter/services.dart';

void testResources() async {
  const platform = MethodChannel('com.gzone.campaign/audioCapture');
  try {
    await platform.invokeMethod('startAudioCapture');
    print('✅ startAudioCapture réussit');
  } catch (e) {
    print('❌ Erreur: $e');
    // Vérifier les logs Xcode
  }
}
```

### Test 2: Vérifier les Logs
```bash
# Terminal 1: Lancer l'app
cd example
flutter run

# Terminal 2: Filtrer les logs
# Cmd+Shift+2 dans Xcode pour accéder au Debug Console
# Ou utiliser xcrun:
xcrun simctl io booted log stream --level debug | grep "MinfoSdk\|ResourceManager\|SCSManager"
```

### Test 3: Vérifier le Bundle
```bash
# Après une build iOS complète
cd example/ios
find build/Runner.app/Frameworks/minfo_sdk.framework \
  -type f | sort
# Chercher les fichiers de données

# Ou dans le simulateur
find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app \
  -type f | grep -E "Resources|CifrasoftData"
```

## 🐛 Problèmes Courants et Solutions

### Problème 1: "No such file or directory" (errno 2)

**Symptôme**: Logs affichent `fopen failed`

**Diagnostic**:
```bash
# Vérifier la structure du projet
ls -la ios/Resources/
# Doit lister vos fichiers de données

# Vérifier le Podspec
grep "resource_bundles" ios/minfo_sdk.podspec
```

**Solutions**:
1. Placer les fichiers dans `ios/Resources/`
2. Exécuter: `flutter clean && pod install`
3. Recompiler

### Problème 2: Pod Timed Out

**Cause**: CocoaPods cache l'ancienne version

**Solution**:
```bash
cd example/ios
rm -rf Pods Podfile.lock
pod repo update
pod install
```

### Problème 3: Erreur de Compilation Swift

**Symptôme**: `error: use of unresolved identifier 'ResourceManager'`

**Cause**: Le pont Objective-C n'est pas bridgé

**Solution**:
1. Vérifier que `ResourceManager.h` existe
2. Vérifier que `minfo_sdk.h` existe
3. Vérifier le bridging-header dans Xcode:
   - Target → Build Settings
   - Chercher "Bridging Header"
   - Doit être vide (auto-détection) ou pointé correctement

### Problème 4: App Démarre mais Ne Détecte Rien

**Cause**: Le moteur démarre mais les fichiers de données sont incomplets

**Diagnostic**:
```bash
# Vérifier que les fichiers ont les bonnes permissions
chmod 644 ios/Resources/*
chmod 755 ios/Resources/

# Vérifier dans les logs s'il y a des erreurs de fichier
# Chercher dans Xcode Debug Console
```

**Solution**:
1. Vérifier les fichiers de données auprès de Cifrasoft
2. S'assurer qu'ils sont complets
3. Recompiler après correction

## ✅ Checklist de Test

- [ ] Vérification implémentation: `./verify_implementation.sh` ✅
- [ ] Fichiers de données placés dans `ios/Resources/`
- [ ] `flutter clean` exécuté
- [ ] `pod install --repo-update` exécuté dans `example/ios`
- [ ] App compilee sans erreurs
- [ ] Logs Xcode montrent ✅ pour ResourceManager
- [ ] Permission microphone demandée et acceptée
- [ ] App affiche "Écoute en cours..."
- [ ] Son AudioQR joué
- [ ] Campagne détectée ✅ et affichée

## 📱 Test sur Appareil Réel (Important!)

Les fichiers de données Cifrasoft peuvent se comporter différemment entre:
- **Simulateur**: Microphone virtuel, latence variable
- **Appareil réel**: Microphone réel, conditions réelles

**Procédure**:
```bash
# 1. Connectez votre iPhone
# 2. Vérifiez sa détection
flutter devices

# 3. Lancez
flutter run -d <device_uuid>

# 4. Ouvrez Xcode pour voir les logs
open example/ios/Runner.xcworkspace

# Dans Xcode: View → Debug Area → Activate Console
```

## 🎯 Indicateurs de Succès

✅ **Succès = Ces trois choses arrivent**:

1. **Logs clairs**:
   ```
   [ResourceManager] ✅ Ressources vérifiées
   [SCSManagerWrapper] ✅ Moteur configuré
   [MinfoSdk-iOS] ✅ Décodage en cours
   ```

2. **App répond**:
   - Affiche "Écoute en cours..."
   - Permission microphone demandée
   - Pas d'erreur/crash

3. **Détection fonctionne**:
   - Son AudioQR joué
   - Campagne détectée et affichée
   - Stream Flutter reçoit les données

## 📈 Progression du Décodage

Pendant le décodage, vous verrez dans les logs:

```
2026-02-04 10:15:30.123: 🔍 Écoute en cours...
2026-02-04 10:15:35.456: 🎯 Signal détecté: [0, 12345, 1, 1707047735456]
2026-02-04 10:15:36.789: ✅ Campagne trouvée: Example Campaign
2026-02-04 10:15:37.012: 📱 Stream Flutter mis à jour
```

## 🔗 Ressources Utiles

- Xcode Debugging: Cmd + Shift + Y pour ouvrir Debug Console
- Flutter Logs: `flutter logs` dans un terminal séparé
- iOS System Logs: Console.app sur le Mac

## 💾 Sauvegarder une Build Réussie

Une fois que tout fonctionne:

```bash
# Sauvegarder la configuration CocoaPods
cp example/ios/Podfile example/ios/Podfile.backup
cp example/ios/Podfile.lock example/ios/Podfile.lock.backup

# Ou créer un snapshot
git add -A && git commit -m "✅ Décoding fix working"
```

## 🚨 Urgent - Si Ça Ne Marche Pas

1. Exécutez le diagnostic:
   ```bash
   ./diagnose_resources.sh
   ```

2. Vérifiez les logs Xcode pour:
   - `[ResourceManager]`
   - `[SCSManagerWrapper]`
   - `[MinfoSdk-iOS]`

3. Cherchez les messages d'erreur spécifiques

4. Vérifiez que les fichiers de données Cifrasoft:
   - Existent
   - Ont les bonnes permissions (644)
   - Sont dans `ios/Resources/`
   - Sont embarqués dans le Podspec

5. Contactez le support Cifrasoft pour les fichiers manquants
