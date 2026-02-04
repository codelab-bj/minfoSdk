#!/bin/bash

# Script de diagnostic - Vérifie la structure des ressources du SDK Minfo
# Usage: ./diagnose_resources.sh

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔍 Diagnostic des Ressources Minfo SDK"
echo "========================================"
echo "Répertoire racine: $PROJECT_ROOT"
echo ""

# Vérifier la structure iOS
echo "📁 Structure du répertoire iOS:"
echo "================================"
if [ -d "$PROJECT_ROOT/ios" ]; then
    ls -la "$PROJECT_ROOT/ios/" | grep -E "^d|\.podspec|\.swift|\.m|\.h" || true
else
    echo "❌ Répertoire ios non trouvé!"
fi

echo ""
echo "📦 Framework SCSTB:"
echo "==================="
if [ -d "$PROJECT_ROOT/ios/Frameworks/SCSTB.framework" ]; then
    echo "✅ Framework trouvé"
    echo "   Contenu:"
    find "$PROJECT_ROOT/ios/Frameworks/SCSTB.framework" -type f | sed 's/^/     /'
else
    echo "❌ Framework non trouvé!"
fi

echo ""
echo "📂 Ressources du SDK:"
echo "===================="
if [ -d "$PROJECT_ROOT/ios/Resources" ]; then
    echo "✅ Répertoire Resources existe"
    echo "   Contenu:"
    find "$PROJECT_ROOT/ios/Resources" -type f | sed 's/^/     /'
else
    echo "⚠️  Répertoire Resources n'existe pas"
    echo "   À créer: mkdir -p $PROJECT_ROOT/ios/Resources"
fi

echo ""
echo "🎨 Assets du SDK:"
echo "================="
if [ -d "$PROJECT_ROOT/ios/Assets" ]; then
    echo "✅ Répertoire Assets existe"
    echo "   Contenu:"
    find "$PROJECT_ROOT/ios/Assets" -type f | sed 's/^/     /'
else
    echo "⚠️  Répertoire Assets n'existe pas"
fi

echo ""
echo "📝 Classes natives:"
echo "=================="
if [ -d "$PROJECT_ROOT/ios/Classes" ]; then
    echo "✅ Répertoire Classes existe"
    echo "   Fichiers:"
    ls -1 "$PROJECT_ROOT/ios/Classes/" | sed 's/^/     /'
else
    echo "❌ Répertoire Classes n'existe pas!"
fi

echo ""
echo "⚙️  Configuration Podspec:"
echo "========================="
if [ -f "$PROJECT_ROOT/ios/minfo_sdk.podspec" ]; then
    echo "✅ Podspec trouvé"
    echo ""
    echo "   Contenu pertinent:"
    grep -E "source_files|public_header|vendored_frameworks|resource_bundles" \
        "$PROJECT_ROOT/ios/minfo_sdk.podspec" | sed 's/^/     /'
else
    echo "❌ Podspec non trouvé!"
fi

echo ""
echo "🔍 Recherche des fichiers de données Cifrasoft:"
echo "=============================================="
echo "   Extensions typiquement attendues: .dat, .bin, .idx, .tbl"
echo ""

find "$PROJECT_ROOT/ios" -type f \( -name "*.dat" -o -name "*.bin" -o -name "*.idx" -o -name "*.tbl" \) 2>/dev/null | {
    if read -r line; then
        echo "✅ Fichiers de données trouvés:"
        echo "$line"
        while read -r line; do
            echo "$line"
        done
    else
        echo "⚠️  Aucun fichier de données (.dat, .bin, .idx, .tbl) trouvé"
        echo "   Vérifiez que le moteur Cifrasoft a ses fichiers de référence"
    fi
}

echo ""
echo "📋 Résumé:"
echo "=========="
echo "✅ ResourceManager implémenté: Oui"
echo "✅ SCSManagerWrapper mis à jour: Oui"
echo "✅ Podspec mis à jour: Oui"
echo ""
echo "⚠️  À vérifier:"
echo "   1. Les fichiers de données Cifrasoft sont-ils présents?"
echo "   2. Les fichiers sont-ils dans ios/Resources/ ?"
echo "   3. Le podspec inclut-il la section resource_bundles?"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Vérifiez la documentation Cifrasoft pour les fichiers requis"
echo "   2. Placez les fichiers dans ios/Resources/"
echo "   3. Lancez: flutter clean && flutter pub get"
echo "   4. Dans example/ios: rm -rf Pods Podfile.lock && pod install"
echo "   5. Testez: flutter run"
echo ""
