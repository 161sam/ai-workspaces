#!/bin/bash

# 1. Caddy Logs überprüfen
echo "=== CADDY LOGS ==="
sudo docker logs caddy --tail 50

echo -e "\n=== GUACAMOLE-WEB LOGS ==="
sudo docker logs guacamole-web --tail 50

echo -e "\n=== CONTAINER STATUS ==="
sudo docker ps --filter "name=caddy" --filter "name=guacamole"

echo -e "\n=== RESTART COUNTS ==="
sudo docker inspect caddy --format='{{.RestartCount}}'
sudo docker inspect guacamole-web --format='{{.RestartCount}}'

echo -e "\n=== ENVIRONMENT CHECK ==="
# Überprüfung der .env Datei auf häufige Probleme
grep -E "(DOMAIN|GUACAMOLE|CADDY)" .env | head -10
