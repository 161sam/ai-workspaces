#!/bin/bash

# Script to guide user through service selection for n8n-installer
# Erweiterte Wizard-Funktionalität mit Desktop-Auswahl

# Source utility functions, if any, assuming it's in the same directory
# and .env is in the parent directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Source the utilities file
source "$(dirname "$0")/utils.sh"

# Function to check if whiptail is installed
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        log_error "'whiptail' is not installed."
        log_info "This tool is required for the interactive service selection."
        log_info "On Debian/Ubuntu, you can install it using: sudo apt-get install whiptail"
        log_info "Please install whiptail and try again."
        exit 1
    fi
}

# Call the check
check_whiptail

# Store original DEBIAN_FRONTEND and set to dialog for whiptail
ORIGINAL_DEBIAN_FRONTEND="$DEBIAN_FRONTEND"
export DEBIAN_FRONTEND=dialog

# --- Read current COMPOSE_PROFILES from .env ---
CURRENT_PROFILES_VALUE=""
if [ -f "$ENV_FILE" ]; then
    LINE_CONTENT=$(grep "^COMPOSE_PROFILES=" "$ENV_FILE" || echo "")
    if [ -n "$LINE_CONTENT" ]; then
        # Get value after '=', remove potential surrounding quotes
        CURRENT_PROFILES_VALUE=$(echo "$LINE_CONTENT" | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    fi
fi
# Prepare comma-separated current profiles for easy matching, adding leading/trailing commas
current_profiles_for_matching=",$CURRENT_PROFILES_VALUE,"

# --- Define available services and their descriptions (ERWEITERT) ---
# Base service definitions (tag, description) - ERWEITERT
base_services_data=(
    "n8n" "n8n, n8n-worker, n8n-import (Workflow Automation)"
    "flowise" "Flowise (AI Agent Builder)"
    "monitoring" "Monitoring Suite (Prometheus, Grafana, cAdvisor, Node-Exporter)"
    "qdrant" "Qdrant (Vector Database)"
    "supabase" "Supabase (Backend as a Service)"
    "langfuse" "Langfuse Suite (AI Observability - includes Clickhouse, Minio)"
    "open-webui" "Open WebUI (ChatGPT-like Interface)"
    "searxng" "SearXNG (Private Metasearch Engine)"
    "crawl4ai" "Crawl4ai (Web Crawler for AI)"
    "letta" "Letta (Agent Server & SDK)"
    "ollama" "Ollama (Local LLM Runner - select hardware in next step)"
    "portainer" "Portainer (Container Management UI)"
    "desktop" "Remote Desktop (Browser-based - select variant in next step)"
)

services=() # This will be the final array for whiptail

# Populate the services array for whiptail based on current profiles or defaults
idx=0
while [ $idx -lt ${#base_services_data[@]} ]; do
    tag="${base_services_data[idx]}"
    description="${base_services_data[idx+1]}"
    status="OFF" # Default to OFF

    if [ -n "$CURRENT_PROFILES_VALUE" ] && [ "$CURRENT_PROFILES_VALUE" != '""' ]; then # Check if .env has profiles
        if [[ "$tag" == "ollama" ]]; then
            if [[ "$current_profiles_for_matching" == *",cpu,"* || \
                  "$current_profiles_for_matching" == *",gpu-nvidia,"* || \
                  "$current_profiles_for_matching" == *",gpu-amd,"* ]]; then
                status="ON"
            fi
        elif [[ "$tag" == "desktop" ]]; then
            if [[ "$current_profiles_for_matching" == *",desktop-ubuntu,"* || \
                  "$current_profiles_for_matching" == *",desktop-kde,"* || \
                  "$current_profiles_for_matching" == *",desktop-xfce,"* || \
                  "$current_profiles_for_matching" == *",desktop-mate,"* || \
                  "$current_profiles_for_matching" == *",desktop-fedora-kde,"* || \
                  "$current_profiles_for_matching" == *",desktop-alpine,"* ]]; then
                status="ON"
            fi
        elif [[ "$current_profiles_for_matching" == *",$tag,"* ]]; then
            status="ON"
        fi
    else
        # .env has no COMPOSE_PROFILES or it's empty/just quotes, use hardcoded defaults
        case "$tag" in
            "n8n"|"flowise"|"monitoring") status="ON" ;;
            *) status="OFF" ;;
        esac
    fi
    services+=("$tag" "$description" "$status")
    idx=$((idx + 2))
done

# Use whiptail to display the checklist
CHOICES=$(whiptail --title "Service Selection Wizard" --checklist \
  "Choose the services you want to deploy.\nUse ARROW KEYS to navigate, SPACEBAR to select/deselect, ENTER to confirm." 22 78 10 \
  "${services[@]}" \
  3>&1 1>&2 2>&3)

# Restore original DEBIAN_FRONTEND
if [ -n "$ORIGINAL_DEBIAN_FRONTEND" ]; then
  export DEBIAN_FRONTEND="$ORIGINAL_DEBIAN_FRONTEND"
else
  unset DEBIAN_FRONTEND
fi

# Exit if user pressed Cancel or Esc
exitstatus=$?
if [ $exitstatus -ne 0 ]; then
    log_info "Service selection cancelled by user. Exiting wizard."
    log_info "No changes made to service profiles. Default services will be used."
    # Set COMPOSE_PROFILES to empty to ensure only core services run
    if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
    fi
    if grep -q "^COMPOSE_PROFILES=" "$ENV_FILE"; then
        sed -i.bak "/^COMPOSE_PROFILES=/d" "$ENV_FILE"
    fi
    echo "COMPOSE_PROFILES=" >> "$ENV_FILE"
    exit 0
fi

# Process selected services
selected_profiles=()
ollama_selected=0
ollama_profile=""
desktop_selected=0
desktop_profile=""

if [ -n "$CHOICES" ]; then
    # Whiptail returns a string like "tag1" "tag2" "tag3"
    # We need to remove quotes and convert to an array
    temp_choices=()
    eval "temp_choices=($CHOICES)"

    for choice in "${temp_choices[@]}"; do
        if [ "$choice" == "ollama" ]; then
            ollama_selected=1
        elif [ "$choice" == "desktop" ]; then
            desktop_selected=1
        else
            selected_profiles+=("$choice")
        fi
    done
fi

# If Ollama was selected, prompt for the hardware profile
if [ $ollama_selected -eq 1 ]; then
    # Determine default selected Ollama hardware profile from .env
    default_ollama_hardware="cpu" # Fallback default
    ollama_hw_on_cpu="OFF"
    ollama_hw_on_gpu_nvidia="OFF"
    ollama_hw_on_gpu_amd="OFF"

    # Check current_profiles_for_matching which includes commas, e.g., ",cpu,"
    if [[ "$current_profiles_for_matching" == *",cpu,"* ]]; then
        ollama_hw_on_cpu="ON"
        default_ollama_hardware="cpu"
    elif [[ "$current_profiles_for_matching" == *",gpu-nvidia,"* ]]; then
        ollama_hw_on_gpu_nvidia="ON"
        default_ollama_hardware="gpu-nvidia"
    elif [[ "$current_profiles_for_matching" == *",gpu-amd,"* ]]; then
        ollama_hw_on_gpu_amd="ON"
        default_ollama_hardware="gpu-amd"
    else
        # If ollama was selected in the main list, but no specific hardware profile was previously set,
        # default to CPU ON for the radiolist.
        ollama_hw_on_cpu="ON"
        default_ollama_hardware="cpu"
    fi

    ollama_hardware_options=(
        "cpu" "CPU (Recommended for most users)" "$ollama_hw_on_cpu"
        "gpu-nvidia" "NVIDIA GPU (Requires NVIDIA drivers & CUDA)" "$ollama_hw_on_gpu_nvidia"
        "gpu-amd" "AMD GPU (Requires ROCm drivers)" "$ollama_hw_on_gpu_amd"
    )
    CHOSEN_OLLAMA_PROFILE=$(whiptail --title "Ollama Hardware Profile" --default-item "$default_ollama_hardware" --radiolist \
      "Choose the hardware profile for Ollama. This will be added to your Docker Compose profiles." 15 78 3 \
      "${ollama_hardware_options[@]}" \
      3>&1 1>&2 2>&3)

    ollama_exitstatus=$?
    if [ $ollama_exitstatus -eq 0 ] && [ -n "$CHOSEN_OLLAMA_PROFILE" ]; then
        selected_profiles+=("$CHOSEN_OLLAMA_PROFILE")
        ollama_profile="$CHOSEN_OLLAMA_PROFILE" # Store for user message
        log_info "Ollama hardware profile selected: $CHOSEN_OLLAMA_PROFILE"
    else
        log_info "Ollama hardware profile selection cancelled or no choice made. Ollama will not be configured with a specific hardware profile."
        # ollama_selected remains 1, but no specific profile is added.
        # This means "ollama" won't be in COMPOSE_PROFILES unless a hardware profile is chosen.
        ollama_selected=0 # Mark as not fully selected if profile choice is cancelled
    fi
fi

# Desktop-Varianten-Auswahl (ähnlich wie Ollama Hardware-Auswahl)
if [ $desktop_selected -eq 1 ]; then
    # Bestehende Desktop-Profile aus .env ermitteln
    default_desktop="desktop-ubuntu" # Fallback default
    desktop_ubuntu_on="OFF"
    desktop_kde_on="OFF"
    desktop_xfce_on="OFF"
    desktop_mate_on="OFF"
    desktop_fedora_kde_on="OFF"
    desktop_alpine_on="OFF"

    # Prüfe aktuelle Profile in .env
    if [[ "$current_profiles_for_matching" == *",desktop-ubuntu,"* ]]; then
        desktop_ubuntu_on="ON"
        default_desktop="desktop-ubuntu"
    elif [[ "$current_profiles_for_matching" == *",desktop-kde,"* ]]; then
        desktop_kde_on="ON"
        default_desktop="desktop-kde"
    elif [[ "$current_profiles_for_matching" == *",desktop-xfce,"* ]]; then
        desktop_xfce_on="ON"
        default_desktop="desktop-xfce"
    elif [[ "$current_profiles_for_matching" == *",desktop-mate,"* ]]; then
        desktop_mate_on="ON"
        default_desktop="desktop-mate"
    elif [[ "$current_profiles_for_matching" == *",desktop-fedora-kde,"* ]]; then
        desktop_fedora_kde_on="ON"
        default_desktop="desktop-fedora-kde"
    elif [[ "$current_profiles_for_matching" == *",desktop-alpine,"* ]]; then
        desktop_alpine_on="ON"
        default_desktop="desktop-alpine"
    else
        # Wenn Desktop gewählt wurde, aber kein spezifisches Profil gesetzt war
        desktop_ubuntu_on="ON"
        default_desktop="desktop-ubuntu"
    fi

    desktop_variant_options=(
        "desktop-ubuntu" "Ubuntu Desktop (Standard RDP - Lightweight)" "$desktop_ubuntu_on"
        "desktop-kde" "KDE Plasma Desktop (Modern, Full-featured)" "$desktop_kde_on"
        "desktop-xfce" "XFCE Desktop (Fast, Traditional)" "$desktop_xfce_on"
        "desktop-mate" "MATE Desktop (Windows-like, User-friendly)" "$desktop_mate_on"
        "desktop-fedora-kde" "Fedora KDE Desktop (Latest packages)" "$desktop_fedora_kde_on"
        "desktop-alpine" "Alpine KDE Desktop (Minimal, Secure)" "$desktop_alpine_on"
    )

    CHOSEN_DESKTOP_PROFILE=$(whiptail --title "Desktop Environment Selection" --default-item "$default_desktop" --radiolist \
      "Choose your preferred desktop environment. Each provides different user experiences and resource usage." 20 78 6 \
      "${desktop_variant_options[@]}" \
      3>&1 1>&2 2>&3)

    desktop_exitstatus=$?
    if [ $desktop_exitstatus -eq 0 ] && [ -n "$CHOSEN_DESKTOP_PROFILE" ]; then
        selected_profiles+=("$CHOSEN_DESKTOP_PROFILE")
        desktop_profile="$CHOSEN_DESKTOP_PROFILE"

        # Desktop-Profil-spezifische Informationen anzeigen
        case "$CHOSEN_DESKTOP_PROFILE" in
            "desktop-ubuntu")
                log_info "Ubuntu Desktop selected: Traditional RDP connection, lightweight"
                ;;
            "desktop-kde")
                log_info "KDE Plasma Desktop selected: Modern interface, high resource usage"
                ;;
            "desktop-xfce")
                log_info "XFCE Desktop selected: Fast and responsive, moderate resource usage"
                ;;
            "desktop-mate")
                log_info "MATE Desktop selected: Windows-like interface, user-friendly"
                ;;
            "desktop-fedora-kde")
                log_info "Fedora KDE Desktop selected: Latest packages, cutting-edge features"
                ;;
            "desktop-alpine")
                log_info "Alpine KDE Desktop selected: Minimal footprint, maximum security"
                ;;
        esac
    else
        log_info "Desktop environment selection cancelled. No desktop service will be configured."
        desktop_selected=0
    fi
fi

# Erweiterte Anzeige der ausgewählten Services
if [ ${#selected_profiles[@]} -eq 0 ]; then
    log_info "No optional services selected."
    COMPOSE_PROFILES_VALUE=""
else
    log_info "You have selected the following service profiles to be deployed:"
    COMPOSE_PROFILES_VALUE=$(IFS=,; echo "${selected_profiles[*]}")

    for profile in "${selected_profiles[@]}"; do
        case "$profile" in
            # Ollama Hardware-Profile
            "cpu"|"gpu-nvidia"|"gpu-amd")
                if [ "$profile" == "$ollama_profile" ]; then
                    echo "  - Ollama ($profile profile)"
                else
                    echo "  - $profile"
                fi
                ;;
            # Desktop-Profile
            "desktop-ubuntu")
                echo "  - Ubuntu Desktop (RDP-based, lightweight)"
                ;;
            "desktop-kde")
                echo "  - KDE Plasma Desktop (modern, full-featured)"
                ;;
            "desktop-xfce")
                echo "  - XFCE Desktop (fast, traditional)"
                ;;
            "desktop-mate")
                echo "  - MATE Desktop (Windows-like)"
                ;;
            "desktop-fedora-kde")
                echo "  - Fedora KDE Desktop (latest packages)"
                ;;
            "desktop-alpine")
                echo "  - Alpine KDE Desktop (minimal, secure)"
                ;;
            # Standard-Services
            *)
                echo "  - $profile"
                ;;
        esac
    done
fi

# Update or add COMPOSE_PROFILES in .env file
# Ensure .env file exists (it should have been created by 03_generate_secrets.sh or exist from previous run)
if [ ! -f "$ENV_FILE" ]; then
    log_warning "'.env' file not found at $ENV_FILE. Creating it."
    touch "$ENV_FILE"
fi

# Remove existing COMPOSE_PROFILES line if it exists
if grep -q "^COMPOSE_PROFILES=" "$ENV_FILE"; then
    # Using a different delimiter for sed because a profile name might contain '/' (unlikely here)
    sed -i.bak "\|^COMPOSE_PROFILES=|d" "$ENV_FILE"
fi

# Add the new COMPOSE_PROFILES line
echo "COMPOSE_PROFILES=${COMPOSE_PROFILES_VALUE}" >> "$ENV_FILE"
log_info "COMPOSE_PROFILES has been set in '$ENV_FILE'."
if [ -z "$COMPOSE_PROFILES_VALUE" ]; then
    log_info "Only core services (Caddy, Postgres, Redis) will be started."
else
    log_info "The following Docker Compose profiles will be active: ${COMPOSE_PROFILES_VALUE}"
fi

# Make the script executable (though install.sh calls it with bash)
chmod +x "$SCRIPT_DIR/04_wizard.sh"

exit 0
