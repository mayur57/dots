#!/usr/bin/env bash

# System configuration module (architecture-specific settings)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

configure_system() {
    logg "${COLOR_GREEN}" "Configuring system settings..."
    
    SYSTEM_ARCH=$(get_system_arch)
    logg "${COLOR_GREEN}" "Detected system architecture: ${SYSTEM_ARCH}"
    
    if [[ ${SYSTEM_ARCH} == "arm64" ]]; then
        logg "${COLOR_GREEN}" "Configuring for Apple Silicon (arm64)..."
        if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null; then
            if execute_command "echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile && eval \"\$(/opt/homebrew/bin/brew shellenv)\"" "Apple Silicon configuration"; then
                logg "${COLOR_GREEN}" "✓ Apple Silicon configuration completed"
            else
                logg "${COLOR_RED}" "✗ Failed to configure Apple Silicon settings"
            fi
        else
            logg "${COLOR_GREEN}" "✓ Apple Silicon configuration already present"
        fi
    else
        logg "${COLOR_GREEN}" "Configuring for Intel (x86_64)..."
        logg "${COLOR_GREEN}" "✓ Intel configuration completed"
    fi
}

main() {
    configure_system
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
