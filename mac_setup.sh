#!/bin/bash

# Mac Setup Script
# This script automates the setup of a new Mac with all necessary software and configurations
# Based on command history analysis
#
# Every install step checks whether the item is already present before installing it,
# and the user is shown a numbered list of everything that will be done up front so they
# can skip specific items (or whole groups) before anything runs.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

skip_msg() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] SKIPPED: $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "This script is designed for macOS only"
    exit 1
fi

# ==============================================================================
# Skip-list handling
# ==============================================================================
# Items are numbered 1, 2, 3... with sub-items like 3.1, 3.2. Skipping a
# top-level number (e.g. "7") skips all of its sub-items (7.1, 7.2, ...).
# Skipping a specific sub-item (e.g. "7.1") skips only that sub-item.

declare -a SKIP_ITEMS=()

is_skipped() {
    local id="$1"
    local entry
    for entry in "${SKIP_ITEMS[@]}"; do
        # Exact match (covers both top-level ids and sub-item ids)
        if [[ "$entry" == "$id" ]]; then
            return 0
        fi
        # If a top-level number was skipped, skip all its sub-items too.
        if [[ "$id" == "$entry."* ]]; then
            return 0
        fi
    done
    return 1
}

print_menu() {
    echo ""
    echo -e "${BOLD}The following will be checked/installed/configured:${NC}"
    echo ""
    echo "  1. Homebrew (package manager)"
    echo "  2. Update Homebrew"
    echo "  3. Essential CLI tools"
    echo "     3.1 Git"
    echo "     3.2 Zsh"
    echo "  4. GUI applications (Homebrew Cask)"
    echo "     4.1 Visual Studio Code"
    echo "     4.2 iTerm2"
    echo "     4.3 Sublime Text"
    echo "     4.4 Rancher Desktop (Docker runtime)"
    echo "     4.5 Slack"
    echo "  5. Oh My Zsh"
    echo "  6. SDKMAN (Java version manager)"
    echo "  7. Java versions (via SDKMAN)"
    echo "     7.1 Java 21 (amzn) - set as default"
    echo "     7.2 Java 17 (amzn)"
    echo "     7.3 Java 11 (amzn)"
    echo "     7.4 Java 8 (amzn)"
    echo "  8. Build tools"
    echo "     8.1 Maven"
    echo "     8.2 Gradle"
    echo "     8.3 Go"
    echo "     8.4 Scala"
    echo "  9. AWS CLI"
    echo "  10. Kafka (download and extract)"
    echo "  11. SSH directory setup (~/.ssh)"
    echo ""
    echo -e "${BOLD}Configuration changes (items 12-15):${NC}"
    echo -e "${YELLOW}  Note: unlike the install items above, these write to config files that may"
    echo -e "  already exist. By default they REPLACE the existing file (a .backup copy is"
    echo -e "  made first). After this menu you'll get a separate prompt to choose, per item,"
    echo -e "  whether to replace or keep-as-is (skip) any file that already exists.${NC}"
    echo ""
    echo "  12. Shell configuration (configure_shell.sh)"
    echo "      - Overwrites ~/.zshrc (existing file backed up to ~/.zshrc.backup)"
    echo "      - Sets Oh My Zsh theme 'robbyrussell' and plugins (git, brew, macos,"
    echo "        docker, aws, gradle, maven)"
    echo "      - Adds shell aliases (ll, gs, ga, dps, dcup, code., etc.)"
    echo "      - Wires up SDKMAN init, Homebrew shellenv (Apple Silicon), Rancher"
    echo "        Desktop PATH, AWS CLI completion, and zsh history settings"
    echo "  13. Git configuration (configure_git.sh)"
    echo "      - Overwrites ~/.gitconfig (existing file backed up to ~/.gitconfig.backup)"
    echo "      - You'll get a 4th prompt asking for your Git/GitHub username and email"
    echo "        to use for user.name / user.email (defaults to 'Deepanshu Garg' /"
    echo "        'deepanshu.garg@cred.club' if left blank)"
    echo "      - Sets default editor/mergetool/difftool to VS Code, credential.helper"
    echo "        = store, git-lfs filters, Bitbucket HTTPS->SSH URL rewrites"
    echo "      - Creates ~/.gitignore_global and sets core.excludesfile to it"
    echo "      - Adds ~30 git aliases (st, co, br, lg, cleanup, etc.)"
    echo "  14. SSH configuration (configure_ssh.sh)"
    echo "      - Creates ~/.ssh (chmod 700) if it doesn't already exist"
    echo "      - Overwrites ~/.ssh/config (existing file backed up to ~/.ssh/config.backup)"
    echo "      - Adds Host entries for bitbucket.org, github.com, gitlab.com (all"
    echo "        using ~/.ssh/id_rsa) plus keychain/agent settings for Host *"
    echo "      - Fixes permissions on any existing key files and loads them into ssh-agent"
    echo "      - If no RSA key exists yet, you'll get a 3rd prompt asking whether to"
    echo "        COPY an existing key from another path or GENERATE a new one"
    echo "      - Creates ~/.ssh/generate_ssh_key.sh helper script"
    echo "  15. Development environment setup (setup_dev_environment.sh)"
    echo "      - Creates ~/Development/{projects,tools,scripts,workspace}"
    echo "      - Overwrites VS Code ~/Library/Application Support/Code/User/settings.json"
    echo "        (font, formatting, Java runtimes, Maven/Gradle paths, telemetry off)"
    echo "        and writes a curated VS Code extensions list"
    echo "      - Overwrites ~/.m2/settings.xml (Maven) and ~/.gradle/gradle.properties"
    echo "      - Creates helper scripts: switch-java.sh, clean-dev.sh, dev-status.sh,"
    echo "        create-project.sh, install-vscode-extensions.sh"
    echo ""
}

prompt_for_skips() {
    print_menu

    if [ ! -t 0 ]; then
        info "Non-interactive shell detected; running all steps (nothing skipped)."
        return
    fi

    echo -e "${BOLD}Enter a comma-separated list of item numbers to SKIP (e.g. 4.2,7.3,9), or press Enter to skip nothing:${NC}"
    read -r skip_input

    if [ -z "$skip_input" ]; then
        info "No items skipped. Proceeding with full setup."
        return
    fi

    IFS=',' read -ra RAW_SKIPS <<< "$skip_input"
    for raw in "${RAW_SKIPS[@]}"; do
        trimmed=$(echo "$raw" | xargs)
        if [ -n "$trimmed" ]; then
            SKIP_ITEMS+=("$trimmed")
        fi
    done

    if [ ${#SKIP_ITEMS[@]} -gt 0 ]; then
        info "Skipping items: ${SKIP_ITEMS[*]}"
    fi
    echo ""
}

# ==============================================================================
# Config overwrite-mode handling (items 12-15)
# ==============================================================================
# For each configuration item that is going to run, the user chooses whether
# to REPLACE an existing config file (default; a .backup copy is made first)
# or SKIP writing it and keep the existing file untouched.

declare -a CONFIG_KEEP_EXISTING_ITEMS=()

is_keep_existing() {
    local id="$1"
    local entry
    for entry in "${CONFIG_KEEP_EXISTING_ITEMS[@]}"; do
        if [[ "$entry" == "$id" ]]; then
            return 0
        fi
    done
    return 1
}

prompt_for_config_overwrite_mode() {
    # Only ask about config items that are actually going to run.
    local -a eligible=()
    for id in 12 13 14 15; do
        if ! is_skipped "$id"; then
            eligible+=("$id")
        fi
    done

    if [ ${#eligible[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo -e "${BOLD}Configuration file overwrite behavior:${NC}"
    echo "  12. Shell config      -> ~/.zshrc"
    echo "  13. Git config        -> ~/.gitconfig, ~/.gitignore_global"
    echo "  14. SSH config        -> ~/.ssh/config"
    echo "  15. Dev environment   -> VS Code settings.json, ~/.m2/settings.xml, ~/.gradle/gradle.properties"
    echo ""

    if [ ! -t 0 ]; then
        info "Non-interactive shell detected; existing config files will be REPLACED (backed up first)."
        return
    fi

    echo -e "${BOLD}Enter a comma-separated list of item numbers where you want to KEEP existing"
    echo -e "config files as-is (skip writing if the file already exists). Press Enter to"
    echo -e "replace all existing config files (default, with automatic .backup):${NC}"
    read -r keep_input

    if [ -z "$keep_input" ]; then
        info "Existing config files (if any) will be replaced, with backups made first."
        echo ""
        return
    fi

    IFS=',' read -ra RAW_KEEP <<< "$keep_input"
    for raw in "${RAW_KEEP[@]}"; do
        trimmed=$(echo "$raw" | xargs)
        if [ -n "$trimmed" ]; then
            CONFIG_KEEP_EXISTING_ITEMS+=("$trimmed")
        fi
    done

    if [ ${#CONFIG_KEEP_EXISTING_ITEMS[@]} -gt 0 ]; then
        info "Will keep existing config as-is (skip if present) for items: ${CONFIG_KEEP_EXISTING_ITEMS[*]}"
    fi
    echo ""
}

# ==============================================================================
# RSA SSH key handling (item 14)
# ==============================================================================
# If SSH configuration is going to run and no RSA key pair exists yet at
# ~/.ssh/id_rsa, ask whether to copy an existing key pair from elsewhere on
# disk or generate a brand new one.

SSH_KEY_MODE="generate"
SSH_KEY_SOURCE_PATH=""

prompt_for_ssh_key_mode() {
    if is_skipped "14"; then
        return
    fi

    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        info "An RSA key already exists at ~/.ssh/id_rsa; it will be reused as-is."
        return
    fi

    echo ""
    echo -e "${BOLD}RSA SSH key setup (item 14 - no key found at ~/.ssh/id_rsa):${NC}"
    echo "  1) Generate a new RSA key pair (default)"
    echo "  2) Copy an existing RSA key pair from another path on this Mac"
    echo ""

    if [ ! -t 0 ]; then
        info "Non-interactive shell detected; a new RSA key pair will be generated."
        return
    fi

    echo -e "${BOLD}Enter 1 or 2 (press Enter for 1 - generate new):${NC}"
    read -r ssh_key_choice

    if [ -z "$ssh_key_choice" ] || [ "$ssh_key_choice" = "1" ]; then
        info "A new RSA key pair will be generated."
        SSH_KEY_MODE="generate"
        echo ""
        return
    fi

    if [ "$ssh_key_choice" = "2" ]; then
        echo -e "${BOLD}Enter the path to the existing PRIVATE key (its matching .pub will be used if present, e.g. ~/Downloads/id_rsa):${NC}"
        read -r ssh_key_path
        # Expand a leading ~ since we're not going through the shell.
        ssh_key_path="${ssh_key_path/#\~/$HOME}"

        if [ -n "$ssh_key_path" ] && [ -f "$ssh_key_path" ]; then
            SSH_KEY_MODE="copy"
            SSH_KEY_SOURCE_PATH="$ssh_key_path"
            info "Will copy RSA key from: $ssh_key_path"
        else
            warn "No file found at '$ssh_key_path'; falling back to generating a new RSA key pair."
            SSH_KEY_MODE="generate"
        fi
        echo ""
        return
    fi

    warn "Unrecognized choice '$ssh_key_choice'; falling back to generating a new RSA key pair."
    SSH_KEY_MODE="generate"
    echo ""
}

# ==============================================================================
# GitHub identity (item 13)
# ==============================================================================
# If Git configuration is going to run, ask for the username and email to use
# for git's [user] section (i.e. what shows up as the author on commits and
# what GitHub/Bitbucket/GitLab associate with your account).

GIT_USER_NAME="Deepanshu Garg"
GIT_USER_EMAIL="deepanshu.garg@cred.club"

prompt_for_git_identity() {
    if is_skipped "13"; then
        return
    fi

    echo ""
    echo -e "${BOLD}GitHub identity for item 13 (Git configuration):${NC}"
    echo "  This sets git's global user.name and user.email (shows up on every commit"
    echo "  and is how GitHub/Bitbucket/GitLab attribute your commits to your account)."
    echo ""

    if [ ! -t 0 ]; then
        info "Non-interactive shell detected; using default identity: $GIT_USER_NAME <$GIT_USER_EMAIL>"
        return
    fi

    echo -e "${BOLD}Enter your Git/GitHub username (press Enter to keep default '$GIT_USER_NAME'):${NC}"
    read -r git_name_input
    if [ -n "$git_name_input" ]; then
        GIT_USER_NAME="$git_name_input"
    fi

    echo -e "${BOLD}Enter your Git/GitHub email (press Enter to keep default '$GIT_USER_EMAIL'):${NC}"
    read -r git_email_input
    if [ -n "$git_email_input" ]; then
        GIT_USER_EMAIL="$git_email_input"
    fi

    info "Git identity set to: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    echo ""
}

prompt_for_skips
prompt_for_config_overwrite_mode
prompt_for_ssh_key_mode
prompt_for_git_identity

log "Starting Mac Setup Script..."

# ==============================================================================
# 1. Install Homebrew (Package Manager)
# ==============================================================================
if is_skipped "1"; then
    skip_msg "1. Homebrew"
else
    log "Checking Homebrew..."
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        log "Homebrew already installed"
    fi
fi

# ==============================================================================
# 2. Update Homebrew
# ==============================================================================
if is_skipped "2"; then
    skip_msg "2. Update Homebrew"
elif command -v brew &> /dev/null; then
    log "Updating Homebrew..."
    brew update
else
    warn "Homebrew not available; skipping update"
fi

# ==============================================================================
# 3. Essential Development Tools
# ==============================================================================
log "Checking essential development tools..."

# 3.1 Git
if is_skipped "3.1"; then
    skip_msg "3.1 Git"
elif ! command -v git &> /dev/null; then
    log "Installing Git..."
    brew install git
else
    log "Git already installed"
fi

# 3.2 Zsh
if is_skipped "3.2"; then
    skip_msg "3.2 Zsh"
elif ! brew list zsh &> /dev/null; then
    log "Installing Zsh..."
    brew install zsh
else
    log "Zsh already installed"
fi

# ==============================================================================
# 4. Install Applications via Homebrew Cask
# ==============================================================================
log "Checking GUI applications..."

declare -A CASK_APPS=(
    ["4.1"]="visual-studio-code"
    ["4.2"]="iterm2"
    ["4.3"]="sublime-text"
    ["4.4"]="rancher"
    ["4.5"]="slack"
)

for id in 4.1 4.2 4.3 4.4 4.5; do
    app="${CASK_APPS[$id]}"
    if is_skipped "$id"; then
        skip_msg "$id $app"
        continue
    fi
    if ! brew list --cask "$app" &> /dev/null; then
        log "Installing $app..."
        brew install --cask "$app"
    else
        log "$app already installed"
    fi
done

# ==============================================================================
# 5. Install Oh My Zsh
# ==============================================================================
if is_skipped "5"; then
    skip_msg "5. Oh My Zsh"
else
    log "Checking Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log "Oh My Zsh already installed"
    fi
fi

# ==============================================================================
# 6. Install SDKMAN for Java version management
# ==============================================================================
if is_skipped "6"; then
    skip_msg "6. SDKMAN"
else
    log "Checking SDKMAN..."
    if [ ! -d "$HOME/.sdkman" ]; then
        log "Installing SDKMAN..."
        curl -s "https://get.sdkman.io" | bash
    else
        log "SDKMAN already installed"
    fi
fi

if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# ==============================================================================
# 7. Install Java versions
# ==============================================================================
log "Checking Java versions..."

declare -A JAVA_VERSIONS=(
    ["7.1"]="21.0.8-amzn"
    ["7.2"]="17.0.16-amzn"
    ["7.3"]="11.0.28-amzn"
    ["7.4"]="8.0.462-amzn"
)

if ! command -v sdk &> /dev/null; then
    warn "SDKMAN not available; skipping Java version installs"
else
    for id in 7.1 7.2 7.3 7.4; do
        version="${JAVA_VERSIONS[$id]}"
        if is_skipped "$id"; then
            skip_msg "$id Java $version"
            continue
        fi
        if [ -d "$HOME/.sdkman/candidates/java/$version" ]; then
            log "Java $version already installed"
        else
            log "Installing Java $version..."
            sdk install java "$version" < /dev/null || warn "Java $version installation failed"
        fi
    done

    # Set Java 21 as default (only if it was not skipped and is installed)
    if is_skipped "7.1"; then
        skip_msg "Set Java 21 as default (7.1 skipped)"
    elif [ -d "$HOME/.sdkman/candidates/java/${JAVA_VERSIONS[7.1]}" ]; then
        log "Setting Java 21 as default..."
        sdk default java "${JAVA_VERSIONS[7.1]}" || warn "Failed to set Java 21 as default"
    fi
fi

# ==============================================================================
# 8. Install Build Tools
# ==============================================================================
log "Checking build tools..."

# 8.1 Maven
if is_skipped "8.1"; then
    skip_msg "8.1 Maven"
elif ! command -v mvn &> /dev/null; then
    log "Installing Maven..."
    brew install maven
else
    log "Maven already installed"
fi

# 8.2 Gradle
if is_skipped "8.2"; then
    skip_msg "8.2 Gradle"
elif ! command -v gradle &> /dev/null; then
    log "Installing Gradle..."
    brew install gradle
else
    log "Gradle already installed"
fi

# 8.3 Go
if is_skipped "8.3"; then
    skip_msg "8.3 Go"
elif ! command -v go &> /dev/null; then
    log "Installing Go..."
    brew install go
else
    log "Go already installed"
fi

# 8.4 Scala
if is_skipped "8.4"; then
    skip_msg "8.4 Scala"
elif ! command -v scala &> /dev/null; then
    log "Installing Scala..."
    brew install scala
else
    log "Scala already installed"
fi

# ==============================================================================
# 9. Install AWS CLI
# ==============================================================================
if is_skipped "9"; then
    skip_msg "9. AWS CLI"
else
    log "Checking AWS CLI..."
    if ! command -v aws &> /dev/null; then
        log "Downloading and installing AWS CLI..."
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
        sudo installer -pkg "/tmp/AWSCLIV2.pkg" -target /
        rm "/tmp/AWSCLIV2.pkg"
    else
        log "AWS CLI already installed"
    fi
fi

# ==============================================================================
# 10. Download and setup Kafka
# ==============================================================================
if is_skipped "10"; then
    skip_msg "10. Kafka"
else
    log "Checking Kafka..."

    mkdir -p "$HOME/Downloads"

    KAFKA_VERSION="2.13-3.8.1"
    KAFKA_DIR="kafka_${KAFKA_VERSION}"
    KAFKA_FILE="${KAFKA_DIR}.tgz"

    if [ -d "$HOME/Downloads/${KAFKA_DIR}" ]; then
        log "Kafka already extracted at ~/Downloads/${KAFKA_DIR}"
    else
        cd "$HOME/Downloads"
        if [ ! -f "$KAFKA_FILE" ]; then
            log "Downloading Kafka ${KAFKA_VERSION}..."
            curl -L "https://downloads.apache.org/kafka/3.8.1/${KAFKA_FILE}" -o "$KAFKA_FILE"
        else
            log "Kafka archive already downloaded"
        fi

        if [ -f "$KAFKA_FILE" ]; then
            log "Extracting Kafka..."
            tar -xzf "$KAFKA_FILE"
            log "Kafka extracted to ~/Downloads/${KAFKA_DIR}"
        else
            warn "Failed to download Kafka"
        fi
        cd - > /dev/null
    fi
fi

# ==============================================================================
# 11. Create SSH directory if it doesn't exist
# ==============================================================================
if is_skipped "11"; then
    skip_msg "11. SSH directory setup"
else
    log "Checking SSH directory..."
    if [ ! -d "$HOME/.ssh" ]; then
        log "Creating ~/.ssh directory..."
        mkdir -p "$HOME/.ssh"
    else
        log "~/.ssh directory already exists"
    fi
    chmod 700 "$HOME/.ssh"
fi

# ==============================================================================
# 12. Setup shell configuration
# ==============================================================================
if is_skipped "12"; then
    skip_msg "12. Shell configuration"
else
    log "Configuring shell..."
    if is_keep_existing "12"; then
        SHELL_CONFIG_MODE="skip_if_exists" ./configure_shell.sh
    else
        SHELL_CONFIG_MODE="replace" ./configure_shell.sh
    fi
fi

# ==============================================================================
# 13. Setup Git configuration
# ==============================================================================
if is_skipped "13"; then
    skip_msg "13. Git configuration"
else
    log "Configuring Git..."
    if is_keep_existing "13"; then
        GIT_CONFIG_MODE="skip_if_exists" GIT_USER_NAME="$GIT_USER_NAME" GIT_USER_EMAIL="$GIT_USER_EMAIL" ./configure_git.sh
    else
        GIT_CONFIG_MODE="replace" GIT_USER_NAME="$GIT_USER_NAME" GIT_USER_EMAIL="$GIT_USER_EMAIL" ./configure_git.sh
    fi
fi

# ==============================================================================
# 14. Setup SSH configuration
# ==============================================================================
if is_skipped "14"; then
    skip_msg "14. SSH configuration"
else
    log "Configuring SSH..."
    if is_keep_existing "14"; then
        SSH_CONFIG_MODE="skip_if_exists" SSH_KEY_MODE="$SSH_KEY_MODE" SSH_KEY_SOURCE_PATH="$SSH_KEY_SOURCE_PATH" ./configure_ssh.sh
    else
        SSH_CONFIG_MODE="replace" SSH_KEY_MODE="$SSH_KEY_MODE" SSH_KEY_SOURCE_PATH="$SSH_KEY_SOURCE_PATH" ./configure_ssh.sh
    fi
fi

# ==============================================================================
# 15. Setup development environment
# ==============================================================================
if is_skipped "15"; then
    skip_msg "15. Development environment setup"
else
    log "Setting up development environment..."
    if is_keep_existing "15"; then
        DEVENV_CONFIG_MODE="skip_if_exists" ./setup_dev_environment.sh
    else
        DEVENV_CONFIG_MODE="replace" ./setup_dev_environment.sh
    fi
fi

log "Mac setup completed successfully!"
log "Please restart your terminal or run 'source ~/.zshrc' to apply all changes"

info "Next steps:"
info "1. Configure your Git credentials if not already done"
info "2. Add your SSH keys to ~/.ssh/"
info "3. Configure AWS credentials using 'aws configure'"
info "4. Install any additional software specific to your projects"
