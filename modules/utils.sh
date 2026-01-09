#!/usr/bin/env bash

# Shared utilities for all setup modules

# Color definitions
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_NORMAL="\033[0;39m"

# Error log file (set by each module)
ERROR_LOG=""

# Logging function
logg() {
    local color="$1"
    local message="$2"
    printf "${color}${message}${COLOR_NORMAL}\n"
}

# Execute command with clean output (suppress stdout, capture stderr to error log)
execute_command() {
    local command="$1"
    local description="${2:-}"
    
    # Capture both stdout and stderr, but only show errors
    local temp_output=$(mktemp)
    local temp_error=$(mktemp)
    
    # Execute command, capturing all output
    # Use eval to handle complex commands, redirect both stdout and stderr
    if eval "${command}" > "${temp_output}" 2> "${temp_error}"; then
        # Success - clean up temp files
        rm -f "${temp_output}" "${temp_error}"
        return 0
    else
        # Failure - log error and dump to error log
        local exit_code=$?
        if [[ -n "${ERROR_LOG}" ]]; then
            {
                echo "=========================================="
                echo "Command failed: ${command}"
                echo "Description: ${description:-N/A}"
                echo "Exit code: ${exit_code}"
                echo "Timestamp: $(date)"
                echo "------------------------------------------"
                echo "STDOUT:"
                cat "${temp_output}" 2>/dev/null || echo "(empty)"
                echo "------------------------------------------"
                echo "STDERR:"
                cat "${temp_error}" 2>/dev/null || echo "(empty)"
                echo "=========================================="
                echo ""
            } >> "${ERROR_LOG}" 2>/dev/null
        fi
        rm -f "${temp_output}" "${temp_error}"
        return 1
    fi
}

# Execute command silently (no output at all)
execute_silent() {
    local command="$1"
    eval "${command}" > /dev/null 2>> "${ERROR_LOG:-/dev/null}"
}

# Check internet connectivity
check_internet() {
    if ! ping -c 1 google.com &>/dev/null 2>&1; then
        logg "${COLOR_RED}" "No internet connection detected. Please check your network."
        return 1
    fi
    return 0
}

# Get system architecture
get_system_arch() {
    uname -m
}

# Source this file in modules: source "$(dirname "$0")/utils.sh"
