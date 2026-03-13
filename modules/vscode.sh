#!/usr/bin/env bash

# VS Code extensions installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

install_vscode_extensions() {
    logg "${COLOR_GREEN}" "Installing VS Code extensions..."
    
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    if [[ -d "${DOTFILES_DIR}/vscode" ]] && [[ -f "${DOTFILES_DIR}/vscode/extensions.sh" ]]; then
        if execute_command "cd '${DOTFILES_DIR}/vscode' && bash extensions.sh" "VS Code extensions installation"; then
            logg "${COLOR_GREEN}" "✓ VS Code extensions installed successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to install VS Code extensions"
        fi
    else
        logg "${COLOR_YELLOW}" "vscode/extensions.sh not found, skipping..."
    fi
}

main() {
    install_vscode_extensions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
