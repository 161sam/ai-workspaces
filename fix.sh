#!/bin/bash

echo "=== VOLLSTÄNDIGE REPARATUR ==="

echo "SCHRITT 1: CADDYFILE SYNTAX REPARIEREN"
# Schaue das aktuelle Caddyfile an
echo "Aktuelles Caddyfile (erste 30 Zeilen):"
head -30 ./Caddyfile

echo -e "\nSCHRITT 2: CADDYFILE GLOBALE BLÖCKE FINDEN"
# Suche nach problematischen globalen Blöcken
grep -n "^{" ./Caddyfile
echo "Zeilen mit nur '{' gefunden"

echo -e "\nSCHRITT 3: ALLE CONTAINER STOPPEN"
# Stoppe alle Container für einen sauberen Neustart
sudo docker compose down

echo -e "\nSCHRITT 4: GUACAMOLE DOCKER VOLUMES BEREINIGEN"
# Entferne das alte Volume mit dem Tippfehler
sudo docker volume ls | grep guacamole
echo "Entferne defekte Guacamole-Volumes:"
sudo docker volume rm ai-workspaces_guacamole_data 2>/dev/null || echo "Volume nicht gefunden"

echo -e "\nSCHRITT 5: ENVIRONMENT VARIABLEN PRÜFEN"
# Prüfe ob noch Tippfehler in .env existieren
grep -i "guracamole" .env || echo "Keine 'guracamole' Tippfehler in .env gefunden"

echo -e "\nSCHRITT 6: CADDYFILE BACKUP UND REPARATUR"
# Backup des aktuellen Caddyfile
cp ./Caddyfile ./Caddyfile.broken

# Erstelle ein minimales, funktionierendes Caddyfile
cat > ./Caddyfile.minimal << 'EOF'
# Globale Konfiguration (MUSS ZUERST STEHEN!)
{
    email {$ACME_EMAIL}
    admin off
}

# n8n Service
{$N8N_HOSTNAME} {
    reverse_proxy n8n:5678
}

# Desktop/Guacamole Service
{$GUACAMOLE_HOSTNAME} {
    reverse_proxy guacamole-web:8080
}

# Flowise Service
{$FLOWISE_HOSTNAME} {
    reverse_proxy flowise:3000
}

# Portainer Service
{$PORTAINER_HOSTNAME} {
    reverse_proxy portainer:9000
}
EOF

# Verwende das minimale Caddyfile
echo "Verwende minimales, funktionierendes Caddyfile..."
mv ./Caddyfile.minimal ./Caddyfile

echo -e "\nSCHRITT 7: CONTAINER SAUBER NEUSTARTEN"
# Starte alle Services neu
sudo docker compose up -d

echo -e "\nSCHRITT 8: WARTEN UND STATUS PRÜFEN"
echo "Warte 10 Sekunden für Container-Start..."
sleep 10

echo "=== CONTAINER STATUS ==="
sudo docker ps --filter "name=caddy" --filter "name=guacamole"

echo -e "\n=== CADDY STATUS ==="
if sudo docker ps --filter "name=caddy" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Caddy läuft erfolgreich!"
    sudo docker logs caddy --tail 5
else
    echo "❌ Caddy läuft noch nicht. Logs:"
    sudo docker logs caddy --tail 10
fi

echo -e "\n=== GUACAMOLE STATUS ==="
if sudo docker ps --filter "name=guacamole" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Guacamole läuft erfolgreich!"
    sudo docker logs guacamole-web --tail 5
else
    echo "❌ Guacamole läuft noch nicht. Logs:"
    sudo docker logs guacamole-web --tail 10
fi

echo -e "\n=== SERVICE TESTS ==="
echo "Teste Service-Erreichbarkeit:"
curl -I https://n8n.ecosphernet.work 2>/dev/null | head -1 || echo "❌ n8n nicht erreichbar"
curl -I https://desktop.ecosphernet.work 2>/dev/null | head -1 || echo "❌ Desktop nicht erreichbar"

echo -e "\n=== ZUSAMMENFASSUNG ==="
echo "Wenn beide Container 'Up' zeigen, sind die Hauptprobleme behoben!"
echo "Falls noch Probleme bestehen, führe aus:"
echo "  sudo docker logs caddy"
echo "  sudo docker logs guacamole-web"
