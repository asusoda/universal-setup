#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSION="3.8.18"   # Latest 3.8.x as of 2025; adjust if needed
USER_SHELL_RC="${HOME}/.bashrc" # Updated dynamically if using zsh/fish later

need_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_shell_rc() {
  # Try to pick the right shell rc file for pyenv initialization
  if [ -n "${ZSH_VERSION:-}" ]; then USER_SHELL_RC="${HOME}/.zshrc"; fi
  if [ -n "${FISH_VERSION:-}" ]; then USER_SHELL_RC="${HOME}/.config/fish/config.fish"; fi
}

msg() { printf "\n\033[1;32m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m%s\033[0m\n" "$*"; }
err() { printf "\n\033[1;31m%s\033[0m\n" "$*" >&2; }

# --- OS detection ---
OS=""
DISTRO=""
if [ "$(uname)" = "Darwin" ]; then
  OS="macOS"
else
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="$ID"
    DISTRO="$ID_LIKE"
  fi
fi

require_sudo() {
  if [ "$EUID" -ne 0 ]; then
    if need_cmd sudo; then
      SUDO="sudo"
    else
      err "This script needs root privileges. Please install sudo or run as root."
      exit 1
    fi
  else
    SUDO=""
  fi
}

# --- VS Code install helpers (official Microsoft repos where possible) ---
install_vscode_deb() {
  $SUDO apt-get update
  $SUDO apt-get install -y wget gpg apt-transport-https
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $SUDO tee /usr/share/keyrings/packages.microsoft.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
  $SUDO apt-get update
  $SUDO apt-get install -y code
}

install_vscode_rpm() {
  $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
  cat <<'EOF' | $SUDO tee /etc/yum.repos.d/vscode.repo >/dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  if need_cmd dnf; then $SUDO dnf check-update || true; $SUDO dnf install -y code; else $SUDO yum check-update || true; $SUDO yum install -y code; fi
}

install_vscode_zypper() {
  $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
  $SUDO zypper --non-interactive addrepo --refresh \
    https://packages.microsoft.com/yumrepos/vscode vscode
  $SUDO zypper --non-interactive refresh
  $SUDO zypper --non-interactive install code
}

install_vscode_arch() {
  # Arch has 'code' (the official binary) in community/extra on most mirrors
  $SUDO pacman -Sy --noconfirm code || {
    warn "Could not install VS Code from official repos. You may use AUR package visual-studio-code-bin."
  }
}

install_vscode_macos() {
  if ! need_cmd brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current shell
    if [ -d /opt/homebrew/bin ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    if [ -d /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  fi
  brew install --cask visual-studio-code
}

# --- Python 3.8 helpers ---
install_python_native_deb() {
  # Try native python3.8. If not available (newer Ubuntu/Debian), skip to pyenv.
  if apt-cache show python3.8 >/dev/null 2>&1; then
    $SUDO apt-get install -y python3.8 python3.8-venv python3.8-distutils
  else
    return 1
  fi
}

install_python_native_rpm() {
  # Fedora/CentOS/RHEL usually expose python38
  if need_cmd dnf; then
    $SUDO dnf install -y python38 python38-devel
  else
    $SUDO yum install -y python38 python38-devel || return 1
  fi
}

install_python_native_zypper() {
  $SUDO zypper --non-interactive install python38 python38-devel || return 1
}

install_python_native_arch() {
  # Arch typically doesn’t keep old minor versions in official repos
  return 1
}

install_python_native_macos() {
  # Homebrew no longer keeps old Python versions reliably; prefer pyenv
  return 1
}

install_pyenv_and_python() {
  msg "Installing Python $PYTHON_VERSION via pyenv (non-system, safe fallback)..."
  detect_shell_rc

  # Build deps
  if [ "$OS" = "macOS" ]; then
    if ! need_cmd brew; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [ -d /opt/homebrew/bin ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
      if [ -d /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
    fi
    brew update
    brew install openssl readline sqlite3 xz zlib bzip2 \
      libffi tcl-tk git curl
  else
    require_sudo
    if need_cmd apt-get; then
      $SUDO apt-get update
      $SUDO apt-get install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev git
    elif need_cmd dnf; then
      $SUDO dnf groupinstall -y "Development Tools" || true
      $SUDO dnf install -y openssl-devel bzip2 bzip2-devel libffi-devel \
        zlib-devel readline-devel sqlite sqlite-devel xz xz-devel tk tk-devel \
        libuuid-devel git curl
    elif need_cmd yum; then
      $SUDO yum groupinstall -y "Development Tools" || true
      $SUDO yum install -y openssl-devel bzip2 bzip2-devel libffi-devel \
        zlib-devel readline-devel sqlite sqlite-devel xz xz-devel tk tk-devel \
        libuuid-devel git curl
    elif need_cmd zypper; then
      $SUDO zypper --non-interactive install -t pattern devel_basis || true
      $SUDO zypper --non-interactive install openssl-devel bzip2 libbz2-devel \
        libffi-devel zlib-devel readline-devel sqlite3 sqlite3-devel xz xz-devel \
        tk tk-devel git curl
    elif need_cmd pacman; then
      $SUDO pacman -Sy --noconfirm base-devel openssl zlib bzip2 \
        libffi readline sqlite xz tk git curl
    else
      warn "Unknown package manager; you might need to install build deps manually."
    fi
  fi

  # Install pyenv
  if ! need_cmd pyenv; then
    curl -fsSL https://pyenv.run | bash
    # Init lines
    if [ -n "${ZSH_VERSION:-}" ]; then
      {
        echo ''
        echo '# pyenv init'
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"'
        echo 'eval "$(pyenv init -)"'
        echo 'eval "$(pyenv virtualenv-init -)"'
      } >> "${HOME}/.zshrc"
    elif [ -n "${FISH_VERSION:-}" ]; then
      mkdir -p "${HOME}/.config/fish"
      {
        echo '# pyenv init'
        echo 'set -Ux PYENV_ROOT $HOME/.pyenv'
        echo 'fish_add_path $PYENV_ROOT/bin'
        echo 'status --is-interactive; and pyenv init - | source'
      } >> "${HOME}/.config/fish/config.fish"
    else
      {
        echo ''
        echo '# pyenv init'
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"'
        echo 'eval "$(pyenv init -)"'
        echo 'eval "$(pyenv virtualenv-init -)"'
      } >> "${HOME}/.bashrc"
    fi
    # Load into current session
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)" || true
  fi

  pyenv install -s "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
  msg "Python $(python -V) installed via pyenv. This won’t affect your system Python."
}

install_git_basic() {
  if need_cmd git; then return 0; fi
  msg "Installing Git..."
  if [ "$OS" = "macOS" ]; then
    if need_cmd brew; then brew install git; else xcode-select --install || true; fi
  elif need_cmd apt-get; then
    $SUDO apt-get update; $SUDO apt-get install -y git
  elif need_cmd dnf; then
    $SUDO dnf install -y git
  elif need_cmd yum; then
    $SUDO yum install -y git
  elif need_cmd zypper; then
    $SUDO zypper --non-interactive install git
  elif need_cmd pacman; then
    $SUDO pacman -Sy --noconfirm git
  else
    err "Unknown package manager; please install Git manually."
  fi
}

# --- Main per-OS flow ---
main() {
  msg "Detected platform: ${OS:-unknown} ${DISTRO:+(like $DISTRO)}"

  if [ "$OS" = "macOS" ]; then
    # macOS: Git + VS Code via brew; Python 3.8 via pyenv
    install_git_basic
    install_vscode_macos
    install_pyenv_and_python
  else
    require_sudo
    if need_cmd apt-get; then
      msg "Using apt (Ubuntu/Debian)"
      $SUDO apt-get update
      install_git_basic
      install_vscode_deb
      # Try native python3.8 first; otherwise pyenv
      if ! install_python_native_deb; then
        warn "python3.8 not found in apt; installing via pyenv."
        install_pyenv_and_python
      fi
    elif need_cmd dnf || need_cmd yum; then
      msg "Using dnf/yum (Fedora/RHEL/CentOS)"
      install_git_basic
      install_vscode_rpm
      if ! install_python_native_rpm; then
        warn "python38 not found; installing via pyenv."
        install_pyenv_and_python
      fi
    elif need_cmd zypper; then
      msg "Using zypper (openSUSE)"
      install_git_basic
      install_vscode_zypper
      if ! install_python_native_zypper; then
        warn "python38 not found; installing via pyenv."
        install_pyenv_and_python
      fi
    elif need_cmd pacman; then
      msg "Using pacman (Arch/Manjaro)"
      $SUDO pacman -Sy --noconfirm git curl
      install_vscode_arch
      # Arch rarely ships old minors; use pyenv
      install_pyenv_and_python
    else
      err "Unsupported or undetected UNIX distribution."
      exit 1
    fi
  fi

  # Verify installs
  msg "Verifying installations..."
  if need_cmd git; then git --version; else warn "Git not found after install."; fi
  if need_cmd code; then code --version | head -n 1; else warn "VS Code not found after install."; fi

  # Prefer the python we just installed (pyenv or system)
  if need_cmd pyenv; then
    detect_shell_rc
    msg "Pyenv configured. Restart your shell OR run the following to activate now:"
    echo '  export PATH="$HOME/.pyenv/bin:$PATH"'
    echo '  eval "$(pyenv init -)"'
    echo '  eval "$(pyenv virtualenv-init -)"'
    echo "Then 'python -V' should show Python $PYTHON_VERSION"
  else
    if need_cmd python3.8; then
      msg "System Python available: $(python3.8 -V)"
      warn "Tip: use 'python3.8 -m venv .venv' to create 3.8 virtual environments."
    else
      warn "Python 3.8 not found. Please review messages above."
    fi
  fi

  msg "All done! ✅"
}

main "$@"
