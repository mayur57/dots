#!/usr/bin/env bash

# Modular setup script - Main entry point
# Prompts user to select which modules to run

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
source "${MODULES_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/setup_error.log"
exec 2>>"${ERROR_LOG}"

# Module definitions in execution order (most important to least important)
MODULES=(
    "defaults"      # macOS defaults - must be first, may require Finder reload
    "system"        # System architecture configuration
    "homebrew"      # Package manager - needed for other modules
    "shell"         # Shell setup (zsh, oh-my-zsh, aliases, .zshrc)
    "languages"      # Development languages/SDKs
    "git"           # Git configuration
    "agents"        # AI coding tools (Claude Code, Gemini CLI)
    "applications"  # Application downloads
    "vscode"        # VS Code extensions
    "fonts"         # Font installation
    "scripts"       # Custom scripts building
)

# Module descriptions (indexed by module name)
get_module_description() {
    local module="$1"
    case "${module}" in
        "defaults")     echo "macOS defaults configuration" ;;
        "system")        echo "System architecture configuration" ;;
        "homebrew")      echo "Homebrew installation and package management" ;;
        "shell")         echo "Shell configuration (Oh My Zsh, .zshrc, aliases)" ;;
        "languages")     echo "Programming languages (Node.js, Python, Go, Java)" ;;
        "git")           echo "Git configuration" ;;
        "agents")        echo "AI coding tools (Claude Code, Gemini CLI)" ;;
        "applications")  echo "Download applications (Rectangle, iTerm2, etc.)" ;;
        "vscode")        echo "VS Code extensions installation" ;;
        "fonts")         echo "Font installation" ;;
        "scripts")       echo "Custom scripts building and installation" ;;
        *)               echo "Unknown module" ;;
    esac
}

# Function to display menu
show_menu() {
    logg "${COLOR_BLUE}" "╔════════════════════════════════════════════════════════╗"
    logg "${COLOR_BLUE}" "║         Modular Dotfiles Setup - Select Modules       ║"
    logg "${COLOR_BLUE}" "╚════════════════════════════════════════════════════════╝"
    echo ""
    logg "${COLOR_GREEN}" "Available modules (in execution order):"
    echo ""
    local index=1
    for module in "${MODULES[@]}"; do
        local desc=$(get_module_description "${module}")
        printf "  ${COLOR_YELLOW}%2d${COLOR_NORMAL}. %-20s - %s\n" "${index}" "${module}" "${desc}"
        ((index++))
    done
    echo ""
    printf "  ${COLOR_YELLOW}%2d${COLOR_NORMAL}. %s\n" "${index}" "Run all modules sequentially"
    ((index++))
    printf "  ${COLOR_YELLOW}%2d${COLOR_NORMAL}. %s\n" "${index}" "Exit"
    echo ""
}

# Function to get module name by index
get_module_by_index() {
    local index=$1
    if [[ $index -ge 1 ]] && [[ $index -le ${#MODULES[@]} ]]; then
        echo "${MODULES[$((index-1))]}"
    fi
}

# Function to run a module
run_module() {
    local module=$1
    local module_script="${MODULES_DIR}/${module}.sh"
    
    if [[ ! -f "${module_script}" ]]; then
        logg "${COLOR_RED}" "✗ Module script not found: ${module_script}"
        return 1
    fi
    
    logg "${COLOR_BLUE}" ""
    logg "${COLOR_BLUE}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    logg "${COLOR_MAGENTA}" "Running module: ${module}"
    logg "${COLOR_BLUE}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run module and capture output
    if bash "${module_script}" 2>> "${ERROR_LOG}"; then
        logg "${COLOR_GREEN}" "✓ Module '${module}' completed successfully"
        return 0
    else
        logg "${COLOR_RED}" "✗ Module '${module}' failed (check ${ERROR_LOG} for details)"
        return 1
    fi
}

# Function to select modules interactively
select_modules() {
    local selected_modules=()
    local total_modules=${#MODULES[@]}
    
    while true; do
        show_menu
        read -p "$(echo -e ${COLOR_YELLOW}Enter module numbers \(space-separated\) or 'all' for all modules:${COLOR_NORMAL}) " selection
        
        if [[ "${selection}" == "all" ]]; then
            selected_modules=("${MODULES[@]}")
            break
        elif [[ "${selection}" =~ ^[0-9\ ]+$ ]]; then
            read -ra indices <<< "${selection}"
            for idx in "${indices[@]}"; do
                local total_options=$((total_modules + 2))  # +2 for "all" and "exit"
                
                if [[ $idx -eq $((total_modules + 1)) ]]; then
                    # Run all modules
                    selected_modules=("${MODULES[@]}")
                    break 2
                elif [[ $idx -eq $((total_modules + 2)) ]]; then
                    # Exit
                    logg "${COLOR_YELLOW}" "Exiting..."
                    exit 0
                elif [[ $idx -ge 1 ]] && [[ $idx -le $total_modules ]]; then
                    local module=$(get_module_by_index "$idx")
                    if [[ -n "${module}" ]]; then
                        selected_modules+=("${module}")
                    fi
                else
                    logg "${COLOR_RED}" "Invalid selection: ${idx}"
                fi
            done
            
            if [[ ${#selected_modules[@]} -gt 0 ]]; then
                break
            else
                logg "${COLOR_RED}" "No valid modules selected. Please try again."
            fi
        else
            logg "${COLOR_RED}" "Invalid input. Please enter numbers or 'all'."
        fi
    done
    
    echo "${selected_modules[@]}"
}

# Main function
main() {
    logg "${COLOR_BLUE}" "╔════════════════════════════════════════════════════════╗"
    logg "${COLOR_BLUE}" "║              Modular Dotfiles Setup Script             ║"
    logg "${COLOR_BLUE}" "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Detect system architecture
    SYSTEM_ARCH=$(get_system_arch)
    logg "${COLOR_GREEN}" "Detected system architecture: ${SYSTEM_ARCH}"
    echo ""
    
    # Show modules that will run
    logg "${COLOR_GREEN}" "Modules will run sequentially in the following order:"
    for module in "${MODULES[@]}"; do
        local desc=$(get_module_description "${module}")
        printf "  - ${COLOR_MAGENTA}%s${COLOR_NORMAL}: %s\n" "${module}" "${desc}"
    done
    echo ""
    
    # Run all modules sequentially
    local success_count=0
    local fail_count=0
    
    for module in "${MODULES[@]}"; do
        if run_module "${module}"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # Summary
    logg "${COLOR_BLUE}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    logg "${COLOR_GREEN}" "Installation Summary:"
    logg "${COLOR_GREEN}" "  ✓ Successful: ${success_count}"
    if [[ ${fail_count} -gt 0 ]]; then
        logg "${COLOR_RED}" "  ✗ Failed: ${fail_count}"
    fi
    logg "${COLOR_BLUE}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    logg "${COLOR_GREEN}" "Next steps:"
    logg "${COLOR_YELLOW}" "1. Install applications downloaded from ~/Desktop/Applications folder"
    logg "${COLOR_YELLOW}" "2. For Advent of Code stuff to work, add {export AOC_SESSION_TOKEN=<token>} to your ~/.zshrc file"
    logg "${COLOR_YELLOW}" "3. Restart your terminal or run 'source ~/.zshrc' to load NVM and other configurations"
    echo ""
}

# Run main function
main "$@"
