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

# Highest top-level item number in the menu below. Used to validate skip
# ranges like "1-5" entered at the skip-items prompt.
MAX_ITEM_NUMBER=21

# Source Homebrew/SDKMAN shell integration unconditionally up front, in case
# they were installed by a previous run of this script but this invocation's
# shell doesn't have them on PATH yet (this is what causes "command not
# found" errors mid-script when e.g. brew or sdk was already installed).
if [ -d /opt/homebrew/bin ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# ==============================================================================
# Skip-list handling
# ==============================================================================
# Items are numbered 1, 2, 3... with sub-items like 3.1, 3.2. Skipping a
# top-level number (e.g. "7") skips all of its sub-items (7.1, 7.2, ...).
# Skipping a specific sub-item (e.g. "7.1") skips only that sub-item.
# You can also skip a contiguous range of top-level items with "N-M"
# (e.g. "1-5" skips items 1 through 5 inclusive, including all their
# sub-items). Ranges and individual items can be mixed, comma-separated
# (e.g. "1-5,7.2,9").

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
    echo "     3.3 Bash (newer version via Homebrew)"
    echo "     3.4 htop"
    echo "  4. Browsers & communication apps (Homebrew Cask)"
    echo "     4.1 Brave Browser"
    echo "     4.2 Firefox"
    echo "     4.3 Notion"
    echo "     4.4 iTerm2"
    echo "     4.5 Slack"
    echo "  5. Code editors (Homebrew Cask) - installed after Git (3.1)"
    echo "     5.1 Sublime Text"
    echo "     5.2 Visual Studio Code"
    echo "  6. IDEs & AI tools (Homebrew Cask)"
    echo "     6.1 IntelliJ IDEA"
    echo "     6.2 Claude (desktop app)"
    echo "     6.3 Google Antigravity"
    echo "  7. Oh My Zsh"
    echo "  8. SDKMAN (Java version manager)"
    echo "  9. Java versions (via SDKMAN)"
    echo "     9.1 Java 21 (amzn) - set as default"
    echo "     9.2 Java 25 (amzn)"
    echo "  10. Build tools"
    echo "      10.1 Maven"
    echo "      10.2 Gradle"
    echo "      10.3 Go (latest)"
    echo "      10.4 Scala"
    echo "  11. AWS CLI"
    echo "  12. Kafka (download and extract)"
    echo "  13. SSH directory setup (~/.ssh)"
    echo "  14. Documents folder structure"
    echo "      - ~/Documents/official/{codebase,docs,scripts,platforms,interview}"
    echo "      - ~/Documents/personal/{scripts,platform,practice,interview}"
    echo "      - ~/Documents/{docker-volumes,claude-temp,open-source}"
    echo ""
    echo -e "${BOLD}Configuration changes (items 15-18):${NC}"
    echo -e "${YELLOW}  Note: unlike the install items above, these write to config files that may"
    echo -e "  already exist. By default they REPLACE the existing file (a .backup copy is"
    echo -e "  made first). After this menu you'll get a separate prompt to choose, per item,"
    echo -e "  whether to replace or keep-as-is (skip) any file that already exists.${NC}"
    echo ""
    echo "  15. Shell configuration (configure_shell.sh)"
    echo "      - Overwrites ~/.zshrc (existing file backed up to ~/.zshrc.backup)"
    echo "      - Sets Oh My Zsh theme 'robbyrussell' and plugins (git, brew, macos,"
    echo "        docker, aws, gradle)"
    echo "      - Adds shell aliases (ll, gs, ga, dps, dcup, code., etc.) plus cd"
    echo "        shortcuts into the Documents folders created by item 14"
    echo "      - Wires up SDKMAN init, Homebrew shellenv, Rancher Desktop PATH,"
    echo "        AWS CLI completion, and zsh history settings"
    echo "  16. Git configuration (configure_git.sh)"
    echo "      - Overwrites ~/.gitconfig (existing file backed up to ~/.gitconfig.backup)"
    echo "      - You'll get a 4th prompt asking for your Git/GitHub username and email"
    echo "        to use for user.name / user.email (defaults to 'Deepanshu Garg' /"
    echo "        'deepanshu.garg@cred.club' if left blank)"
    echo "      - Sets default editor/mergetool/difftool to VS Code, credential.helper"
    echo "        = store, git-lfs filters, Bitbucket HTTPS->SSH URL rewrites"
    echo "      - Creates ~/.gitignore_global and sets core.excludesfile to it"
    echo "      - Adds ~30 git aliases (st, co, br, lg, cleanup, etc.)"
    echo "  17. SSH configuration (configure_ssh.sh)"
    echo "      - Creates ~/.ssh (chmod 700) if it doesn't already exist"
    echo "      - Overwrites ~/.ssh/config (existing file backed up to ~/.ssh/config.backup)"
    echo "      - Adds Host entries for bitbucket.org, github.com, gitlab.com (all"
    echo "        using ~/.ssh/id_rsa) plus keychain/agent settings for Host *"
    echo "      - Fixes permissions on any existing key files and loads them into ssh-agent"
    echo "      - If no RSA key exists yet, you'll get a 3rd prompt asking whether to"
    echo "        COPY an existing key from another path or GENERATE a new one"
    echo "      - Creates ~/.ssh/generate_ssh_key.sh helper script"
    echo "  18. Development environment setup (setup_dev_environment.sh)"
    echo "      - Overwrites VS Code ~/Library/Application Support/Code/User/settings.json"
    echo "        (font, formatting, Java runtimes, Maven/Gradle paths, telemetry off)"
    echo "      - Installs VS Code extensions directly (code --install-extension)"
    echo "      - Overwrites ~/.m2/settings.xml (Maven) and ~/.gradle/gradle.properties"
    echo ""
    echo -e "${BOLD}Final steps:${NC}"
    echo "  19. Database GUI tools (Homebrew Cask)"
    echo "      19.1 Sequel Ace"
    echo "      19.2 pgAdmin"
    echo "  20. Rancher Desktop (Docker runtime) - installed last so nothing above"
    echo "      blocks waiting on it"
    echo "  21. Fetch Docker images (Kafka, MySQL, PostgreSQL, DynamoDB Local,"
    echo "      LocalStack for SQS, Redis) - requires Rancher Desktop's Docker"
    echo "      engine to be running"
    echo ""
}

prompt_for_skips() {
    print_menu

    if [ ! -t 0 ]; then
        info "Non-interactive shell detected; running all steps (nothing skipped)."
        return
    fi

    echo -e "${BOLD}Enter a comma-separated list of item numbers to SKIP.${NC}"
    echo "Examples: '4.2,7.3,9' (specific items), '1-5' (range - skips items 1 through 5"
    echo "and all their sub-items), or '1-5,9,12.2' (mixed). Press Enter to skip nothing:"
    read -r skip_input

    if [ -z "$skip_input" ]; then
        info "No items skipped. Proceeding with full setup."
        return
    fi

    IFS=',' read -ra RAW_SKIPS <<< "$skip_input"
    for raw in "${RAW_SKIPS[@]}"; do
        trimmed=$(echo "$raw" | xargs)
        if [ -z "$trimmed" ]; then
            continue
        fi

        if [[ "$trimmed" == *-* ]]; then
            if [[ "$trimmed" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                range_start="${BASH_REMATCH[1]}"
                range_end="${BASH_REMATCH[2]}"
                if [ "$range_start" -ge 1 ] && [ "$range_end" -le "$MAX_ITEM_NUMBER" ] && [ "$range_start" -lt "$range_end" ]; then
                    for ((range_i = range_start; range_i <= range_end; range_i++)); do
                        SKIP_ITEMS+=("$range_i")
                    done
                else
                    error "Invalid skip range '$trimmed': must satisfy 1 <= start < end <= $MAX_ITEM_NUMBER. Ignoring this entry."
                fi
            else
                error "Invalid skip range format '$trimmed' (expected e.g. '1-5'). Ignoring this entry."
            fi
        else
            SKIP_ITEMS+=("$trimmed")
        fi
    done

    if [ ${#SKIP_ITEMS[@]} -gt 0 ]; then
        info "Skipping items: ${SKIP_ITEMS[*]}"
    fi
    echo ""
}

# ==============================================================================
# Config overwrite-mode handling (items 15-18)
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
    for id in 15 16 17 18; do
        if ! is_skipped "$id"; then
            eligible+=("$id")
        fi
    done

    if [ ${#eligible[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo -e "${BOLD}Configuration file overwrite behavior:${NC}"
    echo "  15. Shell config      -> ~/.zshrc"
    echo "  16. Git config        -> ~/.gitconfig, ~/.gitignore_global"
    echo "  17. SSH config        -> ~/.ssh/config"
    echo "  18. Dev environment   -> VS Code settings.json, ~/.m2/settings.xml, ~/.gradle/gradle.properties"
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
# RSA SSH key handling (item 17)
# ==============================================================================
# If SSH configuration is going to run and no RSA key pair exists yet at
# ~/.ssh/id_rsa, ask whether to copy an existing key pair from elsewhere on
# disk or generate a brand new one.

SSH_KEY_MODE="generate"
SSH_KEY_SOURCE_PATH=""

prompt_for_ssh_key_mode() {
    if is_skipped "17"; then
        return
    fi

    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        info "An RSA key already exists at ~/.ssh/id_rsa; it will be reused as-is."
        return
    fi

    echo ""
    echo -e "${BOLD}RSA SSH key setup (item 17 - no key found at ~/.ssh/id_rsa):${NC}"
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
# GitHub identity (item 16)
# ==============================================================================
# If Git configuration is going to run, ask for the username and email to use
# for git's [user] section (i.e. what shows up as the author on commits and
# what GitHub/Bitbucket/GitLab associate with your account).

GIT_USER_NAME="Deepanshu Garg"
GIT_USER_EMAIL="deepanshu.garg@cred.club"

prompt_for_git_identity() {
    if is_skipped "16"; then
        return
    fi

    echo ""
    echo -e "${BOLD}GitHub identity for item 16 (Git configuration):${NC}"
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
        # NONINTERACTIVE=1 skips Homebrew's "Press RETURN to continue" prompt
        # so the script doesn't stall waiting for a keypress.
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew already installed"
    fi

    # Source unconditionally (fresh install or pre-existing) so every step
    # below this point in the same run has a working `brew` on PATH.
    if [ -d /opt/homebrew/bin ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
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

# 3.1 Git (installed first, since other tools below may depend on it)
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

# 3.3 Bash (newer version than macOS's built-in bash 3.2)
if is_skipped "3.3"; then
    skip_msg "3.3 Bash"
elif ! brew list bash &> /dev/null; then
    log "Installing Bash..."
    brew install bash
else
    log "Bash already installed"
fi

# 3.4 htop
if is_skipped "3.4"; then
    skip_msg "3.4 htop"
elif ! brew list htop &> /dev/null; then
    log "Installing htop..."
    brew install htop
else
    log "htop already installed"
fi

# ==============================================================================
# 4. Browsers & communication apps (Homebrew Cask)
# ==============================================================================
log "Checking browsers & communication apps..."

declare -A BROWSER_APPS=(
    ["4.1"]="brave-browser"
    ["4.2"]="firefox"
    ["4.3"]="notion"
    ["4.4"]="iterm2"
    ["4.5"]="slack"
)

for id in 4.1 4.2 4.3 4.4 4.5; do
    app="${BROWSER_APPS[$id]}"
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
# 5. Code editors (Homebrew Cask) - runs after Git (3.1)
# ==============================================================================
log "Checking code editors..."

declare -A EDITOR_APPS=(
    ["5.1"]="sublime-text"
    ["5.2"]="visual-studio-code"
)

for id in 5.1 5.2; do
    app="${EDITOR_APPS[$id]}"
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
# 6. IDEs & AI tools (Homebrew Cask)
# ==============================================================================
log "Checking IDEs & AI tools..."

declare -A IDE_APPS=(
    ["6.1"]="intellij-idea"
    ["6.2"]="claude"
    ["6.3"]="antigravity"
)

for id in 6.1 6.2 6.3; do
    app="${IDE_APPS[$id]}"
    if is_skipped "$id"; then
        skip_msg "$id $app"
        continue
    fi
    if ! brew list --cask "$app" &> /dev/null; then
        log "Installing $app..."
        brew install --cask "$app" || warn "Failed to install $app (cask may have been renamed/removed upstream)"
    else
        log "$app already installed"
    fi
done

# ==============================================================================
# 7. Install Oh My Zsh
# ==============================================================================
if is_skipped "7"; then
    skip_msg "7. Oh My Zsh"
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
# 8. Install SDKMAN for Java version management
# ==============================================================================
if is_skipped "8"; then
    skip_msg "8. SDKMAN"
else
    log "Checking SDKMAN..."
    if [ ! -d "$HOME/.sdkman" ]; then
        log "Installing SDKMAN..."
        curl -s "https://get.sdkman.io" | bash
    else
        log "SDKMAN already installed"
    fi
fi

# Source unconditionally so items 9+ below can use `sdk` in this same run.
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# ==============================================================================
# 9. Install Java versions
# ==============================================================================
log "Checking Java versions..."

declare -A JAVA_VERSIONS=(
    ["9.1"]="21.0.11-amzn"
    ["9.2"]="25.0.3-amzn"
)

if ! command -v sdk &> /dev/null; then
    warn "SDKMAN not available; skipping Java version installs"
else
    for id in 9.1 9.2; do
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
    if is_skipped "9.1"; then
        skip_msg "Set Java 21 as default (9.1 skipped)"
    elif [ -d "$HOME/.sdkman/candidates/java/${JAVA_VERSIONS[9.1]}" ]; then
        log "Setting Java 21 as default..."
        sdk default java "${JAVA_VERSIONS[9.1]}" || warn "Failed to set Java 21 as default"
    fi
fi

# ==============================================================================
# 10. Install Build Tools
# ==============================================================================
log "Checking build tools..."

# 10.1 Maven
if is_skipped "10.1"; then
    skip_msg "10.1 Maven"
elif ! command -v mvn &> /dev/null; then
    log "Installing Maven..."
    brew install maven
else
    log "Maven already installed"
fi

# 10.2 Gradle
if is_skipped "10.2"; then
    skip_msg "10.2 Gradle"
elif ! command -v gradle &> /dev/null; then
    log "Installing Gradle..."
    brew install gradle
else
    log "Gradle already installed"
fi

# 10.3 Go (latest formula version)
if is_skipped "10.3"; then
    skip_msg "10.3 Go"
elif ! command -v go &> /dev/null; then
    log "Installing Go..."
    brew install go
else
    log "Go already installed"
fi

# 10.4 Scala
if is_skipped "10.4"; then
    skip_msg "10.4 Scala"
elif ! command -v scala &> /dev/null; then
    log "Installing Scala..."
    brew install scala
else
    log "Scala already installed"
fi

# ==============================================================================
# 11. Install AWS CLI
# ==============================================================================
if is_skipped "11"; then
    skip_msg "11. AWS CLI"
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
# 12. Download and setup Kafka
# ==============================================================================
if is_skipped "12"; then
    skip_msg "12. Kafka"
else
    log "Checking Kafka..."

    mkdir -p "$HOME/Downloads"

    KAFKA_VERSION="2.13-3.8.1"
    KAFKA_DIR="kafka_${KAFKA_VERSION}"
    KAFKA_FILE="${KAFKA_DIR}.tgz"
    # archive.apache.org keeps every historical release permanently; the
    # downloads.apache.org mirror network 404s once a release is superseded,
    # which is what caused "tar: Unrecognized archive format" (curl silently
    # saved the 404 HTML page as the .tgz).
    KAFKA_URL="https://archive.apache.org/dist/kafka/3.8.1/${KAFKA_FILE}"

    if [ -d "$HOME/Downloads/${KAFKA_DIR}" ]; then
        log "Kafka already extracted at ~/Downloads/${KAFKA_DIR}"
    else
        cd "$HOME/Downloads"

        # If a previous run left behind a corrupt/partial archive, remove it
        # so we re-download instead of trying to extract garbage.
        if [ -f "$KAFKA_FILE" ] && ! gzip -t "$KAFKA_FILE" 2>/dev/null; then
            warn "Existing Kafka archive is corrupt/incomplete; re-downloading..."
            rm -f "$KAFKA_FILE"
        fi

        if [ ! -f "$KAFKA_FILE" ]; then
            log "Downloading Kafka ${KAFKA_VERSION}..."
            if ! curl -fL "$KAFKA_URL" -o "$KAFKA_FILE"; then
                error "Failed to download Kafka from $KAFKA_URL"
                rm -f "$KAFKA_FILE"
            fi
        else
            log "Kafka archive already downloaded"
        fi

        if [ -f "$KAFKA_FILE" ] && gzip -t "$KAFKA_FILE" 2>/dev/null; then
            log "Extracting Kafka..."
            tar -xzf "$KAFKA_FILE"
            log "Kafka extracted to ~/Downloads/${KAFKA_DIR}"
        elif [ -f "$KAFKA_FILE" ]; then
            error "Downloaded Kafka archive failed integrity check; removing it"
            rm -f "$KAFKA_FILE"
        fi
        cd - > /dev/null
    fi
fi

# ==============================================================================
# 13. Create SSH directory if it doesn't exist
# ==============================================================================
if is_skipped "13"; then
    skip_msg "13. SSH directory setup"
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
# 14. Documents folder structure
# ==============================================================================
if is_skipped "14"; then
    skip_msg "14. Documents folder structure"
else
    log "Setting up Documents folder structure..."
    mkdir -p ~/Documents/official/{codebase,docs,scripts,platforms,interview}
    mkdir -p ~/Documents/personal/{scripts,platform,practice,interview}
    mkdir -p ~/Documents/docker-volumes
    mkdir -p ~/Documents/claude-temp
    mkdir -p ~/Documents/open-source
    log "Documents folder structure ready under ~/Documents"
fi

# ==============================================================================
# 15. Setup shell configuration
# ==============================================================================
if is_skipped "15"; then
    skip_msg "15. Shell configuration"
else
    log "Configuring shell..."
    if is_keep_existing "15"; then
        SHELL_CONFIG_MODE="skip_if_exists" ./configure_shell.sh
    else
        SHELL_CONFIG_MODE="replace" ./configure_shell.sh
    fi
fi

# ==============================================================================
# 16. Setup Git configuration
# ==============================================================================
if is_skipped "16"; then
    skip_msg "16. Git configuration"
else
    log "Configuring Git..."
    if is_keep_existing "16"; then
        GIT_CONFIG_MODE="skip_if_exists" GIT_USER_NAME="$GIT_USER_NAME" GIT_USER_EMAIL="$GIT_USER_EMAIL" ./configure_git.sh
    else
        GIT_CONFIG_MODE="replace" GIT_USER_NAME="$GIT_USER_NAME" GIT_USER_EMAIL="$GIT_USER_EMAIL" ./configure_git.sh
    fi
fi

# ==============================================================================
# 17. Setup SSH configuration
# ==============================================================================
if is_skipped "17"; then
    skip_msg "17. SSH configuration"
else
    log "Configuring SSH..."
    if is_keep_existing "17"; then
        SSH_CONFIG_MODE="skip_if_exists" SSH_KEY_MODE="$SSH_KEY_MODE" SSH_KEY_SOURCE_PATH="$SSH_KEY_SOURCE_PATH" ./configure_ssh.sh
    else
        SSH_CONFIG_MODE="replace" SSH_KEY_MODE="$SSH_KEY_MODE" SSH_KEY_SOURCE_PATH="$SSH_KEY_SOURCE_PATH" ./configure_ssh.sh
    fi
fi

# ==============================================================================
# 18. Setup development environment
# ==============================================================================
if is_skipped "18"; then
    skip_msg "18. Development environment setup"
else
    log "Setting up development environment..."
    if is_keep_existing "18"; then
        DEVENV_CONFIG_MODE="skip_if_exists" ./setup_dev_environment.sh
    else
        DEVENV_CONFIG_MODE="replace" ./setup_dev_environment.sh
    fi
fi

# ==============================================================================
# 19. Database GUI tools (Homebrew Cask)
# ==============================================================================
log "Checking database GUI tools..."

declare -A DB_APPS=(
    ["19.1"]="sequel-ace"
    ["19.2"]="pgadmin4"
)

for id in 19.1 19.2; do
    app="${DB_APPS[$id]}"
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
# 20. Rancher Desktop (Docker runtime) - installed last so nothing above waits on it
# ==============================================================================
if is_skipped "20"; then
    skip_msg "20. Rancher Desktop"
else
    log "Checking Rancher Desktop..."
    if ! brew list --cask rancher &> /dev/null; then
        log "Installing Rancher Desktop..."
        brew install --cask rancher
        info "Rancher Desktop installed. Launch it from Applications to start the Docker engine."
    else
        log "Rancher Desktop already installed"
    fi
fi

# ==============================================================================
# 21. Fetch Docker images (requires Rancher Desktop's Docker engine running)
# ==============================================================================
DOCKER_IMAGES=(
    "apache/kafka:latest"
    "mysql:latest"
    "postgres:latest"
    "amazon/dynamodb-local:latest"
    "localstack/localstack:latest"
    "redis:latest"
)

if is_skipped "21"; then
    skip_msg "21. Fetch Docker images"
else
    log "Fetching Docker images..."
    if ! command -v docker &> /dev/null; then
        warn "docker CLI not found; skipping image pulls. Install/launch Rancher Desktop (item 20) first."
    else
        log "Waiting for Docker engine to become available (up to 60s)..."
        docker_ready=false
        for i in $(seq 1 12); do
            if docker info &> /dev/null; then
                docker_ready=true
                break
            fi
            sleep 5
        done

        if [ "$docker_ready" = true ]; then
            for image in "${DOCKER_IMAGES[@]}"; do
                log "Pulling $image..."
                docker pull "$image" || warn "Failed to pull $image"
            done
        else
            warn "Docker engine did not become ready in time. Launch Rancher Desktop manually, then run:"
            for image in "${DOCKER_IMAGES[@]}"; do
                info "  docker pull $image"
            done
        fi
    fi
fi

log "Mac setup completed successfully!"
log "Please restart your terminal or run 'source ~/.zshrc' to apply all changes"

info "Next steps:"
info "1. Configure your Git credentials if not already done"
info "2. Add your SSH keys to ~/.ssh/"
info "3. Configure AWS credentials using 'aws configure'"
info "4. Install any additional software specific to your projects"
