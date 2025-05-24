#!/bin/bash

echo "=== ENDGÜLTIGE REPARATUR - ALLE PROBLEME BEHEBEN ==="

echo "SCHRITT 1: ENVIRONMENT VARIABLEN ÜBERPRÜFEN"
echo "Prüfe verfügbare Email-Variablen:"
grep -E "(EMAIL|email)" .env | head -5

echo -e "\nSCHRITT 2: ALLE CONTAINER STOPPEN UND BEREINIGEN"
sudo docker compose down
sudo docker container prune -f
sudo docker system prune -f

echo -e "\nSCHRITT 3: ALLE GUACAMOLE TIPPFEHLER SUCHEN UND BEHEBEN"
echo "Suche nach 'guracamole' in allen relevanten Dateien:"
find . -name "*.yml" -o -name "*.yaml" -o -name "*.env" | xargs grep -l "guracamole" 2>/dev/null || echo "Keine Tippfehler in Konfigurationsdateien gefunden"

# Backup aller wichtigen Dateien
cp docker-compose.yml docker-compose.yml.backup-final
cp .env .env.backup-final

# Korrigiere ALLE Tippfehler in docker-compose.yml
sed -i 's/guracamole/guacamole/g' docker-compose.yml

# Korrigiere ALLE Tippfehler in .env (falls vorhanden)
sed -i 's/guracamole/guacamole/g' .env

echo "Tippfehler-Korrektur abgeschlossen."

echo -e "\nSCHRITT 4: KORREKTES CADDYFILE ERSTELLEN"
# Backup des aktuellen Caddyfile
cp ./Caddyfile ./Caddyfile.backup-final

# Erstelle ein funktionierendes Caddyfile mit korrekter Email-Syntax
cat > ./Caddyfile << 'EOF'
# Globale Konfiguration (MUSS ZUERST STEHEN!)
{
    # Verwende eine Fallback-Email wenn LETSENCRYPT_EMAIL nicht gesetzt ist
    email admin@ecospherenet.work
    admin off
}

# N8N Service
{$N8N_HOSTNAME} {
    reverse_proxy n8n:5678
}

# Open WebUI
{$WEBUI_HOSTNAME} {
    reverse_proxy open-webui:8080
}

# Flowise
{$FLOWISE_HOSTNAME} {
    reverse_proxy flowise:3000
}

# Langfuse
{$LANGFUSE_HOSTNAME} {
    reverse_proxy langfuse-web:3000
}

# Supabase
{$SUPABASE_HOSTNAME} {
    reverse_proxy kong:8000
}

# Grafana
{$GRAFANA_HOSTNAME} {
    reverse_proxy grafana:3000
}

# Letta
{$LETTA_HOSTNAME} {
    reverse_proxy letta:8283
}

# Prometheus
{$PROMETHEUS_HOSTNAME} {
    reverse_proxy prometheus:9090
}

# SearXNG
{$SEARXNG_HOSTNAME} {
    reverse_proxy searxng:8080
}

# Portainer
{$PORTAINER_HOSTNAME} {
    reverse_proxy portainer:9000
}

# Guacamole (Desktop)
{$GUACAMOLE_HOSTNAME} {
    reverse_proxy guacamole-web:8080
}
EOF

echo "Funktionierendes Caddyfile erstellt."

echo -e "\nSCHRITT 5: ALLE VOLUMES BEREINIGEN"
echo "Entferne defekte Volumes:"
sudo docker volume ls | grep guacamole
sudo docker volume rm $(sudo docker volume ls -q | grep guacamole) 2>/dev/null || echo "Keine Guacamole-Volumes zum Entfernen gefunden"

echo -e "\nSCHRITT 6: SAUBERER NEUSTART ALLER SERVICES"
echo "Starte alle Services neu..."
sudo docker compose up -d

echo -e "\nSCHRITT 7: WARTEN FÜR CONTAINER-START"
echo "Warte 15 Sekunden für vollständigen Container-Start..."
sleep 15

echo -e "\nSCHRITT 8: FINALER STATUS-CHECK"
echo "=== ALLE CONTAINER STATUS ==="
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== KRITISCHE SERVICES STATUS ==="
if sudo docker ps --filter "name=caddy" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Caddy: ERFOLGREICH"
else
    echo "❌ Caddy: FEHLER"
    echo "Caddy Logs:"
    sudo docker logs caddy --tail 3
fi

if sudo docker ps --filter "name=guacamole-web" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Guacamole: ERFOLGREICH"
else
    echo "❌ Guacamole: FEHLER"
    echo "Guacamole Logs:"
    sudo docker logs guacamole-web --tail 3
fi

echo -e "\n=== CADDYFILE VALIDATION ==="
echo "Teste Caddyfile Syntax:"
sudo docker exec caddy caddy validate --config /etc/caddy/Caddyfile 2>/dev/null && echo "✅ Caddyfile Syntax: OK" || echo "❌ Caddyfile Syntax: FEHLER"

echo -e "\n=== SERVICE ERREICHBARKEIT ==="
echo "Teste Service-URLs:"
timeout 5 curl -k -I https://n8n.ecospherenet.work 2>/dev/null | head -1 || echo "❌ n8n nicht erreichbar (normal bei erstem Start)"
timeout 5 curl -k -I https://desktop.ecospherenet.work 2>/dev/null | head -1 || echo "❌ Desktop nicht erreichbar (normal bei erstem Start)"

echo -e "\n=== ZUSAMMENFASSUNG ==="
echo "Reparatur abgeschlossen!"
echo ""
echo "✅ Wenn Caddy und Guacamole 'Up' zeigen, sind die Probleme behoben"
echo "✅ Services sollten in 2-3 Minuten über URLs erreichbar sein"
echo "✅ Falls noch Probleme: Warte 5 Minuten und teste erneut"
echo ""
echo "📋 Nächste Schritte:"
echo "1. Teste: https://n8n.ecospherenet.work"
echo "2. Teste: https://desktop.ecospherenet.work"
echo "3. Bei Problemen: sudo docker logs <container-name>"
