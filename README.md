# Universal Setup Tool

Cross-platform scripts to automate installation of essential development tools (Git, VS Code, Python 3.8) across Windows, macOS, and Linux distributions.

## Quick Start

### Unix/Linux/macOS (One-liner)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/setup.sh)
```

### Windows
First, bypass PowerShell execution policy for the current session:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then download and run the script:
```powershell
# Option 1: Download and run
Invoke-WebRequest -Uri https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/windows.ps1 -OutFile windows.ps1
.\windows.ps1

# Option 2: One-liner (after execution policy bypass)
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/asusoda/universal-setup/refs/heads/main/windows.ps1'))
```

## What Gets Installed

- **Git** - Version control system
- **Visual Studio Code** - Modern code editor
- **Python 3.8.18** - Python interpreter (latest 3.8.x release)

## Platform Support

### Unix/Linux
- **Ubuntu/Debian** (apt)
- **Fedora/RHEL/CentOS** (dnf/yum)
- **openSUSE** (zypper)
- **Arch/Manjaro** (pacman)
- **macOS** (brew)

### Windows
- Windows 10/11 with winget (App Installer)
- Automatic admin elevation
- PowerShell 5.1+

## Features

- **Idempotent**: Safe to run multiple times
- **Automatic Fallback**: Uses pyenv/pyenv-win if system Python 3.8 unavailable
- **Shell Detection**: Configures .bashrc, .zshrc, or config.fish automatically
- **Package Manager Abstraction**: Works with your distro's native package manager
- **Error Handling**: Fail-fast approach with clear error messages

## Manual Installation

### Clone and Run Locally

```bash
git clone https://github.com/asusoda/universal-setup.git
cd universal-setup

# Unix/Linux/macOS
chmod +x setup.sh
./setup.sh

# Windows (PowerShell as Administrator)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows.ps1
```

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

## Security Notes

- Scripts are downloaded over HTTPS
- Windows execution policy bypass is session-only (doesn't change system settings)
- No sensitive data is collected or transmitted
- Open source - review the code before running

## Contributing

Pull requests welcome! Please test on your target platform before submitting.

## License

MIT License - see [LICENSE](LICENSE) file for details