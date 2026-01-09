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

SYSTEM_ARCH=$(uname -m)
logg "${COLOR_BLUE}" "Detected system architecture: ${SYSTEM_ARCH}"

if ! ping -c 1 google.com &>/dev/null; then
    logg "${COLOR_RED}" "No internet connection detected. Please check your network."
    exit 1
fi

logg "${COLOR_GREEN}" "Checking for existing installations..."
if ! command -v brew &>/dev/null; then
    logg "${COLOR_MAGENTA}" "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        logg "${COLOR_GREEN}" "✓ Homebrew installed successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to install Homebrew. Check the output above for details."
    fi
else
    logg "${COLOR_YELLOW}" "Homebrew is already installed, skipping..."
fi

logg "${COLOR_GREEN}" "Installing essential Homebrew packages..."
BREW_PACKAGES=(yarn gh jq wget tree)
installed_count=0
failed_count=0
for package in "${BREW_PACKAGES[@]}"; do
    if ! brew list "${package}" &>/dev/null; then
        if execute_command "brew install ${package}"; then
            logg "${COLOR_GREEN}" "✓ ${package} installed successfully"
            ((installed_count++))
        else
            logg "${COLOR_RED}" "✗ Failed to install ${package}"
            ((failed_count++))
        fi
    else
        logg "${COLOR_YELLOW}" "${package} is already installed, skipping..."
    fi
done
if [[ ${installed_count} -gt 0 ]] || [[ ${failed_count} -eq 0 ]]; then
    logg "${COLOR_GREEN}" "✓ Homebrew packages installation completed"
else
    logg "${COLOR_RED}" "✗ Some Homebrew packages failed to install"
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    logg "${COLOR_MAGENTA}" "Installing Oh My Zsh..."
    if execute_command "sh -c '$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)'"; then
        logg "${COLOR_GREEN}" "✓ Oh My Zsh installed successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to install Oh My Zsh. Check the output above for details."
    fi
else
    logg "${COLOR_YELLOW}" "Oh My Zsh is already installed, skipping..."
fi

ZSHRC_FILE="$HOME/.zshrc"
if [[ -f ${ZSHRC_FILE} ]]; then
    logg "${COLOR_YELLOW}" "Backing up existing ${ZSHRC_FILE} to ${ZSHRC_FILE}.bak"
    if cp "${ZSHRC_FILE}" "${ZSHRC_FILE}.bak"; then
        logg "${COLOR_GREEN}" "✓ Backup created successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to create backup"
    fi
fi
if [[ -f "./.zshrc" ]]; then
    if execute_command "cp ./.zshrc ~/.zshrc"; then
        logg "${COLOR_GREEN}" "✓ .zshrc copied successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to copy .zshrc"
    fi
else
    logg "${COLOR_YELLOW}" ".zshrc not found in current directory, skipping..."
fi

logg "${COLOR_GREEN}" "Configuring aliases..."
if [[ -f "./.aliases" ]]; then
    # Check if aliases are already sourced in .zshrc
    if ! grep -q "source.*\.aliases" "${ZSHRC_FILE}" 2>/dev/null; then
        if echo "" >> "${ZSHRC_FILE}" && echo "# Source custom aliases" >> "${ZSHRC_FILE}" && echo "source ~/.aliases" >> "${ZSHRC_FILE}"; then
            logg "${COLOR_GREEN}" "✓ Aliases configured successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to configure aliases"
        fi
    else
        logg "${COLOR_YELLOW}" "Aliases already configured in .zshrc, skipping..."
    fi
    # Copy .aliases to home directory
    if cp "./.aliases" "${HOME}/.aliases"; then
        logg "${COLOR_GREEN}" "✓ .aliases copied to home directory"
    else
        logg "${COLOR_RED}" "✗ Failed to copy .aliases"
    fi
else
    logg "${COLOR_YELLOW}" ".aliases not found in current directory, skipping..."
fi

logg "${COLOR_GREEN}" "Installing Node Version Manager (NVM) and Node.js..."
if [[ ! -d "$HOME/.nvm" ]]; then
    if execute_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash"; then
        logg "${COLOR_GREEN}" "✓ NVM installed successfully"
        # Export NVM_DIR and source nvm.sh for current session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        logg "${COLOR_RED}" "✗ Failed to install NVM. Check the output above for details."
    fi
fi
# Ensure nvm is available before using it
if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
    if execute_command "nvm install --lts"; then
        logg "${COLOR_GREEN}" "✓ Node.js LTS installed successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to install Node.js LTS"
    fi
else
    logg "${COLOR_YELLOW}" "NVM not available in this session. Please run 'nvm install --lts' manually after restarting your terminal."
fi

logg "${COLOR_GREEN}" "Installing Python..."
if ! command -v python3 &>/dev/null; then
    if execute_command "brew install python@3.12"; then
        logg "${COLOR_GREEN}" "✓ Python installed successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to install Python"
    fi
else
    python_version=$(python3 --version 2>&1)
    logg "${COLOR_YELLOW}" "Python is already installed (${python_version}), skipping..."
fi

logg "${COLOR_GREEN}" "Installing Go..."
if ! command -v go &>/dev/null; then
    if execute_command "brew install go"; then
        logg "${COLOR_GREEN}" "✓ Go installed successfully"
        # Add Go bin to PATH if not already there
        if ! grep -q 'export PATH.*go/bin' "${ZSHRC_FILE}" 2>/dev/null; then
            echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> "${ZSHRC_FILE}"
            export PATH="$PATH:$(go env GOPATH)/bin"
        fi
    else
        logg "${COLOR_RED}" "✗ Failed to install Go"
    fi
else
    go_version=$(go version 2>&1 | head -1)
    logg "${COLOR_YELLOW}" "Go is already installed (${go_version}), skipping..."
fi

logg "${COLOR_GREEN}" "Installing Java..."
if ! command -v java &>/dev/null; then
    if execute_command "brew install openjdk@21"; then
        logg "${COLOR_GREEN}" "✓ Java installed successfully"
        # Add Java to PATH if not already there
        if ! grep -q 'export PATH.*openjdk' "${ZSHRC_FILE}" 2>/dev/null; then
            echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> "${ZSHRC_FILE}"
            export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
        fi
    else
        logg "${COLOR_RED}" "✗ Failed to install Java"
    fi
else
    java_version=$(java -version 2>&1 | head -1)
    logg "${COLOR_YELLOW}" "Java is already installed (${java_version}), skipping..."
fi

if [[ ${SYSTEM_ARCH} == "arm64" ]]; then
    logg "${COLOR_YELLOW}" "Configuring for Apple Silicon (arm64) mac..."
    if echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"; then
        logg "${COLOR_GREEN}" "✓ Apple Silicon configuration completed"
    else
        logg "${COLOR_RED}" "✗ Failed to configure Apple Silicon settings"
    fi
else
    logg "${COLOR_YELLOW}" "Configuring for Intel (x86 64 bit) mac..."
    logg "${COLOR_GREEN}" "✓ Intel configuration completed"
fi

logg "${COLOR_GREEN}" "Downloading and setting up applications..."
mkdir -p ~/Desktop/Applications

postman_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://dl.pstmn.io/download/latest/osx_arm64" || echo "https://dl.pstmn.io/download/latest/osx_64")
notion_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://www.notion.so/desktop/apple-silicon/download" || echo "https://www.notion.so/desktop/mac/download")
vscode_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64" || echo "https://code.visualstudio.com/sha/download?build=stable&os=darwin")

declare -A APPLICATIONS_URLS=(
    ["Rectangle"]="https://github.com/rxhanson/Rectangle/releases/download/v0.61/Rectangle0.61.dmg"
    ["iTerm2"]="https://iterm2.com/downloads/stable/latest"
    ["Postman"]="${postman_url}"
    ["Notion"]="${notion_url}"
    ["Visual Studio Code"]="${vscode_url}"
    ["Spotify"]="https://download.scdn.co/SpotifyInstaller.zip"
    ["Rocket"]="https://macrelease.matthewpalmer.net/Rocket.dmg"
)

for app in "${!APPLICATIONS_URLS[@]}"; do
    # Determine file extension based on URL
    url="${APPLICATIONS_URLS[$app]:-}"
    [[ -z "$url" ]] && continue
    if [[ "$url" == *.dmg ]]; then
        extension=".dmg"
    elif [[ "$url" == *.zip ]]; then
        extension=".zip"
    else
        extension=""
    fi
    
    output_file="$HOME/Desktop/Applications/${app}${extension}"
    
    # Skip if file already exists
    if [[ -f "${output_file}" ]]; then
        logg "${COLOR_YELLOW}" "${app} already downloaded, skipping..."
        continue
    fi
    
    logg "${COLOR_MAGENTA}" "Downloading ${app}..."
    printf "  URL: %s\n" "${url}"
    
    # Download with timeout and better error handling
    # Use --silent --show-error --progress-bar for better output control
    if curl -L --max-time 300 --connect-timeout 30 --fail --location-trusted \
        --progress-bar --show-error "${url}" -o "${output_file}" 2>&1; then
        if [[ -f "${output_file}" ]] && [[ -s "${output_file}" ]]; then
            file_size=$(du -h "${output_file}" | cut -f1)
            logg "${COLOR_GREEN}" "✓ Successfully downloaded ${app} (${file_size})"
        else
            logg "${COLOR_RED}" "✗ Download completed but file is empty or missing"
            [[ -f "${output_file}" ]] && rm -f "${output_file}"
        fi
    else
        exit_code=$?
        logg "${COLOR_RED}" "✗ Failed to download ${app} (exit code: ${exit_code})"
        # Remove partial download
        [[ -f "${output_file}" ]] && rm -f "${output_file}"
    fi
    echo ""
done

logg "${COLOR_GREEN}" "Installing VS Code extensions..."
if [[ -d "vscode" ]] && [[ -f "vscode/extensions.sh" ]]; then
    if cd vscode && bash extensions.sh; then
        cd ..
        logg "${COLOR_GREEN}" "✓ VS Code extensions installed successfully"
    else
        cd ..
        logg "${COLOR_RED}" "✗ Failed to install VS Code extensions. Check the output above for details."
    fi
else
    logg "${COLOR_YELLOW}" "vscode/extensions.sh not found, skipping..."
fi

logg "${COLOR_GREEN}" "Configuring git..."
if git config --global user.name "Mayur Bhoi" && \
   git config --global user.email "mayur072000@gmail.com" && \
   git config --global init.defaultBranch main && \
   git config --global core.editor "code --wait"; then
    logg "${COLOR_GREEN}" "✓ Git configured successfully"
else
    logg "${COLOR_RED}" "✗ Failed to configure git"
fi

logg "${COLOR_GREEN}" "Installing fonts..."
FONT_DIR="$HOME/Library/Fonts"
mkdir -p "${FONT_DIR}"
if [[ -d "fonts" ]]; then
    font_count=$(find fonts -type f \( -name "*.otf" -o -name "*.ttf" \) | wc -l | tr -d ' ')
    if find fonts -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp {} "${FONT_DIR}" \; 2>/dev/null; then
        logg "${COLOR_GREEN}" "✓ Fonts installed successfully (${font_count} fonts)"
    else
        logg "${COLOR_RED}" "✗ Failed to install fonts"
    fi
else
    logg "${COLOR_YELLOW}" "Fonts directory not found, skipping..."
fi

logg "${COLOR_GREEN}" "Building and installing custom scripts..."
if [[ -d "scripts" ]]; then
    # Create local bin directory if it doesn't exist
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "${LOCAL_BIN}"
    
    # Add to PATH if not already there
    if ! grep -q 'export PATH.*\.local/bin' "${ZSHRC_FILE}" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${ZSHRC_FILE}"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    script_count=0
    failed_count=0
    
    # Build Go scripts
    if command -v go &>/dev/null; then
        for go_file in scripts/*.go; do
            if [[ -f "$go_file" ]]; then
                script_name=$(basename "$go_file" .go)
                logg "${COLOR_MAGENTA}" "Building ${script_name}..."
                if go build -o "${LOCAL_BIN}/${script_name}" "$go_file" 2>/dev/null; then
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
    if [[ -d "scripts/bin" ]]; then
        for bin_file in scripts/bin/*; do
            if [[ -f "$bin_file" ]] && [[ -x "$bin_file" ]]; then
                bin_name=$(basename "$bin_file")
                if cp "$bin_file" "${LOCAL_BIN}/${bin_name}"; then
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
else
    logg "${COLOR_YELLOW}" "scripts directory not found, skipping..."
fi

logg "${COLOR_GREEN}" "Configuring macOS defaults..."
if [[ -f "./defaults.sh" ]]; then
    logg "${COLOR_MAGENTA}" "Running macOS defaults configuration script..."
    if bash ./defaults.sh; then
        logg "${COLOR_GREEN}" "✓ macOS defaults configured successfully"
    else
        logg "${COLOR_RED}" "✗ Failed to configure macOS defaults. Check the output above for details."
    fi
else
    logg "${COLOR_YELLOW}" "defaults.sh not found in current directory, skipping..."
fi

logg "${COLOR_GREEN}" "All set. These are the next steps:"
logg "${COLOR_GREEN}" "1. Install applications downloaded from ~/Desktop/Applications folder"
logg "${COLOR_GREEN}" "2. For Advent of Code stuff to work, add {export AOC_SESSION_TOKEN=<token>} to your ~/.zshrc file"
logg "${COLOR_GREEN}" "3. Restart your terminal or run 'source ~/.zshrc' to load NVM and other configurations"
