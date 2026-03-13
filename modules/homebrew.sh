#!/usr/bin/env bash

# Homebrew installation and package management module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

install_homebrew() {
    logg "${COLOR_GREEN}" "Checking for Homebrew..."
    if ! command -v brew &>/dev/null; then
        logg "${COLOR_GREEN}" "Installing Homebrew..."
        if execute_command "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" "Homebrew installation"; then
            logg "${COLOR_GREEN}" "✓ Homebrew installed successfully"
            
            # Configure for Apple Silicon if needed
            SYSTEM_ARCH=$(get_system_arch)
            if [[ ${SYSTEM_ARCH} == "arm64" ]]; then
                logg "${COLOR_GREEN}" "Configuring Homebrew for Apple Silicon..."
                execute_silent 'eval "$(/opt/homebrew/bin/brew shellenv)"'
            fi
        else
            logg "${COLOR_RED}" "✗ Failed to install Homebrew"
            return 1
        fi
    else
        logg "${COLOR_GREEN}" "✓ Homebrew is already installed"
    fi
    return 0
}

install_brew_packages() {
    logg "${COLOR_GREEN}" "Installing essential Homebrew packages..."
    
    BREW_PACKAGES=(yarn gh jq wget tree dockutil)
    
    installed_count=0
    failed_count=0
    for package in "${BREW_PACKAGES[@]}"; do
        if ! brew list "${package}" &>/dev/null 2>&1; then
            logg "${COLOR_GREEN}" "Installing ${package}..."
            if execute_command "brew install ${package}" "Install ${package}"; then
                logg "${COLOR_GREEN}" "✓ ${package} installed successfully"
                ((installed_count++))
            else
                logg "${COLOR_RED}" "✗ Failed to install ${package}"
                ((failed_count++))
            fi
        else
            logg "${COLOR_GREEN}" "✓ ${package} is already installed"
        fi
    done
    
    if [[ ${installed_count} -gt 0 ]] || [[ ${failed_count} -eq 0 ]]; then
        logg "${COLOR_GREEN}" "✓ Homebrew packages installation completed"
    else
        logg "${COLOR_RED}" "✗ Some Homebrew packages failed to install"
    fi
}

main() {
    check_internet || exit 1
    
    install_homebrew || exit 1
    install_brew_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
