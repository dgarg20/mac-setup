# Mac Setup Scripts

A comprehensive collection of bash scripts to automate the setup of a new Mac with all necessary development tools, software, and configurations.

## Overview

This repository contains scripts that will help you set up a complete development environment on macOS, including:

- **Package Management**: Homebrew installation and configuration
- **Development Tools**: Git, VS Code, iTerm2, Sublime Text
- **Java Development**: SDKMAN, multiple Java versions, Maven, Gradle
- **Shell Configuration**: Zsh with Oh My Zsh, custom aliases and functions
- **Version Control**: Git configuration with useful aliases and settings
- **SSH Setup**: SSH key management and configuration
- **AWS Tools**: AWS CLI installation and setup
- **Docker Support**: Container development tools

## Quick Start

1. **Clone or download** this repository to your Mac
2. **Navigate** to the directory containing the scripts
3. **Run the main setup script**:
   ```bash
   ./mac_setup.sh
   ```
4. **Answer the four pre-flight prompts** (see below) before anything runs

Every install step checks whether the item is already present before installing it, so the script is safe to re-run.

### Pre-flight prompts

Before doing any work, `mac_setup.sh` shows a numbered list of everything it will check/install/configure, then asks four questions:

1. **Items to skip** - comma-separated item numbers (e.g. `4.2,7.3,9`) to skip entirely. Skipping a top-level number (e.g. `7`) skips all its sub-items too.
2. **Config overwrite behavior** (items 12-15) - for each config-writing step, choose whether to replace an existing config file (default, with an automatic `.backup`) or keep it as-is if it already exists.
3. **RSA SSH key setup** (item 14, only if no key exists yet at `~/.ssh/id_rsa`) - generate a new key pair, or copy one in from another path on disk.
4. **Git/GitHub identity** (item 13) - the username and email to use for `git config user.name` / `user.email`.

All four prompts default sensibly and are skipped automatically in non-interactive shells (nothing gets skipped, config files get replaced, new keys get generated).

## Scripts Overview

### Main Setup Script

- **`mac_setup.sh`** - The main orchestrator script that runs all other setup scripts in the correct order

### Configuration Scripts

- **`configure_shell.sh`** - Sets up Zsh with Oh My Zsh, plugins, and useful aliases
- **`configure_git.sh`** - Configures Git with user settings, aliases, and global gitignore
- **`configure_ssh.sh`** - Sets up SSH configuration, key management, permissions, and RSA key generation/copy
- **`setup_dev_environment.sh`** - Creates development directories, VS Code settings, and utility scripts

### Validation Script

- **`validate_setup.sh`** - Read-only script that checks installed tools, config files, and directories, and reports a pass/fail summary

## What Gets Installed

### Package Manager
- **Homebrew** - The missing package manager for macOS

### Development Tools
- **Git** - Version control system
- **Visual Studio Code** - Code editor with extensions
- **iTerm2** - Terminal emulator
- **Sublime Text** - Text editor
- **Slack** - Team communication and collaboration
- **Zsh + Oh My Zsh** - Enhanced shell with themes and plugins

### Java Development Stack
- **SDKMAN** - Java version manager
- **Java 8, 11, 17, 21** - Multiple Java versions (Amazon Corretto)
- **Maven** - Build automation tool
- **Gradle** - Build automation tool
- **Scala** - Functional programming language

### Programming Languages
- **Go** - Modern programming language for system programming
- **Scala** - Functional programming language for the JVM

### Message Brokers & Streaming
- **Apache Kafka** - Distributed streaming platform (downloaded and extracted to `~/Downloads`)

### Cloud & DevOps Tools
- **AWS CLI** - Amazon Web Services command line interface
- **Rancher Desktop** - Container management and Kubernetes
- **Docker** - Container development tools (via Rancher Desktop)

## Configuration Details

### Shell Configuration (Zsh)
- **Theme**: robbyrussell (Oh My Zsh default)
- **Plugins**: git, brew, macos, docker, aws, gradle, maven
- **Custom aliases** for common commands
- **History configuration** with search and sharing
- **Auto-completion** with case-insensitive matching

### Git Configuration
- **User**: prompted interactively at the start of `mac_setup.sh` (defaults to Deepanshu Garg <deepanshu.garg@cred.club> if left blank)
- **Editor**: VS Code
- **Useful aliases** (st, co, br, lg, etc.)
- **Global gitignore** for common files
- **Bitbucket SSH configuration**

### SSH Configuration
- **Keychain integration** for macOS
- **Proper file permissions** (600 for private keys, 644 for public keys)
- **Git hosting service configurations** (GitHub, Bitbucket, GitLab)
- **RSA key pair**: auto-generated if none exists, or copied in from a path you provide (prompted at the start of `mac_setup.sh`)
- **SSH key generation helper script** (`~/.ssh/generate_ssh_key.sh`) for manual regeneration later

### Development Environment
- **Directory structure**: ~/Development/{projects,tools,scripts,workspace}
- **VS Code settings** optimized for Java development
- **Maven settings** with Java 21 as default
- **Gradle properties** with performance optimizations
- **Utility scripts** for common development tasks

## Directory Structure Created

```
~/Development/
├── projects/          # Your development projects
├── tools/            # Development tools and utilities
├── scripts/          # Utility scripts
└── workspace/        # Temporary workspace

~/Development/scripts/
├── switch-java.sh    # Switch between Java versions
├── clean-dev.sh      # Clean development caches
├── dev-status.sh     # Show environment status
└── create-project.sh # Create new projects

~/Development/tools/
├── vscode-extensions.txt           # List of VS Code extensions
└── install-vscode-extensions.sh   # Install VS Code extensions
```

## Usage Examples

### Running Individual Scripts

```bash
# Configure shell only
./configure_shell.sh

# Configure Git only
./configure_git.sh

# Configure SSH only
./configure_ssh.sh

# Setup development environment only
./setup_dev_environment.sh
```

### Using Utility Scripts

```bash
# Check development environment status
~/Development/scripts/dev-status.sh

# Switch Java versions
~/Development/scripts/switch-java.sh

# Clean development caches
~/Development/scripts/clean-dev.sh

# Create a new project
~/Development/scripts/create-project.sh

# Install VS Code extensions
~/Development/tools/install-vscode-extensions.sh

# Generate SSH keys
~/.ssh/generate_ssh_key.sh
```

### Git Aliases

The setup includes many useful Git aliases:

```bash
git st          # git status
git co          # git checkout
git br          # git branch
git lg          # git log --oneline --graph --decorate
git unstage     # git reset HEAD --
git cleanup     # Remove merged branches
```

### Shell Aliases

Common shell aliases are configured:

```bash
ll              # ls -alF
gs              # git status
dps             # docker ps
dcup            # docker-compose up
code.           # code . (open current directory in VS Code)
```

## Customization

### Modifying User Information

Just answer the "Git/GitHub identity" prompt when running `mac_setup.sh` - no file editing required. To change the fallback defaults (used for non-interactive runs), edit the `GIT_USER_NAME` / `GIT_USER_EMAIL` defaults near the top of `configure_git.sh`.

### Adding More Software

Add applications to the `CASK_APPS` associative array in `mac_setup.sh` (and add a matching menu line / loop entry with the next available item number):

```bash
declare -A CASK_APPS=(
    ["4.1"]="visual-studio-code"
    ["4.2"]="iterm2"
    ["4.3"]="sublime-text"
    ["4.4"]="rancher"
    ["4.5"]="slack"
    ["4.6"]="your-app-here"
)
```

### Customizing VS Code Extensions

Edit `~/Development/tools/vscode-extensions.txt` to add or remove extensions.

### Adding Java Versions

Modify the `JAVA_VERSIONS` associative array in `mac_setup.sh`:

```bash
declare -A JAVA_VERSIONS=(
    ["7.1"]="21.0.8-amzn"
    ["7.2"]="17.0.16-amzn"
    ["7.3"]="11.0.28-amzn"
    ["7.4"]="8.0.462-amzn"
)
```

## Troubleshooting

### Common Issues

1. **Homebrew installation fails**
   - Ensure you have Xcode Command Line Tools: `xcode-select --install`
   - Check your internet connection

2. **SDKMAN installation fails**
   - Restart your terminal after installation
   - Source the configuration: `source ~/.zshrc`

3. **SSH keys not working**
   - Check file permissions: `ls -la ~/.ssh/`
   - Generate new keys: `~/.ssh/generate_ssh_key.sh`

4. **Java versions not switching**
   - Restart terminal or source: `source ~/.zshrc`
   - Check SDKMAN installation: `sdk version`

### Getting Help

- **Check environment status**: `~/Development/scripts/dev-status.sh`
- **View logs**: Scripts provide colored output with timestamps
- **Manual installation**: Run individual scripts if the main script fails

## Security Notes

- **SSH keys**: Scripts set proper permissions (600 for private, 644 for public); a new RSA key pair is only auto-generated when neither `~/.ssh/id_rsa` nor `~/.ssh/id_rsa.pub` already exist
- **Credentials**: No credentials are stored in scripts
- **Backups**: Existing configurations are backed up (`.backup` suffix) before being replaced, unless you chose "keep existing" at the config-overwrite prompt
- **Shell history**: this repo does not track `bash_history.txt` / `zsh_history.txt` or similar shell history files (see `.gitignore`) since they can contain sensitive data

## Requirements

- **macOS**: Tested on macOS (Apple Silicon and Intel)
- **Internet connection**: Required for downloading tools
- **Admin privileges**: Some installations require sudo access

## Manual Software Installation

Some software needs to be installed manually due to licensing or distribution requirements:

### JetBrains IDEs (Manual Download Required)

Download and install the following IDEs from the [JetBrains website](https://www.jetbrains.com/):

- **[IntelliJ IDEA](https://www.jetbrains.com/idea/download/)** - Java/Kotlin IDE
- **[PyCharm](https://www.jetbrains.com/pycharm/download/)** - Python IDE  
- **[GoLand](https://www.jetbrains.com/go/download/)** - Go IDE

*Note: Download the `.dmg` files and install manually. Consider getting a JetBrains license or use the Community editions.*

### Web Browsers

Download and install from their official websites:

- **[Arc Browser](https://arc.net/)** - Modern, feature-rich browser
- **[Google Chrome](https://www.google.com/chrome/)** - Popular web browser

### App Store Applications

Install the following from the Mac App Store:

- **Numbers** - Apple's spreadsheet application

## Post-Installation

After running the setup scripts:

1. **Restart your terminal** or run `source ~/.zshrc`
2. **Configure AWS credentials**: `aws configure`
3. **Add SSH keys** to your Git hosting services
4. **Install VS Code extensions**: `~/Development/tools/install-vscode-extensions.sh`
5. **Test your setup**: `~/Development/scripts/dev-status.sh`
6. **Install manual software** from the section above

## Contributing

Feel free to customize these scripts for your own needs. The scripts are designed to be:

- **Idempotent**: Safe to run multiple times
- **Modular**: Each script can be run independently
- **Documented**: Clear comments and logging
- **Flexible**: Easy to customize and extend

## License

These scripts are provided as-is for personal use. Modify and distribute as needed.

---

**Happy coding!** 🚀
