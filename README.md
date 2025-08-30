# Universal Setup Tool

Cross-platform scripts to automate installation of the following dev tools for SoDA workshops:
- Git
- Visual Studio Code
- Python 3.8.18

We support the following platforms by leveraging their respective package managers:
- Windows 10/11 (winget)
- macOS (brew)
- Ubuntu/Debian (apt)
- Fedora/RHEL/CentOS (dnf/yum)
- openSUSE (zypper)
- Arch/Manjaro (pacman)

If you're using anything besides these platforms, we hope you're savvy enough to install these tools yourself :)

## Quick Start

### Linux/MacOS/WSL

**via bash/zsh/POSIX-compliant shell:**
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/setup.sh)
```

**via fish 🐟:**
```fish
bash (curl -fsSL https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/setup.sh | psub)
```

### Windows via Powershell
1. Launch Powershell by launching it from the search bar OR hitting `Windows+R`, typing in `powershell.exe`, and pressing `ENTER`.

2. Bypass PowerShell execution policy for the current session (don't worry, this won't persist after you close the shell):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

3. Then download and run the script:
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/windows.ps1 -OutFile windows.ps1
.\windows.ps1
```

## Features

- **Idempotent**: Safe to run multiple times
- **Automatic Fallback**: Uses pyenv/pyenv-win if system Python 3.8 unavailable
- **Shell Detection**: Configures .bashrc, .zshrc, or config.fish automatically
- **Error Handling**: Fail-fast approach with clear error messages

## Post-Installation

### Python Virtual Environments
Create isolated Python environments for your projects:

```bash
# Unix/Linux/macOS
python3.8 -m venv .venv
source .venv/bin/activate  # bash/zsh
# or
source .venv/bin/activate.fish  # fish

# Windows
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

### VS Code Command Line
The `code` command should be available in your terminal:
```bash
code .  # Open current directory in VS Code
```

### Pyenv Users
If Python was installed via pyenv, restart your shell or run:
```bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

## Troubleshooting

### Windows
- **"winget not found"**: Install App Installer from Microsoft Store
- **"Running scripts is disabled"**: Use the execution policy bypass command shown above
- **Commands not found**: Open a new PowerShell window to refresh PATH

### Unix/Linux
- **Permission denied**: The script will request sudo when needed
- **Package manager not detected**: Manual installation may be required
- **Python 3.8 not in repos**: Script automatically falls back to pyenv

### macOS
- **Homebrew installation**: The script will install it if missing
- **Command Line Tools**: May prompt to install Xcode CLT
