# 🔧 Guide d'Ajout des Fichiers de Données Cifrasoft

## 🎯 Situation Actuelle

Diagnostic ✅:
- ✅ ResourceManager implémenté
- ✅ SCSManagerWrapper mis à jour  
- ✅ Podspec mis à jour
- ❌ **Fichiers de données Cifrasoft manquants**

## 📍 Localiser les Fichiers Manquants

Le moteur Cifrasoft (SCSTB_Library) a besoin de fichiers de référence pour fonctionner. Ces fichiers contiennent les données d'analyse audio pour la détection.

### Options pour trouver ces fichiers:

#### 1. **Dans la Documentation Cifrasoft**
- Vérifiez si Cifrasoft a fourni un dossier `data/`, `resources/` ou `assets/`
- Cherchez les fichiers avec extensions: `.dat`, `.bin`, `.idx`, `.tbl`, `.db`

#### 2. **Dans la Version Android du SDK**
Comparez avec votre implémentation Android pour voir où elle place ces fichiers:
```bash
# Chercher dans votre projet Android
find . -path "*/main/assets/*" -type f
find . -path "*/res/raw/*" -type f
```

#### 3. **Auprès du Fournisseur Cifrasoft**
- Demandez les fichiers de données pour iOS
- Il y a généralement un package séparé pour les données

## 🏗️ Structure Attendue

Une fois les fichiers obtenus, voici la structure recommandée:

```
ios/
├── Resources/
│   ├── PrivacyInfo.xcprivacy
│   └── CifrasoftData/               ← NOUVEAU
│       ├── low_frequency.dat        ← Données de fréquence basse
│       ├── high_frequency.dat       ← Données de fréquence haute
│       ├── reference_tables.idx     ← Tables d'indexation
│       └── ...autres fichiers...
└── Classes/
    ├── ResourceManager.h
    ├── ResourceManager.m
    └── ...
```

## 📋 Étapes d'Intégration

### 1. **Préparez les fichiers localement**

Placez-les dans votre dossier `ios/Resources/`:

```bash
# Créer le sous-dossier s'il n'existe pas
mkdir -p /Users/macbook/StudioProjects/minfo_sdk/ios/Resources/CifrasoftData

# Copier vos fichiers
cp /chemin/vers/vos/donnees/* \
   /Users/macbook/StudioProjects/minfo_sdk/ios/Resources/CifrasoftData/
```

### 2. **Mettre à jour le Podspec**

Le podspec est déjà configuré pour inclure tous les fichiers dans `Resources/**/*`:

```ruby
s.resource_bundles = {
  'minfo_sdk' => [
    'Resources/**/*',       # ← Ceci inclut CifrasoftData automatiquement
    'Assets/**/*',
    'Frameworks/SCSTB.framework/**/*'
  ],
  'minfo_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']
}
```

**Si vous devez être plus spécifique:**

```ruby
s.resources = 'Resources/CifrasoftData/**/*'
```

### 3. **Nettoyer et Reconstruire**

```bash
cd /Users/macbook/StudioProjects/minfo_sdk

# Nettoyer Flutter
flutter clean
flutter pub get

# Nettoyer CocoaPods
cd example/ios
rm -rf Pods Podfile.lock .symlinks/ Flutter/Flutter.framework Flutter/Flutter.podspec
pod install --repo-update

cd ../..
flutter run
```

### 4. **Vérifier l'Embarquement**

Après la compilation, vérifiez que les fichiers sont dans l'app:

```bash
# Dans Xcode, Build Settings → Build Phases → Copy Bundle Resources
# Vous devriez voir CifrasoftData listés

# Ou en ligne de commande (après compilation):
find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos/minfo_sdk.framework \
  -path "*CifrasoftData*" 2>/dev/null
```

## 🔍 Diagnostic Avancé

Si vous n'êtes pas sûr des fichiers nécessaires:

### Inspectez le Framework Android

```bash
# Si vous avez une version Android fonctionnelle
unzip audioRecordLib-release.aar -d /tmp/audioRecord
unzip soundCode2UltraCodeLib-release.aar -d /tmp/soundCode

find /tmp/audioRecord /tmp/soundCode -type f | grep -E "\.dat|\.bin|\.idx|\.tbl|assets"
```

### Utilisez `strings` sur la Lib Android

```bash
# Si la lib Android existe
strings android/libs/soundCode2UltraCodeLib-release.aar | grep -E "\.dat|\.bin" | head -20
```

## 📝 Code de Vérification (Test)

Vous pouvez ajouter cette vérification en Dart pour tester:

```dart
// test/diagnose_resources.dart
import 'package:flutter/services.dart';

Future<void> testResources() async {
  const platform = MethodChannel('com.gzone.campaign/audioCapture');
  
  try {
    final result = await platform.invokeMethod('getResourceStatus');
    print('Ressources: $result');
  } catch (e) {
    print('Erreur: $e');
  }
}
```

Et implémenter en Objective-C:

```objc
// Dans SCSManagerWrapper.m
- (void)handleMethodCall:(FlutterMethodCall*)call
                  result:(FlutterResult)result {
  if ([@"getResourceStatus" isEqualToString:call.method]) {
    NSError *error = nil;
    BOOL available = [ResourceManager ensureResourcesAvailable:&error];
    result(@{@"available": @(available),
             @"path": [ResourceManager bundleResourcePath]});
  }
}
```

## ⚠️ Problèmes Courants

### **Problème: "Ressources non trouvées"**

**Cause**: Les fichiers ne sont pas dans le bon dossier

**Solution**:
```bash
# Vérifier l'existence
ls -la /Users/macbook/StudioProjects/minfo_sdk/ios/Resources/

# Les fichiers doivent s'y trouver
# Sinon: cp vos_fichiers ios/Resources/
```

### **Problème: "Podspec ne charge pas les ressources"**

**Cause**: Cache de CocoaPods

**Solution**:
```bash
cd example/ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### **Problème: "Fichiers présents mais non trouvés à l'exécution"**

**Cause**: Chemin incorrect à l'exécution

**Solution**: Vérifiez le log:
```
[ResourceManager] 📁 Chemin des ressources: /path/to/bundle
[ResourceManager] 📋 Fichiers disponibles: [...]
```

S'il est vide, le bundle n'a pas reçu les fichiers → relancer `pod install`.

## ✅ Checklist Finale

- [ ] Fichiers Cifrasoft localisés
- [ ] Fichiers copiés dans `ios/Resources/`
- [ ] Podspec mis à jour (déjà fait ✅)
- [ ] `flutter clean` exécuté
- [ ] `pod install --repo-update` exécuté dans `example/ios`
- [ ] App recompilée
- [ ] Logs `[ResourceManager]` visibles dans Xcode
- [ ] Test sur appareil réel

## 📞 Support Adicional

Si les fichiers ne sont pas disponibles:

1. **Contactez Cifrasoft** pour les fichiers de données iOS
2. **Vérifiez votre contrat** avec Cifrasoft pour la distribution
3. **En dernier recours**: Extrayez depuis la version Android
   - Décompressez le `.aar`
   - Cherchez les dossiers `assets/` ou `res/`
   - Convertissez si nécessaire pour iOS

## 🎯 Résultat Attendu Après Implémentation

Une fois tout en place, l'ordre des étapes sera:

```
User clicks "Listen"
        ↓
requestMicrophonePermission() ✅
        ↓
startAudioCapture() → Swift → Objective-C
        ↓
SCSManagerWrapper.init()
        ↓
ResourceManager.initializeCifrasoftPaths()
        ✅ Bundle located
        ✅ Files verified
        ✅ Paths configured
        ↓
prepareWithSettings() ✅ (Activation)
        ↓
startSearching() ✅ (Decoding with data files)
        ↓
Notifications received → Flutter stream
        ↓
campaignData displayed ✅
```
