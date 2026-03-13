#!/usr/bin/env bash

# VS Code extensions installer
#
# - Exits early (no-op) if the `code` CLI is not available.
# - Uses a simple loop instead of many eval calls.

set -euo pipefail

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI ('code') not found on PATH. Skipping extension installation."
  echo "To enable this later, install VS Code and add the 'code' command to PATH, then re-run this script."
  exit 0
fi

EXTENSIONS=(
  "aaron-bond.better-comments"
  "alexandernanberg.horizon-theme-vscode"
  "atlassian.atlascode"
  "austin.code-gnu-global"
  "christian-kohler.npm-intellisense"
  "cschlosser.doxdocgen"
  "DavidAnson.vscode-markdownlint"
  "dbaeumer.vscode-eslint"
  "dotdevru.prettier-java"
  "dsznajder.es7-react-js-snippets"
  "eamodio.gitlens"
  "esbenp.prettier-vscode"
  "file-icons.file-icons"
  "formulahendry.code-runner"
  "GitHub.copilot"
  "GitHub.github-vscode-theme"
  "GitHub.vscode-pull-request-github"
  "iocave.customize-ui"
  "iocave.monkey-patch"
  "jeff-hykin.better-cpp-syntax"
  # "jolaleye.horizon-theme-vscode" # Deprecated / not available; kept here for reference
  "kamikillerto.vscode-colorize"
  "mariomatheu.syntax-project-pbxproj"
  "mathiasfrohlich.Kotlin"
  "mgmcdermott.vscode-language-babel"
  "mhutchie.git-graph"
  "ms-azuretools.vscode-docker"
  "ms-python.python"
  "ms-python.vscode-pylance"
  "ms-toolsai.jupyter"
  "ms-toolsai.jupyter-keymap"
  "ms-toolsai.jupyter-renderers"
  "ms-toolsai.vscode-jupyter-cell-tags"
  "ms-toolsai.vscode-jupyter-slideshow"
  "ms-vscode.cpptools"
  "ms-vscode.cpptools-extension-pack"
  "ms-vscode.cpptools-themes"
  "ms-vscode.vscode-typescript-next"
  "ms-vsliveshare.vsliveshare"
  "msjsdiag.vscode-react-native"
  "oderwat.indent-rainbow"
  "oouo-diogo-perdigao.docthis"
  "redhat.java"
  "redhat.vscode-yaml"
  "ritwickdey.LiveServer"
  "sallar.vscode-duotone-dark"
  "sburg.vscode-javascript-booster"
  "TabNine.tabnine-vscode"
  "VisualStudioExptTeam.intellicode-api-usage-examples"
  "VisualStudioExptTeam.vscodeintellicode"
  "vivaxy.vscode-conventional-commits"
  "vscjava.vscode-java-debug"
  "vscjava.vscode-java-dependency"
  "vscjava.vscode-java-pack"
  "vscjava.vscode-java-test"
  "vscjava.vscode-maven"
  "vscodevim.vim"
  "whizkydee.material-palenight-theme"
  "wix.vscode-import-cost"
  "xabikos.JavaScriptSnippets"
  "yzhang.markdown-all-in-one"
)

for ext in "${EXTENSIONS[@]}"; do
  echo "Installing VS Code extension: ${ext}"
  # Continue on failure of individual extensions
  if ! code --install-extension "${ext}" >/dev/null 2>&1; then
    echo "  - Failed to install ${ext}, continuing..."
  fi
done

echo "VS Code extensions installation script completed."