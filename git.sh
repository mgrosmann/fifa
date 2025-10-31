#!/bin/bash
echo "📦 GitHub Sync"
echo "1️⃣  Exporter (push vers GitHub)"
echo "2️⃣  Importer (pull depuis GitHub)"
read -p "➡️  Entrez 1 ou 2 : " CHOICE
case "$CHOICE" in
    1)
        echo "🚀 Exportation vers GitHub..."
        git add .
        read -p "📝 Message du commit : " MESSAGE
        git commit -m "${MESSAGE:-Mise à jour rapide}"
        git push origin main
        echo "✅ Export terminé."
        ;;
    2)
        echo "⬇️  Importation depuis GitHub..."
        git stash
        git pull origin main
        echo "✅ Import terminé."
        ;;
    *)
        echo "❌ Choix invalide."
        exit 1
        ;;
esac
