#!/bin/bash

# Script pour ajouter la librairie Cifrasoft au projet iOS

echo "🔧 Configuration de la librairie Cifrasoft pour iOS..."

# Copier les fichiers nécessaires
cp /Users/macbook/StudioProjects/minfo_sdk/ios/SCSTB_LibraryU.a /Users/macbook/StudioProjects/minfo_sdk/example/ios/
cp /Users/macbook/StudioProjects/minfo_sdk/ios/SCSManager.h /Users/macbook/StudioProjects/minfo_sdk/example/ios/Runner/
cp /Users/macbook/StudioProjects/minfo_sdk/ios/SCSSettings.h /Users/macbook/StudioProjects/minfo_sdk/example/ios/Runner/

echo "✅ Fichiers copiés"
echo "📝 Maintenant dans Xcode :"
echo "1. Sélectionnez Runner dans le navigateur"
echo "2. Onglet 'Build Settings'"
echo "3. Cherchez 'Other Linker Flags'"
echo "4. Ajoutez: -lSCSTB_LibraryU"
echo "5. Cherchez 'Library Search Paths'"
echo "6. Ajoutez: \$(PROJECT_DIR)"
echo "7. Compilez avec Cmd+B"

open ios/Runner.xcworkspace
