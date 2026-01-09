#!/usr/bin/env bash

# Git configuration module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

configure_git() {
    logg "${COLOR_GREEN}" "Configuring git..."
    
    # Get current git config or use defaults
    current_name=$(git config --global user.name 2>/dev/null || echo "Mayur Bhoi")
    current_email=$(git config --global user.email 2>/dev/null || echo "mayur072000@gmail.com")
    
    git_name="${current_name}"
    git_email="${current_email}"
    default_branch="main"
    git_editor="code --wait"
    
    logg "${COLOR_GREEN}" "Configuring git with:"
    logg "${COLOR_BLUE}" "  Name: ${git_name}"
    logg "${COLOR_BLUE}" "  Email: ${git_email}"
    logg "${COLOR_BLUE}" "  Default branch: ${default_branch}"
    logg "${COLOR_BLUE}" "  Editor: ${git_editor}"
    
    if execute_command "git config --global user.name '${git_name}' && git config --global user.email '${git_email}' && git config --global init.defaultBranch '${default_branch}' && git config --global core.editor '${git_editor}'" "Git configuration"; then
        logg "${COLOR_GREEN}" "✓ Git configured successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to configure git"
        return 1
    fi
}

main() {
    configure_git
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
