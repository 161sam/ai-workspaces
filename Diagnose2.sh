#!/bin/bash

echo "=== PROBLEM 1: CADDYFILE SYNTAX PRÜFEN ==="
# Caddyfile anschauen um das Problem zu finden
echo "Aktuelle Caddyfile:"
cat docker/caddy/Caddyfile | head -20

echo -e "\n=== PROBLEM 2: GUACAMOLE TIPPFEHLER PRÜFEN ==="
# Nach dem Tippfehler in .env suchen
grep -i "guracamole\|guacamole" .env

echo -e "\n=== DOCKER COMPOSE YAML PRÜFEN ==="
# Nach Guacamole-Konfiguration suchen
grep -A 5 -B 5 -i "guracamole\|guacamole" docker-compose.yml

echo -e "\n=== ALLE TIPPFEHLER FINDEN ==="
# Suche nach allen Guacamole-Tippfehlern im Projekt
find . -type f -name "*.yml" -o -name "*.yaml" -o -name "*.env" -o -name "Caddyfile" | xargs grep -l "guracamole" 2>/dev/null || echo "Keine 'guracamole' Tippfehler in Konfigurationsdateien gefunden"
