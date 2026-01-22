#!/bin/bash
# test_minfo_audio.sh - Script de test complet

echo "🔧 Test complet du SDK Minfo Audio"
echo "=================================="

cd /Users/macbook/StudioProjects/minfo_sdk/example

echo "1. Nettoyage du projet..."
flutter clean
flutter pub get

echo "2. Vérification des permissions Android..."
grep -n "RECORD_AUDIO" android/app/src/main/AndroidManifest.xml || echo "❌ Permission RECORD_AUDIO manquante!"

echo "3. Vérification des bibliothèques natives..."
ls -la ../android/libs/

echo "4. Build Android en mode debug..."
flutter build apk --debug

echo "5. Installation sur l'appareil..."
flutter install

echo "6. Lancement avec logs détaillés..."
flutter run --verbose

echo "✅ Test terminé. Vérifiez les logs pour diagnostiquer."
