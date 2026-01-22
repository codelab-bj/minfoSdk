#!/bin/bash
# test_minfo_debug.sh - Test avec monitoring des logs

echo "🔧 Test Minfo avec monitoring des logs"
echo "======================================"

cd /Users/macbook/StudioProjects/minfo_sdk/example

# Vérifier qu'un appareil est connecté
echo "📱 Vérification des appareils connectés..."
adb devices

# Build et installation
echo "🔨 Build de l'application..."
flutter build apk --debug

echo "📲 Installation sur l'appareil..."
flutter install

# Lancement avec logs en parallèle
echo "🚀 Lancement de l'app avec monitoring des logs..."
echo "   Appuyez sur Ctrl+C pour arrêter"

# Démarrer les logs en arrière-plan
adb logcat | grep -E "(MinfoSDK|Flutter|AudioQR)" &
LOGCAT_PID=$!

# Lancer l'app
flutter run --debug

# Nettoyer à la fin
kill $LOGCAT_PID 2>/dev/null
