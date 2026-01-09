#!/usr/bin/env bash

# macOS defaults configuration module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

configure_defaults() {
    logg "${COLOR_GREEN}" "Configuring macOS defaults..."
    logg "${COLOR_MAGENTA}" "Password is required for altering some settings using sudo"
    
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    if [[ -f "${DOTFILES_DIR}/defaults.sh" ]]; then
        if execute_command "bash '${DOTFILES_DIR}/defaults.sh'" "macOS defaults configuration"; then
            logg "${COLOR_GREEN}" "✓ macOS defaults configured successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to configure macOS defaults"
            return 1
        fi
    else
        logg "${COLOR_YELLOW}" "defaults.sh not found, skipping..."
    fi
}

main() {
    configure_defaults
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
