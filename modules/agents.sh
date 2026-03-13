#!/usr/bin/env bash

# AI coding tools installation module (Claude Code, Gemini CLI)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

ZSHRC_FILE="$HOME/.zshrc"

install_claude_code() {
    logg "${COLOR_GREEN}" "Installing Claude Code Terminal..."
    
    # Check for Node.js
    if ! command -v node &>/dev/null; then
        logg "${COLOR_YELLOW}" "Node.js not found. Checking for NVM..."
        
        # Try to source NVM if it exists
        if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            logg "${COLOR_GREEN}" "Loading NVM..."
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            if command -v nvm &>/dev/null; then
                logg "${COLOR_GREEN}" "Installing Node.js LTS via NVM..."
                if execute_command "nvm install --lts" "Node.js LTS installation"; then
                    execute_silent "nvm use --lts"
                else
                    logg "${COLOR_RED}" "✗ Failed to install Node.js via NVM"
                    return 1
                fi
            else
                logg "${COLOR_RED}" "NVM is not available. Please install Node.js manually or install NVM first."
                return 1
            fi
        else
            logg "${COLOR_RED}" "Node.js is required but not found. Please install Node.js 18+ or NVM first."
            return 1
        fi
    else
        node_version=$(node --version 2>&1)
        logg "${COLOR_GREEN}" "✓ Node.js is already installed (${node_version})"
        
        # Check if version is 18 or higher
        major_version=$(node --version | sed 's/v\([0-9]*\).*/\1/')
        if [[ $major_version -lt 18 ]]; then
            logg "${COLOR_YELLOW}" "Node.js version ${node_version} is below 18. Claude Code requires Node.js 18+. Please upgrade."
            return 1
        fi
    fi
    
    # Check for npm
    if ! command -v npm &>/dev/null; then
        logg "${COLOR_RED}" "npm is not available. Please install npm."
        return 1
    fi
    
    if command -v claude &>/dev/null; then
        claude_version=$(claude --version 2>/dev/null || echo "unknown")
        logg "${COLOR_GREEN}" "✓ Claude Code is already installed (${claude_version})"
    else
        logg "${COLOR_GREEN}" "Installing Claude Code..."
        if execute_command "npm install -g @anthropic-ai/claude-code" "Claude Code installation"; then
            logg "${COLOR_GREEN}" "✓ Claude Code Terminal installed successfully"
            
            # Verify installation
            if command -v claude &>/dev/null; then
                claude_version=$(claude --version 2>/dev/null || echo "unknown")
                logg "${COLOR_GREEN}" "✓ Claude Code verified (${claude_version})"
            fi
        else
            logg "${COLOR_RED}" "✗ Failed to install Claude Code Terminal"
            return 1
        fi
    fi
}

install_gemini_cli() {
    logg "${COLOR_GREEN}" "Installing Gemini Code Agent Tool..."
    
    GEMINI_CLI_DIR="$HOME/.gemini-cli"
    GEMINI_REPO_URL="https://github.com/google-gemini/gemini-cli.git"
    LOCAL_BIN="$HOME/.local/bin"
    
    if [[ -d "${GEMINI_CLI_DIR}" ]]; then
        logg "${COLOR_GREEN}" "Updating Gemini CLI..."
        if execute_command "cd '${GEMINI_CLI_DIR}' && git pull" "Update Gemini CLI"; then
            logg "${COLOR_GREEN}" "✓ Gemini CLI updated successfully"
        else
            logg "${COLOR_YELLOW}" "⚠ Failed to update Gemini CLI, continuing with existing version..."
        fi
    else
        logg "${COLOR_GREEN}" "Cloning Gemini CLI repository..."
        if execute_command "git clone '${GEMINI_REPO_URL}' '${GEMINI_CLI_DIR}'" "Clone Gemini CLI"; then
            logg "${COLOR_GREEN}" "✓ Gemini CLI repository cloned successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to clone Gemini CLI repository"
            return 1
        fi
    fi
    
    # Check if we need to build or setup Gemini CLI
    if [[ -f "${GEMINI_CLI_DIR}/package.json" ]]; then
        logg "${COLOR_GREEN}" "Installing Gemini CLI dependencies..."
        if execute_command "cd '${GEMINI_CLI_DIR}' && npm install" "Install Gemini CLI dependencies"; then
            logg "${COLOR_GREEN}" "✓ Gemini CLI dependencies installed successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to install Gemini CLI dependencies"
            return 1
        fi
    fi
    
    # Create symlink or add to PATH
    mkdir -p "${LOCAL_BIN}"
    
    # Check for gemini executable - try multiple locations based on package.json bin
    GEMINI_BIN=""
    
    # Check package.json for bin location
    if [[ -f "${GEMINI_CLI_DIR}/package.json" ]]; then
        # Try to get bin path from package.json (usually "bundle/gemini.js")
        BIN_PATH=$(grep -A 2 '"bin"' "${GEMINI_CLI_DIR}/package.json" | grep -o '"[^"]*"' | head -1 | tr -d '"')
        if [[ -n "${BIN_PATH}" ]] && [[ -f "${GEMINI_CLI_DIR}/${BIN_PATH}" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/${BIN_PATH}"
        fi
    fi
    
    # Try common locations if not found via package.json
    if [[ -z "${GEMINI_BIN}" ]]; then
        if [[ -f "${GEMINI_CLI_DIR}/bundle/gemini.js" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/bundle/gemini.js"
        elif [[ -f "${GEMINI_CLI_DIR}/bin/gemini" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/bin/gemini"
        elif [[ -f "${GEMINI_CLI_DIR}/dist/bin/gemini" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/dist/bin/gemini"
        elif [[ -f "${GEMINI_CLI_DIR}/gemini" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/gemini"
        elif [[ -f "${GEMINI_CLI_DIR}/node_modules/.bin/gemini" ]]; then
            GEMINI_BIN="${GEMINI_CLI_DIR}/node_modules/.bin/gemini"
        elif command -v gemini &>/dev/null; then
            logg "${COLOR_GREEN}" "✓ Gemini CLI is already available in PATH"
            GEMINI_BIN=""
        fi
    fi
    
    # Create wrapper script if we found a node.js file
    if [[ -n "${GEMINI_BIN}" ]] && [[ -f "${GEMINI_BIN}" ]]; then
        if [[ "${GEMINI_BIN}" == *.js ]]; then
            # It's a Node.js script, create a wrapper
            logg "${COLOR_GREEN}" "Creating wrapper script for Gemini CLI..."
            cat > "${LOCAL_BIN}/gemini" << GEMINI_WRAPPER
#!/usr/bin/env bash
cd "${GEMINI_CLI_DIR}" && node "${GEMINI_BIN}" "\$@"
GEMINI_WRAPPER
            chmod +x "${LOCAL_BIN}/gemini"
            logg "${COLOR_GREEN}" "✓ Gemini CLI wrapper created successfully"
        else
            # It's an executable, create symlink
            logg "${COLOR_GREEN}" "Creating symlink for Gemini CLI..."
            if execute_command "ln -sf '${GEMINI_BIN}' '${LOCAL_BIN}/gemini'" "Create Gemini CLI symlink"; then
                logg "${COLOR_GREEN}" "✓ Gemini CLI symlink created successfully"
            fi
        fi
    else
        logg "${COLOR_YELLOW}" "⚠ Could not find Gemini CLI executable. You may need to build it manually."
    fi
    
    # Add to PATH if not already there (handled by scripts module, but ensure it's there)
    if ! grep -q 'export PATH.*\.local/bin' "${ZSHRC_FILE}" 2>/dev/null; then
        execute_silent "echo '' >> '${ZSHRC_FILE}' && echo '# Add local bin to PATH' >> '${ZSHRC_FILE}' && echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> '${ZSHRC_FILE}'"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Create Gemini settings directory if it doesn't exist
    GEMINI_SETTINGS_DIR="$HOME/.gemini"
    if [[ ! -d "${GEMINI_SETTINGS_DIR}" ]]; then
        logg "${COLOR_GREEN}" "Creating Gemini settings directory..."
        execute_silent "mkdir -p '${GEMINI_SETTINGS_DIR}'"
        logg "${COLOR_GREEN}" "✓ Gemini settings directory created"
    fi
}

main() {
    check_internet || exit 1
    
    install_claude_code
    install_gemini_cli
    
    logg "${COLOR_GREEN}" "✓ AI coding tools installation completed"
    logg "${COLOR_YELLOW}" "Note: Run 'claude auth' to authenticate Claude Code"
    logg "${COLOR_YELLOW}" "Note: Run 'gemini' to start using Gemini CLI"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
