#!/bin/bash

# Script pour lier manuellement la bibliothèque Cifrasoft
echo "🔗 Liaison manuelle de SCSTB_LibraryU.a..."

# Chemin vers la bibliothèque
LIB_PATH="$SRCROOT/SCSTB_LibraryU.a"

if [ -f "$LIB_PATH" ]; then
    echo "✅ Bibliothèque trouvée: $LIB_PATH"
    # Ajouter la bibliothèque aux flags de link
    export OTHER_LDFLAGS="$OTHER_LDFLAGS $LIB_PATH"
    echo "✅ Bibliothèque ajoutée aux flags de link"
else
    echo "❌ Bibliothèque non trouvée: $LIB_PATH"
    exit 1
fi
