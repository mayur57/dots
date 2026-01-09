#!/usr/bin/env bash

# Programming languages installation module (Node.js, Python, Go, Java)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

ZSHRC_FILE="$HOME/.zshrc"

install_nodejs() {
    logg "${COLOR_GREEN}" "Installing Node Version Manager (NVM) and Node.js..."
    
    if [[ ! -d "$HOME/.nvm" ]]; then
        logg "${COLOR_GREEN}" "Installing NVM..."
        if execute_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash" "NVM installation"; then
            logg "${COLOR_GREEN}" "✓ NVM installed successfully"
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        else
            logg "${COLOR_RED}" "✗ Failed to install NVM"
            return 1
        fi
    else
        logg "${COLOR_GREEN}" "✓ NVM is already installed"
    fi
    
    # Ensure nvm is available
    if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
        logg "${COLOR_GREEN}" "Installing Node.js LTS..."
        if execute_command "nvm install --lts" "Node.js LTS installation"; then
            logg "${COLOR_GREEN}" "✓ Node.js LTS installed successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to install Node.js LTS"
        fi
    else
        logg "${COLOR_YELLOW}" "NVM not available in this session. Please run 'nvm install --lts' manually after restarting your terminal."
    fi
}

install_python() {
    logg "${COLOR_GREEN}" "Installing Python..."
    if ! command -v python3 &>/dev/null; then
        logg "${COLOR_GREEN}" "Installing Python 3.12..."
        if execute_command "brew install python@3.12" "Python installation"; then
            logg "${COLOR_GREEN}" "✓ Python installed successfully"
        else
            logg "${COLOR_RED}" "✗ Failed to install Python"
        fi
    else
        python_version=$(python3 --version 2>&1)
        logg "${COLOR_GREEN}" "✓ Python is already installed (${python_version})"
    fi
}

install_go() {
    logg "${COLOR_GREEN}" "Installing Go..."
    if ! command -v go &>/dev/null; then
        logg "${COLOR_GREEN}" "Installing Go..."
        if execute_command "brew install go" "Go installation"; then
            logg "${COLOR_GREEN}" "✓ Go installed successfully"
            # Add Go bin to PATH if not already there
            if ! grep -q 'export PATH.*go/bin' "${ZSHRC_FILE}" 2>/dev/null; then
                execute_silent "echo 'export PATH=\"\$PATH:\$(go env GOPATH)/bin\"' >> '${ZSHRC_FILE}'"
                export PATH="$PATH:$(go env GOPATH)/bin"
            fi
        else
            logg "${COLOR_RED}" "✗ Failed to install Go"
        fi
    else
        go_version=$(go version 2>&1 | head -1)
        logg "${COLOR_GREEN}" "✓ Go is already installed (${go_version})"
    fi
}

install_java() {
    logg "${COLOR_GREEN}" "Installing Java..."
    if ! command -v java &>/dev/null; then
        logg "${COLOR_GREEN}" "Installing Java (OpenJDK 21)..."
        if execute_command "brew install openjdk@21" "Java installation"; then
            logg "${COLOR_GREEN}" "✓ Java installed successfully"
            # Add Java to PATH if not already there
            SYSTEM_ARCH=$(get_system_arch)
            if [[ ${SYSTEM_ARCH} == "arm64" ]]; then
                java_path="/opt/homebrew/opt/openjdk@21/bin"
            else
                java_path="/usr/local/opt/openjdk@21/bin"
            fi
            if ! grep -q 'export PATH.*openjdk' "${ZSHRC_FILE}" 2>/dev/null; then
                execute_silent "echo 'export PATH=\"${java_path}:\$PATH\"' >> '${ZSHRC_FILE}'"
                export PATH="${java_path}:$PATH"
            fi
        else
            logg "${COLOR_RED}" "✗ Failed to install Java"
        fi
    else
        java_version=$(java -version 2>&1 | head -1)
        logg "${COLOR_GREEN}" "✓ Java is already installed (${java_version})"
    fi
}

main() {
    check_internet || exit 1
    
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        logg "${COLOR_RED}" "Homebrew is required but not installed. Please run the homebrew module first."
        exit 1
    fi
    
    install_nodejs
    install_python
    install_go
    install_java
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
