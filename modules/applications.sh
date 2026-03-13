#!/usr/bin/env bash

# Applications download module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ERROR_LOG="${SCRIPT_DIR}/../setup_error.log"
export ERROR_LOG

download_applications() {
    logg "${COLOR_GREEN}" "Downloading and setting up applications..."
    
    SYSTEM_ARCH=$(get_system_arch)
    mkdir -p "$HOME/Desktop/Applications"
    
    postman_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://dl.pstmn.io/download/latest/osx_arm64" || echo "https://dl.pstmn.io/download/latest/osx_64")
    notion_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://www.notion.so/desktop/apple-silicon/download" || echo "https://www.notion.so/desktop/mac/download")
    vscode_url=$([[ "${SYSTEM_ARCH}" == "arm64" ]] && echo "https://code.visualstudio.com/sha/download?build=stable&os=darwin-arm64" || echo "https://code.visualstudio.com/sha/download?build=stable&os=darwin")
    
    # Use a simple list instead of associative arrays for compatibility with
    # older Bash versions on macOS (bash 3.2).
    APPLICATIONS=(
        "Rectangle|https://github.com/rxhanson/Rectangle/releases/download/v0.61/Rectangle0.61.dmg"
        "iTerm2|https://iterm2.com/downloads/stable/latest"
        "Postman|${postman_url}"
        "Notion|${notion_url}"
        "Visual Studio Code|${vscode_url}"
        "Spotify|https://download.scdn.co/SpotifyInstaller.zip"
        "Rocket|https://macrelease.matthewpalmer.net/Rocket.dmg"
    )
    
    for entry in "${APPLICATIONS[@]}"; do
        app="${entry%%|*}"
        url="${entry#*|}"
        [[ -z "${url}" ]] && continue
        
        # Determine file extension based on URL
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
            logg "${COLOR_GREEN}" "✓ ${app} already downloaded"
            continue
        fi
        
        logg "${COLOR_GREEN}" "Downloading ${app}..."
        if execute_command "curl -L --max-time 300 --connect-timeout 30 --fail --location-trusted --silent --show-error '${url}' -o '${output_file}'" "Download ${app}"; then
            if [[ -f "${output_file}" ]] && [[ -s "${output_file}" ]]; then
                file_size=$(du -h "${output_file}" | cut -f1)
                logg "${COLOR_GREEN}" "✓ Successfully downloaded ${app} (${file_size})"
            else
                logg "${COLOR_RED}" "✗ Download completed but file is empty or missing"
                [[ -f "${output_file}" ]] && rm -f "${output_file}"
            fi
        else
            logg "${COLOR_RED}" "✗ Failed to download ${app}"
            [[ -f "${output_file}" ]] && rm -f "${output_file}"
        fi
    done
    
    logg "${COLOR_GREEN}" "✓ Applications download completed"
}

main() {
    check_internet || exit 1
    download_applications
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
