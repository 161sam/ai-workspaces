#!/bin/bash

set -e

# Source the utilities file
source "$(dirname "$0")/utils.sh"

# Get the directory where the script resides
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ENV_FILE="$PROJECT_ROOT/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    log_error "The .env file ('$ENV_FILE') was not found."
    exit 1
fi

# Load environment variables from .env file
# Use set -a to export all variables read from the file
set -a
source "$ENV_FILE"
set +a

# Function to check if a profile is active
is_profile_active() {
    local profile_to_check="$1"
    # COMPOSE_PROFILES is sourced from .env and will be available here
    if [ -z "$COMPOSE_PROFILES" ]; then
        return 1 # Not active if COMPOSE_PROFILES is empty or not set
    fi
    # Check if the profile_to_check is in the comma-separated list
    # Adding commas at the beginning and end of both strings handles edge cases
    # (e.g., single profile, profile being a substring of another)
    if [[ ",$COMPOSE_PROFILES," == *",$profile_to_check,"* ]]; then
        return 0 # Active
    else
        return 1 # Not active
    fi
}

# Funktion um zu prüfen ob eines der Desktop-Profile aktiv ist
is_any_desktop_profile_active() {
    local desktop_profiles=("desktop-ubuntu" "desktop-kde" "desktop-xfce" "desktop-mate" "desktop-fedora-kde" "desktop-alpine")
    for profile in "${desktop_profiles[@]}"; do
        if is_profile_active "$profile"; then
            return 0 # True - mindestens ein Desktop-Profil ist aktiv
        fi
    done
    return 1 # False - kein Desktop-Profil aktiv
}

# Funktion um das aktive Desktop-Profil zu ermitteln
get_active_desktop_profile() {
    local desktop_profiles=("desktop-ubuntu" "desktop-kde" "desktop-xfce" "desktop-mate" "desktop-fedora-kde" "desktop-alpine")
    for profile in "${desktop_profiles[@]}"; do
        if is_profile_active "$profile"; then
            echo "$profile"
            return
        fi
    done
    echo "none"
}

# Funktion um Desktop-Profil-Namen zu formatieren
format_desktop_profile_name() {
    local profile="$1"
    case "$profile" in
        "desktop-ubuntu") echo "Ubuntu Desktop (RDP)" ;;
        "desktop-kde") echo "KDE Plasma Desktop" ;;
        "desktop-xfce") echo "XFCE Desktop" ;;
        "desktop-mate") echo "MATE Desktop" ;;
        "desktop-fedora-kde") echo "Fedora KDE Desktop" ;;
        "desktop-alpine") echo "Alpine KDE Desktop" ;;
        *) echo "Unknown Desktop" ;;
    esac
}

# --- Service Access Credentials ---

# Display credentials, checking if variables exist
echo
log_info "Service Access Credentials. Save this information securely!"

if is_profile_active "n8n"; then
  echo
  echo "================================= n8n ================================="
  echo
  echo "Host: ${N8N_HOSTNAME:-<hostname_not_set>}"
fi

if is_profile_active "open-webui"; then
  echo
  echo "================================= WebUI ==============================="
  echo
  echo "Host: ${WEBUI_HOSTNAME:-<hostname_not_set>}"
fi

if is_profile_active "flowise"; then
  echo
  echo "================================= Flowise ============================="
  echo
  echo "Host: ${FLOWISE_HOSTNAME:-<hostname_not_set>}"
  echo "User: ${FLOWISE_USERNAME:-<not_set_in_env>}"
  echo "Password: ${FLOWISE_PASSWORD:-<not_set_in_env>}"
fi

if is_profile_active "supabase"; then
  echo
  echo "================================= Supabase ============================"
  echo
  echo "External Host (via Caddy): ${SUPABASE_HOSTNAME:-<hostname_not_set>}"
  echo "Studio User: ${DASHBOARD_USERNAME:-<not_set_in_env>}"
  echo "Studio Password: ${DASHBOARD_PASSWORD:-<not_set_in_env>}"
  echo
  echo "Internal API Gateway: http://kong:8000"
  echo "Service Role Secret: ${SERVICE_ROLE_KEY:-<not_set_in_env>}"
fi

if is_profile_active "langfuse"; then
  echo
  echo "================================= Langfuse ============================"
  echo
  echo "Host: ${LANGFUSE_HOSTNAME:-<hostname_not_set>}"
  echo "User: ${LANGFUSE_INIT_USER_EMAIL:-<not_set_in_env>}"
  echo "Password: ${LANGFUSE_INIT_USER_PASSWORD:-<not_set_in_env>}"
fi

if is_profile_active "monitoring"; then
  echo
  echo "================================= Grafana ============================="
  echo
  echo "Host: ${GRAFANA_HOSTNAME:-<hostname_not_set>}"
  echo "User: admin"
  echo "Password: ${GRAFANA_ADMIN_PASSWORD:-<not_set_in_env>}"
  echo
  echo "================================= Prometheus =========================="
  echo
  echo "Host: ${PROMETHEUS_HOSTNAME:-<hostname_not_set>}"
  echo "User: ${PROMETHEUS_USERNAME:-<not_set_in_env>}"
  echo "Password: ${PROMETHEUS_PASSWORD:-<not_set_in_env>}"
fi

if is_profile_active "searxng"; then
  echo
  echo "================================= SearXNG ============================="
  echo
  echo "Host: ${SEARXNG_HOSTNAME:-<hostname_not_set>}"
  echo "User: ${SEARXNG_USERNAME:-<not_set_in_env>}"
  echo "Password: ${SEARXNG_PASSWORD:-<not_set_in_env>}"
fi

if is_profile_active "qdrant"; then
  echo
  echo "================================= Qdrant =============================="
  echo
  echo "Internal REST API Access (e.g., from backend): http://qdrant:6333"
  echo "(Note: Not exposed externally via Caddy by default)"
fi

if is_profile_active "crawl4ai"; then
  echo
  echo "================================= Crawl4AI ============================"
  echo
  echo "Internal Access (e.g., from n8n): http://crawl4ai:11235"
  echo "(Note: Not exposed externally via Caddy by default)"
fi

if is_profile_active "letta"; then
  echo
  echo "================================= Letta ================================"
  echo
  echo "Host: ${LETTA_HOSTNAME:-<hostname_not_set>}"
  echo "Authorization: Bearer ${LETTA_SERVER_PASSWORD}"
fi

if is_profile_active "portainer"; then
  echo
  echo "================================= Portainer ============================"
  echo
  echo "Host: ${PORTAINER_HOSTNAME:-<hostname_not_set>}"
  echo "First-time Setup: Create admin account on first visit"
  echo "Function: Docker container management and monitoring"
fi

if is_any_desktop_profile_active; then
  ACTIVE_DESKTOP_PROFILE=$(get_active_desktop_profile)
  DESKTOP_PROFILE_NAME=$(format_desktop_profile_name "$ACTIVE_DESKTOP_PROFILE")

  echo
  echo "================================= Remote Desktop ======================"
  echo
  echo "Desktop Environment: $DESKTOP_PROFILE_NAME"
  echo "Access URL: ${GUACAMOLE_HOSTNAME:-<hostname_not_set>}"
  echo
  echo "--- Guacamole Web Interface ---"
  echo "Default Admin Login: guacadmin / guacadmin"
  echo "⚠️  SECURITY: Change default password immediately after first login!"
  echo
  echo "--- Desktop Connection Details ---"
  echo "Desktop User: abc (created automatically)"
  echo "Connection: Pre-configured in Guacamole as '$DESKTOP_PROFILE_NAME'"
  echo
  echo "--- Desktop Specifications ---"
  case "$ACTIVE_DESKTOP_PROFILE" in
    "desktop-ubuntu")
      echo "Type: Traditional Ubuntu Desktop with RDP"
      echo "Memory Usage: ~1GB RAM (lightweight)"
      echo "Features: Basic desktop environment, RDP-optimized"
      ;;
    "desktop-kde")
      echo "Type: KDE Plasma Desktop Environment"
      echo "Memory Usage: ~2-3GB RAM (full-featured)"
      echo "Features: Modern interface, extensive customization"
      ;;
    "desktop-xfce")
      echo "Type: XFCE Desktop Environment"
      echo "Memory Usage: ~1.5GB RAM (balanced)"
      echo "Features: Fast, traditional interface"
      ;;
    "desktop-mate")
      echo "Type: MATE Desktop Environment"
      echo "Memory Usage: ~1.5GB RAM (user-friendly)"
      echo "Features: Windows-like interface, familiar layout"
      ;;
    "desktop-fedora-kde")
      echo "Type: Fedora Linux with KDE Plasma"
      echo "Memory Usage: ~2-3GB RAM (cutting-edge)"
      echo "Features: Latest packages, modern features"
      ;;
    "desktop-alpine")
      echo "Type: Alpine Linux with KDE"
      echo "Memory Usage: ~800MB RAM (minimal)"
      echo "Features: Security-focused, minimal footprint"
      ;;
  esac
  echo
  echo "--- Usage Instructions ---"
  echo "1. Open ${GUACAMOLE_HOSTNAME:-<hostname_not_set>} in your browser"
  echo "2. Login with guacadmin/guacadmin"
  echo "3. Click on the '$DESKTOP_PROFILE_NAME' connection"
  echo "4. Desktop will load in your browser window"
  echo "5. Change admin password: Settings → Preferences → Change Password"
  echo
  echo "--- File Sharing ---"
  echo "Shared Folder: /shared (mapped to ./shared on host)"
  echo "Use this folder to transfer files between host and desktop"
fi

if is_profile_active "cpu" || is_profile_active "gpu-nvidia" || is_profile_active "gpu-amd"; then
  echo
  echo "================================= Ollama =============================="
  echo
  echo "Internal Access (e.g., from n8n, Open WebUI): http://ollama:11434"
  echo "(Note: Ollama runs with the selected profile: cpu, gpu-nvidia, or gpu-amd)"
fi

if is_profile_active "n8n" || is_profile_active "langfuse"; then
  echo
  echo "================================= Redis (Valkey) ======================"
  echo
  echo "Internal Host: ${REDIS_HOST:-redis}"
  echo "Internal Port: ${REDIS_PORT:-6379}"
  echo "Password: ${REDIS_AUTH:-LOCALONLYREDIS} (Note: Default if not set in .env)"
  echo "(Note: Primarily for internal service communication, not exposed externally by default)"
fi

# Standalone PostgreSQL (used by n8n, Langfuse, etc.)
# Check if n8n or langfuse is active, as they use this PostgreSQL instance.
# The Supabase section already details its own internal Postgres.
if is_profile_active "n8n" || is_profile_active "langfuse"; then
  # Check if Supabase is NOT active, to avoid confusion with Supabase's Postgres if both are present
  # However, the main POSTGRES_PASSWORD is used by this standalone instance.
  # Supabase has its own environment variables for its internal Postgres if configured differently,
  # but the current docker-compose.yml uses the main POSTGRES_PASSWORD for langfuse's postgres dependency too.
  # For clarity, we will label this distinctly.
  echo
  echo "==================== Standalone PostgreSQL (for n8n, Langfuse, etc.) ====================="
  echo
  echo "Host: ${POSTGRES_HOST:-postgres}"
  echo "Port: ${POSTGRES_PORT:-5432}"
  echo "Database: ${POSTGRES_DB:-postgres}" # This is typically 'postgres' or 'n8n' for n8n, and 'langfuse' for langfuse, but refers to the service.
  echo "User: ${POSTGRES_USER:-postgres}"
  echo "Password: ${POSTGRES_PASSWORD:-<not_set_in_env>}"
  echo "(Note: This is the PostgreSQL instance used by services like n8n and Langfuse.)"
  echo "(It is separate from Supabase's internal PostgreSQL if Supabase is also enabled.)"
fi

echo
echo "======================================================================="
echo

# --- Update Script Info (Placeholder) ---
log_info "To update the services, run the 'update.sh' script: bash ./scripts/update.sh"

echo
echo "======================================================================"
echo
echo "Security Reminders:"
if is_profile_active "portainer"; then
  echo "• Portainer: Secure your admin account with a strong password"
fi
if is_any_desktop_profile_active; then
  echo "• Guacamole: IMMEDIATELY change default password (guacadmin/guacadmin)"
  echo "• Desktop: Consider changing the desktop user password inside the container"
  echo "• Network: Desktop services are only accessible through Guacamole (secure)"
fi

echo
echo "Performance Tips:"
if is_any_desktop_profile_active; then
  ACTIVE_DESKTOP_PROFILE=$(get_active_desktop_profile)
  case "$ACTIVE_DESKTOP_PROFILE" in
    "desktop-kde"|"desktop-fedora-kde")
      echo "• KDE Desktop: Allocated 2-4GB RAM recommended for smooth operation"
      echo "• Graphics: Consider GPU passthrough for better performance if available"
      ;;
    "desktop-ubuntu"|"desktop-alpine")
      echo "• Lightweight Desktop: Current setup optimized for minimal resource usage"
      ;;
    "desktop-xfce"|"desktop-mate")
      echo "• Balanced Desktop: Good performance with moderate resource usage"
      ;;
  esac
  echo "• Browser: Use Chrome/Firefox for best Guacamole compatibility"
  echo "• Network: Ensure stable connection for smooth desktop experience"
fi

echo
echo "======================================================================"
echo
echo "Next Steps:"
echo "1. Review the credentials above and store them safely."
echo "2. Access the services via their respective URLs (check \`docker compose ps\` if needed)."
echo "3. Configure services as needed (e.g., first-run setup for n8n)."
if is_any_desktop_profile_active; then
  echo "4. ⚠️  CRITICAL: Change Guacamole default password immediately!"
fi
echo
echo "======================================================================"
echo
log_info "Thank you for using this installer setup!"
echo

exit 0
