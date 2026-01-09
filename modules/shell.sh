#!/usr/bin/env bash

# Shell configuration module (Oh My Zsh, .zshrc, aliases)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

install_oh_my_zsh() {
    logg "${COLOR_GREEN}" "Installing Oh My Zsh..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        if execute_command "sh -c '\$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)'" "Oh My Zsh installation"; then
            logg "${COLOR_GREEN}" "✓ Oh My Zsh installed successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to install Oh My Zsh"
            return 1
        fi
    else
        logg "${COLOR_GREEN}" "✓ Oh My Zsh is already installed"
    fi
    return 0
}

setup_zshrc() {
    logg "${COLOR_GREEN}" "Setting up .zshrc..."
    ZSHRC_FILE="$HOME/.zshrc"
    
    if [[ -f ${ZSHRC_FILE} ]]; then
        logg "${COLOR_GREEN}" "Backing up existing .zshrc..."
        if execute_command "cp '${ZSHRC_FILE}' '${ZSHRC_FILE}.bak'" "Backup .zshrc"; then
            logg "${COLOR_GREEN}" "✓ Backup created successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to create backup"
        fi
    fi
    
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    if [[ -f "${DOTFILES_DIR}/.zshrc" ]]; then
        if execute_command "cp '${DOTFILES_DIR}/.zshrc' ~/.zshrc" "Copy .zshrc"; then
            logg "${COLOR_GREEN}" "✓ .zshrc configured successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to copy .zshrc"
        fi
    else
        logg "${COLOR_YELLOW}" ".zshrc not found in dotfiles directory, skipping..."
    fi
}

setup_aliases() {
    logg "${COLOR_GREEN}" "Configuring aliases..."
    ZSHRC_FILE="$HOME/.zshrc"
    DOTFILES_DIR="${SCRIPT_DIR}/.."
    
    if [[ -f "${DOTFILES_DIR}/.aliases" ]]; then
        # Copy .aliases to home directory
        if execute_command "cp '${DOTFILES_DIR}/.aliases' ~/.aliases" "Copy .aliases"; then
            logg "${COLOR_GREEN}" "✓ .aliases copied to home directory"
        else
            logg "${COLOR_RED}" "✗ Failed to copy .aliases"
            return 1
        fi
        
        # Check if aliases are already sourced in .zshrc
        if ! grep -q "source.*\.aliases" "${ZSHRC_FILE}" 2>/dev/null; then
            logg "${COLOR_GREEN}" "Adding aliases to .zshrc..."
            if execute_command "echo '' >> '${ZSHRC_FILE}' && echo '# Source custom aliases' >> '${ZSHRC_FILE}' && echo 'source ~/.aliases' >> '${ZSHRC_FILE}'" "Configure aliases in .zshrc"; then
                logg "${COLOR_GREEN}" "✓ Aliases configured successfully"
            else
                logg "${COLOR_RED}" "✗ Failed to configure aliases"
            fi
        else
            logg "${COLOR_GREEN}" "✓ Aliases already configured in .zshrc"
        fi
    else
        logg "${COLOR_YELLOW}" ".aliases not found in dotfiles directory, skipping..."
    fi
}

main() {
    check_internet || exit 1
    
    install_oh_my_zsh || exit 1
    setup_zshrc
    setup_aliases
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
