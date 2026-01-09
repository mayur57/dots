# Dot Files

Essential files and preferences aggregated to make setting up a Mac as easy as running one script.

## Usage
Download the source as a ZIP, unpack and run `cd <your-dir> | sh setup.sh` in your terminal

## Compatibility

- macOS 

## Actions
These steps are followed sequentially with feedback for every step.

### Setup Dev Tools
- Sets strict error handling with detailed logging to an error log file (setup_error.log).
- Detects system architecture (arm64 or x86_64).
- Verifies an active internet connection before proceeding.
- Installs Homebrew if not already installed.
- Updates Homebrew and installs essential packages: yarn, gh (GitHub CLI), jq, wget, tree
- Installs Oh My Zsh if not already installed.
- Backs up the existing .zshrc file (if present) and replaces it with a new configuration.
- Installs Node Version Manager (NVM) and the latest LTS version of Node.js.
- Adjusts environment paths based on the system architecture.
- Creates a directory (~/Desktop/Applications) for downloaded applications.
- Downloads and prepares installation files for the following: Rectangle, iTerm2, Postman, Notion, Visual Studio Code, Spotify, Rocket

### Installs VS Code Extensions
Runs a separate script (extensions.sh) to install and configure VS Code extensions.

### Configures Git with user information:
Sets default branch to main and configures VS Code as the default Git editor.

### Install fonts
Copies .otf and .ttf font files from a local directory (fonts) to the system's font directory.
Provides instructions to install additional VS Code extensions manually.
