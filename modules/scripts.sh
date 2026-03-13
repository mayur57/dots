#!/usr/bin/env bash

# Custom scripts building and installation module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

ZSHRC_FILE="$HOME/.zshrc"

install_custom_scripts() {
    logg "${COLOR_GREEN}" "Building and installing custom scripts..."
    
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "${LOCAL_BIN}"
    
    # Add to PATH if not already there
    if ! grep -q 'export PATH.*\.local/bin' "${ZSHRC_FILE}" 2>/dev/null; then
        execute_silent "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> '${ZSHRC_FILE}'"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    script_count=0
    failed_count=0
    
    # Build Go scripts
    if command -v go &>/dev/null; then
        for go_file in "${DOTFILES_DIR}/scripts"/*.go; do
            if [[ -f "$go_file" ]]; then
                script_name=$(basename "$go_file" .go)
                logg "${COLOR_GREEN}" "Building ${script_name}..."
                if execute_command "go build -o '${LOCAL_BIN}/${script_name}' '$go_file'" "Build ${script_name}"; then
                    logg "${COLOR_GREEN}" "✓ ${script_name} built and installed successfully"
                    ((script_count++))
                else
                    logg "${COLOR_RED}" "✗ Failed to build ${script_name}"
                    ((failed_count++))
                fi
            fi
        done
    else
        logg "${COLOR_YELLOW}" "Go not available, skipping Go script builds..."
    fi
    
    # Copy pre-built binaries if they exist
    if [[ -d "${DOTFILES_DIR}/scripts/bin" ]]; then
        for bin_file in "${DOTFILES_DIR}/scripts/bin"/*; do
            if [[ -f "$bin_file" ]] && [[ -x "$bin_file" ]]; then
                bin_name=$(basename "$bin_file")
                logg "${COLOR_GREEN}" "Installing ${bin_name}..."
                if execute_command "cp '$bin_file' '${LOCAL_BIN}/${bin_name}'" "Install ${bin_name}"; then
                    logg "${COLOR_GREEN}" "✓ ${bin_name} installed successfully"
                    ((script_count++))
                else
                    logg "${COLOR_RED}" "✗ Failed to install ${bin_name}"
                    ((failed_count++))
                fi
            fi
        done
    fi
    
    if [[ ${script_count} -gt 0 ]]; then
        logg "${COLOR_GREEN}" "✓ Custom scripts installation completed (${script_count} scripts)"
    elif [[ ${failed_count} -gt 0 ]]; then
        logg "${COLOR_RED}" "✗ Some scripts failed to install"
    else
        logg "${COLOR_YELLOW}" "No scripts found to install"
    fi
}

main() {
    install_custom_scripts
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
