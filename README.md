## Dotfiles for macOS

Essential dotfiles and setup scripts to provision a new macOS machine in one go.

### Single entry point

The **only entry point** for a full setup is `setup.sh` in the repository root:

```bash
git clone https://github.com/<your-username>/dots.git
cd dots
./setup.sh
```

This script:
- **Runs all setup modules sequentially** in a sensible order
- **Configures macOS defaults, shell, languages, tools, and apps**
- **Logs detailed errors** to `setup_error.log` while keeping console output readable

You can also run individual modules directly from the `modules/` directory if you only want a subset.

### Requirements

- **OS**: macOS (Apple Silicon and Intel are supported)
- **Network**: active internet connection (validated before running modules)
- **User**: admin user with `sudo` access (for macOS defaults and system tools)

### What `setup.sh` does

High‑level flow:

- **System detection & safety**
  - Sets strict error handling and central error logging (`setup_error.log`)
  - Detects architecture (`arm64` / `x86_64`)
  - Verifies internet connectivity

- **Core tooling**
  - Installs Homebrew if missing
  - Installs core packages: `yarn`, `gh`, `jq`, `wget`, `tree`, `dockutil` (via `modules/homebrew.sh`)

- **Shell & dotfiles**
  - Installs Oh My Zsh if not already present
  - Backs up an existing `~/.zshrc` and replaces it with the repo’s `.zshrc` (if present)
  - Copies `.aliases` and ensures it is sourced from `~/.zshrc`

- **macOS defaults**
  - Applies opinionated macOS defaults using `defaults.sh` (run through `modules/defaults.sh`)
  - Covers system, keyboard/input, trackpad, Finder, Dock, screenshots, Activity Monitor, energy settings, and more

- **Developer tooling & applications**
  - Installs language runtimes and SDKs (via `modules/languages.sh`)
  - Configures Git defaults (via `modules/git.sh`)
  - Installs AI coding tools (Claude Code, Gemini CLI) via `modules/agents.sh`
  - Downloads common apps to `~/Desktop/Applications` (via `modules/applications.sh`)
  - Installs VS Code extensions (via `vscode/extensions.sh` and `modules/vscode.sh`)
  - Installs fonts from the local `fonts/` directory (via `modules/fonts.sh`)
  - Builds and installs custom Go utilities from `scripts/` (via `modules/scripts.sh`)

### Module order

For a full run, `setup.sh` executes modules in this fixed order:

1. **defaults** – macOS defaults (requires `sudo`, may restart Finder/Dock)
2. **system** – system and architecture‑specific configuration
3. **homebrew** – Homebrew installation and base packages
4. **shell** – Oh My Zsh, `~/.zshrc`, aliases
5. **languages** – programming languages / SDKs
6. **git** – Git configuration
7. **agents** – AI coding tools (Claude Code, Gemini CLI)
8. **applications** – common desktop apps
9. **vscode** – VS Code extensions
10. **fonts** – font installation
11. **scripts** – custom scripts

Each module is a standalone script in `modules/` and can be executed on its own, for example:

```bash
./modules/homebrew.sh
./modules/shell.sh
```

### Repository layout

Key directories and files:

- `setup.sh` – **single entrypoint** for provisioning a new Mac
- `modules/` – modular setup scripts (defaults, system, homebrew, shell, languages, git, agents, applications, vscode, fonts, scripts)
- `defaults.sh` – macOS defaults script invoked by `modules/defaults.sh`
- `scripts/` – custom Go utilities and prebuilt binaries
- `vscode/` – VS Code‑specific scripts and config (e.g. `extensions.sh`)
- `fonts/` – local font files used by the fonts module
- `.gitconfig` – Git configuration template
- `.notes.yaml` – internal notes / setup ideas
- `PACKAGING.md` – packaging and distribution notes

### Open‑source considerations

- **Secrets**: this repository should not contain any API keys, tokens, or personal credentials. Some modules (e.g. AI tools) expect you to provide tokens after installation.
- **Fonts**: the `fonts/` directory may contain licensed fonts. Before open‑sourcing, verify licenses and either remove or replace these fonts, or add clear instructions for users to supply their own.
- **Personal defaults**: `defaults.sh` encodes your personal macOS preferences. Review and adjust them before publishing so others understand the impact.

### Troubleshooting

- Check `setup_error.log` in the repo root for detailed command failures.
- Most modules are idempotent and can be re‑run safely if something fails partway through.

### Customization

- Edit the root dotfiles (for example `.zshrc`, `.aliases`, `.gitconfig`) to your liking.
- Tweak individual modules under `modules/` to add/remove tools, apps, or language runtimes.
- If you maintain a fork, keep `setup.sh` as the **single entry point**, and document any new modules you add.
