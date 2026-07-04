# Mac Setup Scripts

A comprehensive collection of bash scripts to automate the setup of a new Mac with all necessary development tools, software, and configurations.

## Overview

This repository contains scripts that will help you set up a complete development environment on macOS, including:

- **Package Management**: Homebrew installation and configuration
- **Browsers & Communication**: Brave, Firefox, Notion, iTerm2, Slack
- **Editors & IDEs**: Sublime Text, VS Code, IntelliJ IDEA, Claude (desktop app), Google Antigravity
- **Database GUI Tools**: Sequel Ace, pgAdmin
- **Java Development**: SDKMAN, Java 21 & 25, Maven, Gradle
- **Other Languages**: Go, Scala
- **Shell Configuration**: Zsh with Oh My Zsh, custom aliases and functions
- **Version Control**: Git configuration with useful aliases and settings
- **SSH Setup**: SSH key management, generation, and configuration
- **AWS Tools**: AWS CLI installation and setup
- **Docker Support**: Rancher Desktop plus a pre-pulled set of common dev images
- **Documents folder structure**: a consistent `official` / `personal` / `docker-volumes` / `claude-temp` / `open-source` layout with matching shell aliases

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

1. **Items to skip** - comma-separated item numbers to skip entirely. You can mix:
   - Specific items: `4.2,7.3,9`
   - Ranges of top-level items: `1-5` skips items 1 through 5 inclusive (and all their sub-items). Ranges are validated (`start >= 1`, `start < end`, `end <= ` the highest item number) - an invalid range like `5-3` or `18-99` is rejected with an error and ignored rather than silently misapplied.
   - Both together: `1-5,9,12.2`

   Skipping a top-level number (e.g. `6`) skips all its sub-items too (`6.1`, `6.2`, `6.3`).
2. **Config overwrite behavior** (items 15-18) - for each config-writing step, choose whether to replace an existing config file (default, with an automatic `.backup`) or keep it as-is if it already exists.
3. **RSA SSH key setup** (item 17, only if no key exists yet at `~/.ssh/id_rsa`) - generate a new key pair, or copy one in from another path on disk.
4. **Git/GitHub identity** (item 16) - the username and email to use for `git config user.name` / `user.email`.

All four prompts default sensibly and are skipped automatically in non-interactive shells (nothing gets skipped, config files get replaced, new keys get generated).

## Scripts Overview

### Main Setup Script

- **`mac_setup.sh`** - The main orchestrator script that runs all other setup scripts in the correct order

### Configuration Scripts

- **`configure_shell.sh`** - Sets up Zsh with Oh My Zsh, plugins, and useful aliases (including shortcuts into the Documents folder structure)
- **`configure_git.sh`** - Configures Git with user settings, aliases, and global gitignore
- **`configure_ssh.sh`** - Sets up SSH configuration, key management, permissions, and RSA key generation/copy
- **`setup_dev_environment.sh`** - Sets up VS Code settings, installs VS Code extensions directly, and configures Maven/Gradle

### Utility Scripts

- **`switch-java.sh`** - Lists installed Java versions via SDKMAN and shows how to switch
- **`clean-dev.sh`** - Cleans Maven/Gradle caches, prunes Docker, clears npm cache

### Validation Script

- **`validate_setup.sh`** - Read-only script that checks installed tools, config files, and directories, and reports a pass/fail summary. Does not use `set -e`, since its job is to run every check and report a summary rather than abort on the first failure.

## What Gets Installed

### Package Manager
- **Homebrew** - The missing package manager for macOS (installed non-interactively; the "Press RETURN to continue" prompt is bypassed via `NONINTERACTIVE=1`)

### Essential CLI Tools
- **Git** - Version control system (installed first, before any GUI apps)
- **Zsh** - Shell (system default is kept in sync with a Homebrew-managed version)
- **Bash** - A modern Bash via Homebrew (macOS ships a very old 3.2 by default)
- **htop** - Interactive process/resource monitor

### Browsers & Communication
- **Brave Browser**, **Firefox**, **Notion**, **iTerm2**, **Slack**

### Code Editors
- **Sublime Text**, **Visual Studio Code** (installed after Git)

### IDEs & AI Tools
- **IntelliJ IDEA**, **Claude** (Anthropic's desktop app), **Google Antigravity**

### Database GUI Tools
- **Sequel Ace** (MySQL client), **pgAdmin** (PostgreSQL client)

### Java Development Stack
- **SDKMAN** - Java version manager
- **Java 21 & 25** (Amazon Corretto)
- **Maven**, **Gradle** - Build automation tools

### Other Languages
- **Go** - Latest version via Homebrew
- **Scala** - Functional programming language for the JVM

### Protocol Buffers / gRPC Tooling
- **protoc** - Protocol Buffers compiler (Homebrew `protobuf` formula)
- **buf** - Modern protobuf tooling for linting, breaking-change detection, and code generation

### Message Brokers & Streaming
- **Apache Kafka** - Downloaded and extracted to `~/Downloads` (from `archive.apache.org`, which keeps every historical release permanently - see Troubleshooting below for why the previous mirror URL failed)

### Cloud & DevOps Tools
- **AWS CLI**
- **Rancher Desktop** - Container runtime, installed last so nothing earlier in the script blocks waiting on it
- **Docker images** - pulled after Rancher Desktop: `apache/kafka`, `mysql`, `postgres`, `amazon/dynamodb-local`, `localstack` (for SQS), `redis`

## Configuration Details

### Shell Configuration (Zsh)
- **Theme**: robbyrussell (Oh My Zsh default)
- **Plugins**: git, brew, macos, docker, aws, gradle (`maven` is intentionally omitted - Oh My Zsh does not ship a `maven` plugin, and including it produces a `plugin 'maven' not found` error on `source ~/.zshrc`)
- **Custom aliases** for common commands, git, and Docker
- **Documents folder shortcuts** (see below)
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
- **VS Code settings** optimized for Java development (Java 21/25 runtimes, Maven/Gradle paths)
- **VS Code extensions installed directly** via `code --install-extension` (not just a script left behind for you to run manually - see Troubleshooting if `code` isn't found)
- **Maven settings** (`~/.m2/settings.xml`)
- **Gradle properties** (`~/.gradle/gradle.properties`) with performance optimizations

## Documents Folder Structure

`mac_setup.sh` creates a consistent structure under `~/Documents` (note: this replaces the old `~/Development` folder from earlier versions of this script, which is no longer created):

```
~/Documents/
├── official/
│   ├── codebase/
│   ├── docs/
│   ├── scripts/
│   ├── platforms/
│   └── interview/
├── personal/
│   ├── scripts/
│   ├── platform/
│   ├── practice/
│   └── interview/
├── docker-volumes/
├── claude-temp/
└── open-source/
```

Matching `cd` aliases are added to `~/.zshrc` (official-side aliases use the bare name, personal-side aliases are prefixed with `p`):

| Directory | Alias |
|---|---|
| `~/Documents/official` | `official` |
| `~/Documents/official/codebase` | `codebase` |
| `~/Documents/official/docs` | `docs` |
| `~/Documents/official/scripts` | `scripts` |
| `~/Documents/official/platforms` | `platforms` |
| `~/Documents/official/interview` | `interview` |
| `~/Documents/personal` | `personal` |
| `~/Documents/personal/scripts` | `pscripts` |
| `~/Documents/personal/platform` | `pplatform` |
| `~/Documents/personal/practice` | `ppractice` |
| `~/Documents/personal/interview` | `pinterview` |
| `~/Documents/docker-volumes` | `dockervolumes` |
| `~/Documents/claude-temp` | `claudetemp` |
| `~/Documents/open-source` | `opensource` |

## Usage Examples

### Running Individual Scripts

```bash
# Configure shell only
./configure_shell.sh

# Configure Git only
./configure_git.sh

# Configure SSH only
./configure_ssh.sh

# Setup development environment only (VS Code settings/extensions, Maven, Gradle)
./setup_dev_environment.sh
```

### Using Utility Scripts

```bash
# Switch Java versions
./switch-java.sh

# Clean development caches
./clean-dev.sh

# Generate SSH keys
~/.ssh/generate_ssh_key.sh

# Validate the whole setup
./validate_setup.sh
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
scripts         # cd ~/Documents/official/scripts
pscripts        # cd ~/Documents/personal/scripts
dockervolumes   # cd ~/Documents/docker-volumes
```

## Customization

### Modifying User Information

Just answer the "Git/GitHub identity" prompt when running `mac_setup.sh` - no file editing required. To change the fallback defaults (used for non-interactive runs), edit the `GIT_USER_NAME` / `GIT_USER_EMAIL` defaults near the top of `configure_git.sh`.

### Adding More Software

GUI apps are grouped into three associative arrays in `mac_setup.sh` by category - add your app to the relevant one (and add a matching menu line with the next available item number):

```bash
# Browsers & communication (item 4)
declare -A BROWSER_APPS=(
    ["4.1"]="brave-browser"
    ["4.2"]="firefox"
    ["4.3"]="notion"
    ["4.4"]="iterm2"
    ["4.5"]="slack"
    ["4.6"]="your-app-here"
)

# Code editors (item 5)
declare -A EDITOR_APPS=( ["5.1"]="sublime-text" ["5.2"]="visual-studio-code" )

# IDEs & AI tools (item 6)
declare -A IDE_APPS=( ["6.1"]="intellij-idea" ["6.2"]="claude" ["6.3"]="antigravity" )

# Database GUI tools (item 19)
declare -A DB_APPS=( ["19.1"]="sequel-ace" ["19.2"]="pgadmin4" )
```

### Customizing VS Code Extensions

Edit the `VSCODE_EXTENSIONS` array in `setup_dev_environment.sh`. Extensions are installed directly (`code --install-extension`), skipping any already installed.

### Adding Java Versions

Modify the `JAVA_VERSIONS` associative array in `mac_setup.sh` (identifiers are SDKMAN candidate versions - run `sdk list java` to see what's available):

```bash
declare -A JAVA_VERSIONS=(
    ["9.1"]="21.0.11-amzn"
    ["9.2"]="25.0.3-amzn"
    ["9.3"]="your-version-here"
)
```

### Customizing Docker Images

Edit the `DOCKER_IMAGES` array in `mac_setup.sh` (item 21, runs after Rancher Desktop is installed).

## Troubleshooting

### Common Issues

1. **Homebrew installation fails**
   - Ensure you have Xcode Command Line Tools: `xcode-select --install`
   - Check your internet connection

2. **`command not found` errors partway through the script (brew, sdk, code, mvn, ...)**
   - This happens when a tool was installed by a previous run of the script but the *current* shell session never sourced its PATH changes. `mac_setup.sh` now sources Homebrew's `shellenv` and SDKMAN's `sdkman-init.sh` unconditionally at the start of the script (not just right after a fresh install), so this shouldn't recur - but if you still hit it, run `source ~/.zshrc` and re-run the script.

3. **`[oh-my-zsh] plugin 'maven' not found` after `source ~/.zshrc`**
   - Fixed: the `maven` plugin was removed from the Oh My Zsh `plugins=(...)` list in `configure_shell.sh`, since Oh My Zsh doesn't ship one. `gradle` does exist as a plugin and is kept.

4. **Kafka: `tar: Error opening archive: Unrecognized archive format`**
   - Root cause: the old download URL (`downloads.apache.org`) 404s once a Kafka release is superseded on the fast-mirror network, and `curl` (without `-f`) silently saved the 404 HTML error page as if it were the `.tgz`. Fixed by switching to `archive.apache.org` (which retains every historical release permanently), adding `-f` to `curl` so HTTP errors are caught immediately, and adding a `gzip -t` integrity check before extracting - a corrupt/partial archive from a previous failed run is now detected and automatically re-downloaded instead of producing a cryptic tar error.

5. **Homebrew's "Press RETURN to continue" prompt stalls the script**
   - Fixed: the Homebrew installer is now invoked with `NONINTERACTIVE=1`, which skips that confirmation.

6. **SDKMAN installation fails**
   - Restart your terminal after installation
   - Source the configuration: `source ~/.zshrc`

7. **SSH keys not working**
   - Check file permissions: `ls -la ~/.ssh/`
   - Generate new keys: `~/.ssh/generate_ssh_key.sh`

8. **Java versions not switching**
   - Restart terminal or source: `source ~/.zshrc`
   - Check SDKMAN installation: `sdk version`

9. **VS Code extensions didn't install**
   - The `code` CLI must be on PATH (installed automatically alongside the VS Code cask). If item 5.2 (VS Code) was skipped or just installed, re-run `./setup_dev_environment.sh`.

10. **Docker image pulls were skipped / "Docker engine did not become ready in time"**
    - Rancher Desktop needs to be launched from Applications at least once to start its Docker engine; the script waits up to 60 seconds for it. Launch Rancher Desktop, wait for it to finish starting, then re-run item 21 (or the whole script).

### Getting Help

- **Check environment status**: `./validate_setup.sh`
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

A couple of things still need to be installed manually since Homebrew doesn't (or shouldn't) manage them:

### Web Browsers

- **[Arc Browser](https://arc.net/)** - not available as a Homebrew cask
- **Google Chrome** - not automated by this script (Brave and Firefox are); install manually if needed

### App Store Applications

Install the following from the Mac App Store:

- **Numbers** - Apple's spreadsheet application

## Post-Installation

After running the setup scripts:

1. **Restart your terminal** or run `source ~/.zshrc`
2. **Configure AWS credentials**: `aws configure`
3. **Add SSH keys** to your Git hosting services
4. **Launch Rancher Desktop** (if item 20 ran) so item 21's Docker image pulls can complete, or re-run the script afterward
5. **Test your setup**: `./validate_setup.sh`
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
