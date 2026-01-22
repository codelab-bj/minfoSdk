#!/bin/bash

echo "🔍 Test de validation des libs natives Cifrasoft"
echo "================================================"

# Test Android
echo ""
echo "📱 Android - Vérification des libs Cifrasoft:"
echo "- Recherche de soundcode.jar..."
find . -name "*soundcode*" -type f 2>/dev/null || echo "  ❌ Aucun fichier soundcode trouvé"

echo "- Recherche de libscuc.so..."
find . -name "*libscuc*" -type f 2>/dev/null || echo "  ❌ Aucun fichier libscuc trouvé"

echo "- Vérification imports Kotlin..."
grep -r "com.cifrasoft" android/ 2>/dev/null || echo "  ❌ Aucun import Cifrasoft trouvé"

# Test iOS
echo ""
echo "🍎 iOS - Vérification du framework Cifrasoft:"
echo "- Recherche de SCSTB.framework..."
find . -name "*SCSTB*" -type d 2>/dev/null || echo "  ❌ Aucun framework SCSTB trouvé"

echo "- Recherche de SCSManager..."
find . -name "*SCS*" -type f 2>/dev/null || echo "  ❌ Aucun fichier SCS trouvé"

echo "- Vérification imports Swift..."
grep -r "SCSManager" ios/ 2>/dev/null || echo "  ❌ Aucun import SCSManager trouvé"

echo ""
echo "✅ Test terminé - Vérifiez les résultats ci-dessus"
