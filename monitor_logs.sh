#!/bin/bash
# monitor_logs.sh - Monitoring des logs Minfo

echo "📊 Monitoring des logs Minfo SDK"
echo "Appuyez sur Ctrl+C pour arrêter"
echo "================================"

# Filtrer les logs pertinents avec couleurs
adb logcat | grep --line-buffered -E "(MinfoSDK|Flutter|AudioQR|SoundCode|UltraCode)" | while read line; do
    if [[ $line == *"❌"* ]] || [[ $line == *"ERROR"* ]]; then
        echo -e "\033[31m$line\033[0m"  # Rouge pour erreurs
    elif [[ $line == *"✅"* ]] || [[ $line == *"SUCCESS"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Vert pour succès
    elif [[ $line == *"🎯"* ]] || [[ $line == *"DETECTION"* ]]; then
        echo -e "\033[33m$line\033[0m"  # Jaune pour détections
    else
        echo "$line"
    fi
done
