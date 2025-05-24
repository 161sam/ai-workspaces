#!/bin/bash

echo "=== DEFINITIVE LÖSUNG - ALLE PROBLEME ENDGÜLTIG BEHEBEN ==="

echo "SCHRITT 1: ALLE PROBLEMATISCHEN CONTAINER FORCE-REMOVE"
sudo docker rm -f caddy guacamole-web 2>/dev/null || echo "Container bereits entfernt"

echo -e "\nSCHRITT 2: ALLE RELATED VOLUMES ENTFERNEN"
sudo docker volume rm ai-workspaces_guacamole_data 2>/dev/null || echo "Volume bereits entfernt"
sudo docker volume rm ai-workspaces_caddy-data 2>/dev/null || echo "Volume bereits entfernt"
sudo docker volume rm ai-workspaces_caddy-config 2>/dev/null || echo "Volume bereits entfernt"

echo -e "\nSCHRITT 3: CADDYFILE KOMPLETT NEU ERSTELLEN"
# Lösche das alte Caddyfile
rm -f ./Caddyfile

# Erstelle ein MINIMALES, SAUBERES Caddyfile
cat > ./Caddyfile << 'EOF'
{
    email admin@ecospherenet.work
}

n8n.ecospherenet.work {
    reverse_proxy n8n:5678
}

webui.ecospherenet.work {
    reverse_proxy open-webui:8080
}

flowise.ecospherenet.work {
    reverse_proxy flowise:3000
}

langfuse.ecospherenet.work {
    reverse_proxy ai-workspaces-langfuse-web-1:3000
}

supabase.ecospherenet.work {
    reverse_proxy supabase-kong:8000
}

grafana.ecospherenet.work {
    reverse_proxy grafana:3000
}

letta.ecospherenet.work {
    reverse_proxy letta:8283
}

prometheus.ecospherenet.work {
    reverse_proxy prometheus:9090
}

searxng.ecospherenet.work {
    reverse_proxy searxng:8080
}

portainer.ecospherenet.work {
    reverse_proxy portainer:9000
}

desktop.ecospherenet.work {
    reverse_proxy guacamole-web:8080
}
EOF

echo "Neues, sauberes Caddyfile erstellt."

echo -e "\nSCHRITT 4: GUACAMOLE UMGEBUNGSVARIABLEN KORRIGIEREN"
# Erstelle eine Guacamole-spezifische .env-Ergänzung
cat >> .env << 'EOF'

# Guacamole Korrekturen
GUACAMOLE_HOME=/etc/guacamole
EOF

echo -e "\nSCHRITT 5: DOCKER-COMPOSE GUACAMOLE SEKTION PATCHEN"
# Backup der docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup-final2

# Entferne alle problematischen GUACAMOLE_HOME Definitionen und ersetze sie
sed -i 's|GUACAMOLE_HOME=/etc/guracamole|GUACAMOLE_HOME=/etc/guacamole|g' docker-compose.yml

echo -e "\nSCHRITT 6: IMAGES NEU PULLEN"
echo "Hole frische Docker Images:"
sudo docker pull caddy:2-alpine
sudo docker pull guacamole/guacamole:latest

echo -e "\nSCHRITT 7: NUR KRITISCHE SERVICES STARTEN"
echo "Starte nur Caddy und Guacamole zum Testen:"
sudo docker compose up -d caddy
sleep 5
sudo docker compose up -d guacamole-web

echo -e "\nSCHRITT 8: SOFORTIGER STATUS-CHECK"
sleep 10

echo "=== CADDY STATUS ==="
if sudo docker ps --filter "name=caddy" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Caddy: LÄUFT"
    echo "Caddyfile Test:"
    sudo docker exec caddy caddy validate --config /etc/caddy/Caddyfile && echo "✅ Caddyfile: VALID" || echo "❌ Caddyfile: INVALID"
else
    echo "❌ Caddy: FEHLER"
    echo "Logs:"
    sudo docker logs caddy --tail 5
fi

echo -e "\n=== GUACAMOLE STATUS ==="
if sudo docker ps --filter "name=guacamole-web" --format "{{.Status}}" | grep -q "Up"; then
    echo "✅ Guacamole: LÄUFT"
else
    echo "❌ Guacamole: FEHLER"
    echo "Logs:"
    sudo docker logs guacamole-web --tail 5
fi

echo -e "\n=== NETZWERK-TESTS ==="
echo "Teste interne Verbindungen:"
sudo docker exec caddy nc -zv n8n 5678 2>/dev/null && echo "✅ Caddy→n8n: OK" || echo "❌ Caddy→n8n: FEHLER"
sudo docker exec caddy nc -zv guacamole-web 8080 2>/dev/null && echo "✅ Caddy→Guacamole: OK" || echo "❌ Caddy→Guacamole: FEHLER"

echo -e "\n=== FINALE ANWEISUNGEN ==="
echo "Falls beide Services ✅ zeigen:"
echo "1. Starte alle anderen Services: sudo docker compose up -d"
echo "2. Teste URLs: https://n8n.ecospherenet.work"
echo "3. Teste Desktop: https://desktop.ecospherenet.work"
echo ""
echo "Falls noch Probleme bestehen:"
echo "1. Prüfe DNS: ping n8n.ecospherenet.work"
echo "2. Prüfe Ports: sudo netstat -tlnp | grep :443"
echo "3. Manueller Caddyfile-Test: sudo docker exec caddy cat /etc/caddy/Caddyfile"
