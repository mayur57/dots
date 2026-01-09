# Dot Files

Essential files and preferences aggregated to make setting up a Mac as easy as running one script.

## Usage

### Setup
Run the setup script to install all modules sequentially:
```bash
cd <your-dir>
./setup.sh
```

The script will:
- Run all modules sequentially in the optimal order
- Display clean, minimal output with progress indicators
- Log detailed errors to `setup_error.log` if anything fails
- Automatically configure everything with sensible defaults


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

## Setup Modules

The setup script (`setup.sh`) runs modules sequentially in the following order:

1. **defaults** - macOS defaults configuration (must be first, may require Finder reload)
2. **system** - System architecture configuration
3. **homebrew** - Homebrew installation and package management
4. **shell** - Shell configuration (Oh My Zsh, .zshrc, aliases)
5. **languages** - Programming languages (Node.js, Python, Go, Java)
6. **git** - Git configuration
7. **agents** - AI coding tools (Claude Code, Gemini CLI)
8. **applications** - Download applications (Rectangle, iTerm2, etc.)
9. **vscode** - VS Code extensions installation
10. **fonts** - Font installation
11. **scripts** - Custom scripts building and installation

Each module can also be run independently by executing the script in the `modules/` directory.
