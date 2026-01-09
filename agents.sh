#!/usr/bin/env bash

# Exit immediately at script failure point
set -eo pipefail

ERROR_LOG="setup_error.log"
exec 2>>"${ERROR_LOG}"
trap 'logg "${COLOR_RED}" "An error occurred. Check ${ERROR_LOG} for details." && exit 1' ERR

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_NORMAL="\033[0;39m"

logg() {
    local color="$1"
    local message="$2"
    printf "\n${color}${message}${COLOR_NORMAL}\n"
}

execute_command() {
    local command="$1"
    logg "${COLOR_MAGENTA}" "Executing: ${command}"
    if ! eval "${command}"; then
        logg "${COLOR_RED}" "Command failed: ${command}"
        return 1
    fi
}

# Check for internet connection
if ! ping -c 1 google.com &>/dev/null; then
    logg "${COLOR_RED}" "No internet connection detected. Please check your network."
    exit 1
fi

logg "${COLOR_BLUE}" "Installing and setting up AI coding tools..."

# Check for Node.js
logg "${COLOR_GREEN}" "Checking for Node.js..."
if ! command -v node &>/dev/null; then
    logg "${COLOR_YELLOW}" "Node.js not found. Checking for NVM..."
    
    # Try to source NVM if it exists
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        logg "${COLOR_MAGENTA}" "Loading NVM..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command -v nvm &>/dev/null; then
            logg "${COLOR_MAGENTA}" "Installing Node.js LTS via NVM..."
            if execute_command "nvm install --lts"; then
                logg "${COLOR_GREEN}" "✓ Node.js LTS installed successfully"
                execute_command "nvm use --lts"
            else
                logg "${COLOR_RED}" "✗ Failed to install Node.js via NVM"
                exit 1
            fi
        else
            logg "${COLOR_RED}" "NVM is not available. Please install Node.js manually or install NVM first."
            exit 1
        fi
    else
        logg "${COLOR_RED}" "Node.js is required but not found. Please install Node.js 18+ or NVM first."
        logg "${COLOR_YELLOW}" "You can install NVM by running: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash"
        exit 1
    fi
else
    node_version=$(node --version)
    logg "${COLOR_GREEN}" "✓ Node.js is already installed (${node_version})"
    
    # Check if version is 18 or higher
    major_version=$(node --version | sed 's/v\([0-9]*\).*/\1/')
    if [[ $major_version -lt 18 ]]; then
        logg "${COLOR_YELLOW}" "Node.js version ${node_version} is below 18. Claude Code requires Node.js 18+. Please upgrade."
        exit 1
    fi
fi

# Check for npm
if ! command -v npm &>/dev/null; then
    logg "${COLOR_RED}" "npm is not available. Please install npm."
    exit 1
fi

# Install Claude Code Terminal
logg "${COLOR_GREEN}" "Installing Claude Code Terminal..."
if command -v claude &>/dev/null; then
    claude_version=$(claude --version 2>/dev/null || echo "unknown")
    logg "${COLOR_YELLOW}" "Claude Code is already installed (${claude_version}), skipping..."
else
    logg "${COLOR_MAGENTA}" "Installing @anthropic-ai/claude-code via npm..."
    if execute_command "npm install -g @anthropic-ai/claude-code"; then
        logg "${COLOR_GREEN}" "✓ Claude Code Terminal installed successfully"
        
        # Verify installation
        if command -v claude &>/dev/null; then
            claude_version=$(claude --version 2>/dev/null || echo "unknown")
            logg "${COLOR_GREEN}" "✓ Claude Code verified (${claude_version})"
            logg "${COLOR_YELLOW}" "Note: Run 'claude auth' to authenticate with your Anthropic account"
        else
            logg "${COLOR_YELLOW}" "⚠ Claude Code installed but 'claude' command not found in PATH"
        fi
    else
        logg "${COLOR_RED}" "✗ Failed to install Claude Code Terminal"
        exit 1
    fi
fi

# Install Gemini Code Agent Tool
logg "${COLOR_GREEN}" "Installing Gemini Code Agent Tool..."

GEMINI_CLI_DIR="$HOME/.gemini-cli"
GEMINI_REPO_URL="https://github.com/google-gemini/gemini-cli.git"

if [[ -d "${GEMINI_CLI_DIR}" ]]; then
    logg "${COLOR_YELLOW}" "Gemini CLI directory already exists at ${GEMINI_CLI_DIR}"
    logg "${COLOR_MAGENTA}" "Updating Gemini CLI..."
    cd "${GEMINI_CLI_DIR}"
    if execute_command "git pull"; then
        logg "${COLOR_GREEN}" "✓ Gemini CLI updated successfully"
    else
        logg "${COLOR_YELLOW}" "⚠ Failed to update Gemini CLI, continuing with existing version..."
    fi
    cd - > /dev/null
else
    logg "${COLOR_MAGENTA}" "Cloning Gemini CLI repository..."
    if execute_command "git clone ${GEMINI_REPO_URL} ${GEMINI_CLI_DIR}"; then
        logg "${COLOR_GREEN}" "✓ Gemini CLI repository cloned successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to clone Gemini CLI repository"
        exit 1
    fi
fi

# Check if we need to build or setup Gemini CLI
if [[ -f "${GEMINI_CLI_DIR}/package.json" ]]; then
    logg "${COLOR_MAGENTA}" "Installing Gemini CLI dependencies..."
    cd "${GEMINI_CLI_DIR}"
    if execute_command "npm install"; then
        logg "${COLOR_GREEN}" "✓ Gemini CLI dependencies installed successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to install Gemini CLI dependencies"
        exit 1
    fi
    cd - > /dev/null
fi

# Create symlink or add to PATH
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "${LOCAL_BIN}"

# Check for gemini executable
GEMINI_BIN=""
if [[ -f "${GEMINI_CLI_DIR}/bin/gemini" ]]; then
    GEMINI_BIN="${GEMINI_CLI_DIR}/bin/gemini"
elif [[ -f "${GEMINI_CLI_DIR}/gemini" ]]; then
    GEMINI_BIN="${GEMINI_CLI_DIR}/gemini"
elif command -v gemini &>/dev/null; then
    logg "${COLOR_GREEN}" "✓ Gemini CLI is already available in PATH"
    GEMINI_BIN=""
fi

if [[ -n "${GEMINI_BIN}" ]]; then
    logg "${COLOR_MAGENTA}" "Creating symlink for Gemini CLI..."
    if ln -sf "${GEMINI_BIN}" "${LOCAL_BIN}/gemini"; then
        logg "${COLOR_GREEN}" "✓ Gemini CLI symlink created successfully"
    else
        logg "${COLOR_YELLOW}" "⚠ Failed to create symlink, you may need to add ${GEMINI_CLI_DIR} to your PATH"
    fi
fi

# Add to PATH if not already there
ZSHRC_FILE="$HOME/.zshrc"
if ! grep -q 'export PATH.*\.local/bin' "${ZSHRC_FILE}" 2>/dev/null; then
    logg "${COLOR_MAGENTA}" "Adding ~/.local/bin to PATH in .zshrc..."
    echo '' >> "${ZSHRC_FILE}"
    echo '# Add local bin to PATH' >> "${ZSHRC_FILE}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${ZSHRC_FILE}"
    export PATH="$HOME/.local/bin:$PATH"
    logg "${COLOR_GREEN}" "✓ PATH updated in .zshrc"
fi

# Create Gemini settings directory if it doesn't exist
GEMINI_SETTINGS_DIR="$HOME/.gemini"
if [[ ! -d "${GEMINI_SETTINGS_DIR}" ]]; then
    logg "${COLOR_MAGENTA}" "Creating Gemini settings directory..."
    mkdir -p "${GEMINI_SETTINGS_DIR}"
    logg "${COLOR_GREEN}" "✓ Gemini settings directory created"
fi

logg "${COLOR_GREEN}" "✓ AI coding tools installation completed!"
logg "${COLOR_BLUE}" ""
logg "${COLOR_BLUE}" "Next steps:"
logg "${COLOR_YELLOW}" "1. For Claude Code: Run 'claude auth' to authenticate with your Anthropic account"
logg "${COLOR_YELLOW}" "2. For Gemini CLI: Run 'gemini' to start using the tool (it will guide you through authentication)"
logg "${COLOR_YELLOW}" "3. Restart your terminal or run 'source ~/.zshrc' to load updated PATH"
logg "${COLOR_BLUE}" ""

