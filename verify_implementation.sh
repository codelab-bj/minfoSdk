#!/bin/bash

# Quick Verification Script for Minfo SDK Fix
# Vérifie rapidement que tous les fichiers et modifications sont en place

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ERRORS=0
WARNINGS=0

echo "✅ Vérification rapide de l'implémentation"
echo "========================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour vérifier un fichier
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${RED}❌${NC} $1"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Fonction pour vérifier un répertoire
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${RED}❌${NC} $1"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

# Fonction pour vérifier si un mot-clé existe dans un fichier
check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $1 (contient: $2)"
        return 0
    else
        echo -e "${RED}❌${NC} $1 (manque: $2)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

echo "📋 Fichiers Requis:"
echo "==================="

# Vérifier ResourceManager
check_file "$PROJECT_ROOT/ios/Classes/ResourceManager.h"
check_file "$PROJECT_ROOT/ios/Classes/ResourceManager.m"

# Vérifier les fichiers modifiés
check_file "$PROJECT_ROOT/ios/Classes/SCSManagerWrapper.m"
check_file "$PROJECT_ROOT/ios/Classes/MinfoSdkPlugin.swift"
check_file "$PROJECT_ROOT/ios/minfo_sdk.podspec"

echo ""
echo "📋 Répertoires Requis:"
echo "====================="

check_dir "$PROJECT_ROOT/ios/Resources"
check_dir "$PROJECT_ROOT/ios/Classes"
check_dir "$PROJECT_ROOT/ios/Frameworks"

echo ""
echo "🔍 Vérification du Contenu:"
echo "=========================="

# Vérifier que ResourceManager contient les bonnes méthodes
echo ""
echo "  ResourceManager.h:"
check_content "$PROJECT_ROOT/ios/Classes/ResourceManager.h" "bundleResourcePath"
check_content "$PROJECT_ROOT/ios/Classes/ResourceManager.h" "ensureResourcesAvailable"
check_content "$PROJECT_ROOT/ios/Classes/ResourceManager.h" "initializeCifrasoftPaths"

echo ""
echo "  ResourceManager.m:"
check_content "$PROJECT_ROOT/ios/Classes/ResourceManager.m" "bundleResourcePath"
check_content "$PROJECT_ROOT/ios/Classes/ResourceManager.m" "initializeCifrasoftPaths"

echo ""
echo "  SCSManagerWrapper.m:"
check_content "$PROJECT_ROOT/ios/Classes/SCSManagerWrapper.m" "ResourceManager"
check_content "$PROJECT_ROOT/ios/Classes/SCSManagerWrapper.m" "initializeResources"
check_content "$PROJECT_ROOT/ios/Classes/SCSManagerWrapper.m" "isInitialized"

echo ""
echo "  MinfoSdkPlugin.swift:"
check_content "$PROJECT_ROOT/ios/Classes/MinfoSdkPlugin.swift" "AudioSession activée"
check_content "$PROJECT_ROOT/ios/Classes/MinfoSdkPlugin.swift" "Décodage en cours"

echo ""
echo "  minfo_sdk.podspec:"
check_content "$PROJECT_ROOT/ios/minfo_sdk.podspec" "resource_bundles"
check_content "$PROJECT_ROOT/ios/minfo_sdk.podspec" "Resources/\\*\\*/\\*"

echo ""
echo "📚 Documentation:"
echo "================"

check_file "$PROJECT_ROOT/docs/IMPLEMENTATION_SUMMARY.md"
check_file "$PROJECT_ROOT/docs/DECODING_FIX.md"
check_file "$PROJECT_ROOT/docs/CIFRASOFT_DATA_SETUP.md"

echo ""
echo "📊 Résumé de la Vérification:"
echo "============================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ TOUS LES FICHIERS SONT EN PLACE${NC}"
else
    echo -e "${RED}❌ $ERRORS ERREUR(S) TROUVÉE(S)${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS AVERTISSEMENT(S)${NC}"
fi

echo ""
echo "🚀 Prochaines Étapes:"
echo "===================="
echo "1. Localiser les fichiers de données Cifrasoft"
echo "2. Placer les fichiers dans: ios/Resources/CifrasoftData/"
echo "3. Exécuter: flutter clean && flutter pub get"
echo "4. Exécuter: cd example/ios && rm -rf Pods Podfile.lock && pod install"
echo "5. Tester: flutter run"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✨ L'implémentation est complète et prête !${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Veuillez corriger les erreurs au-dessus${NC}"
    exit 1
fi
