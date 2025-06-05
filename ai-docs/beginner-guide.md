# Einstieg in die Codebasis

Dieses Dokument richtet sich an Einsteiger und erklärt die wichtigsten Dateien und Verzeichnisse des Projekts.

## Grundlegender Aufbau

- **`docker-compose.yml`** – orchestriert alle Container der Umgebung, darunter n8n, Flowise, Open WebUI und viele weitere Tools.
- **`scripts/`** – enthält Shell-Skripte zur Installation und zum Starten der Services. `install.sh` führt diese Skripte schrittweise aus.
- **`start_services.py`** – Python-Skript, das Supabase bei Bedarf klont und gemeinsam mit den anderen Diensten startet.
- **`ai-docs/`** – Dokumentationsordner mit Beschreibungen zur Projektstruktur und Hintergrundinformationen.
- **`.env.example`** – Vorlage für Umgebungsvariablen, aus der während der Installation die Datei `.env` generiert wird.

## Was man lernen sollte

1. **Docker und Docker Compose** – verstehen, wie Container definiert und gesteuert werden.
2. **n8n-Grundlagen** – Workflows importieren und eigene Automationen erstellen.
3. **Reverse Proxy mit Caddy** – sorgt für HTTPS und leitet Domains an die richtigen Container weiter.
4. **Monitoring** – Prometheus und Grafana sammeln Metriken und visualisieren sie.

Dieses Repository bietet einen Baukasten, um schnell eine lokale oder selbstgehostete Automatisierungsumgebung aufzusetzen. Wer die Installationsskripte nachvollzieht und die Dienste aus `docker-compose.yml` kennenlernt, kann bald eigene Projekte umsetzen.
