#!/bin/bash

echo "=== GEZIELTE DIAGNOSE DER HARTNÄCKIGEN PROBLEME ==="

echo "PROBLEM 1: CADDYFILE SYNTAX PRÜFEN"
echo "Aktuelles Caddyfile Inhalt:"
cat ./Caddyfile | head -20
echo ""
echo "Caddyfile Zeilen-Nummerierung:"
cat -n ./Caddyfile | head -10

echo -e "\nPROBLEM 2: GUACAMOLE DOCKER IMAGE TIPPFEHLER"
echo "Der Tippfehler kommt aus dem Docker Image selbst!"
echo "Guacamole Image Config prüfen:"
sudo docker inspect guacamole/guacamole:latest | grep -i "guracamole\|guacamole" || echo "Keine Tippfehler im Image gefunden"

echo -e "\nPROBLEM 3: DOCKER-COMPOSE GUACAMOLE SECTION"
echo "Aktuelle Guacamole-Konfiguration in docker-compose.yml:"
grep -A 20 -B 5 "guacamole-web:" docker-compose.yml

echo -e "\nPROBLEM 4: ALLE CONTAINER MIT PROBLEMEN IDENTIFIZIEREN"
echo "Container die Probleme haben:"
sudo docker ps --filter "status=restarting" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo -e "\nPROBLEM 5: SPECIFIC VOLUME ÜBERPRÜFUNG"
echo "Guacamole Volume Details:"
sudo docker volume inspect ai-workspaces_guacamole_data 2>/dev/null || echo "Volume nicht gefunden"

echo -e "\nPROBLEM 6: CADDYFILE PATH MAPPING"
echo "Docker-Compose Caddy Volume Mapping:"
grep -A 5 -B 5 "Caddyfile" docker-compose.yml

echo -e "\nPROBLEM 7: ALTE CONTAINER BEREINIGEN"
echo "Liste aller Container (auch gestoppte):"
sudo docker ps -a --filter "name=caddy" --filter "name=guacamole"
