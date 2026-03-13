#!/usr/bin/env bash

# Fonts installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

install_fonts() {
    logg "${COLOR_GREEN}" "Installing fonts..."
    
    FONT_DIR="$HOME/Library/Fonts"
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    mkdir -p "${FONT_DIR}"
    
    if [[ -d "${DOTFILES_DIR}/fonts" ]]; then
        font_count=$(find "${DOTFILES_DIR}/fonts" -type f \( -name "*.otf" -o -name "*.ttf" \) | wc -l | tr -d ' ')
        logg "${COLOR_GREEN}" "Found ${font_count} fonts to install"
        
        if execute_command "find '${DOTFILES_DIR}/fonts' -type f \\( -name '*.otf' -o -name '*.ttf' \\) -exec cp {} '${FONT_DIR}' \\;" "Font installation"; then
            logg "${COLOR_GREEN}" "✓ Fonts installed successfully (${font_count} fonts)"
        else
            logg "${COLOR_RED}" "✗ Failed to install fonts"
        fi
    else
        logg "${COLOR_YELLOW}" "Fonts directory not found, skipping..."
    fi
}

main() {
    install_fonts
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
