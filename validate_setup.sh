#!/bin/bash

# Setup Validation Script
# Tests the Mac setup to ensure everything is working correctly
#
# Deliberately does NOT use `set -e`: this script's job is to run every
# check and report a pass/fail summary at the end, so an individual failed
# check (a missing tool, a missing file) must not abort the whole run.

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

success_count=0
total_checks=0

check_command() {
    local cmd=$1
    local name=$2
    total_checks=$((total_checks + 1))

    if command -v "$cmd" &> /dev/null; then
        log "✓ $name is installed"
        success_count=$((success_count + 1))
        return 0
    else
        error "✗ $name is not installed"
        return 1
    fi
}

check_file() {
    local file=$1
    local name=$2
    total_checks=$((total_checks + 1))

    if [ -f "$file" ]; then
        log "✓ $name exists"
        success_count=$((success_count + 1))
        return 0
    else
        error "✗ $name does not exist"
        return 1
    fi
}

check_directory() {
    local dir=$1
    local name=$2
    total_checks=$((total_checks + 1))

    if [ -d "$dir" ]; then
        log "✓ $name exists"
        success_count=$((success_count + 1))
        return 0
    else
        error "✗ $name does not exist"
        return 1
    fi
}

check_cask() {
    local cask=$1
    local name=$2
    total_checks=$((total_checks + 1))

    if brew list --cask "$cask" &> /dev/null; then
        log "✓ $name is installed"
        success_count=$((success_count + 1))
        return 0
    else
        warn "$name not found (brew cask: $cask)"
        return 1
    fi
}

log "Starting Mac Setup Validation..."
echo ""

# Check essential commands
info "Checking essential commands..."
check_command "brew" "Homebrew"
check_command "git" "Git"
check_command "zsh" "Zsh"
check_command "bash" "Bash (Homebrew)"
check_command "htop" "htop"
check_command "code" "VS Code"
check_command "subl" "Sublime Text"
check_command "mvn" "Maven"
check_command "gradle" "Gradle"
check_command "aws" "AWS CLI"
check_command "docker" "Docker (via Rancher Desktop)"
check_command "go" "Go"
check_command "scala" "Scala"
check_command "protoc" "protoc (Protocol Buffers)"
check_command "buf" "buf"

echo ""

# Check GUI apps (Homebrew Cask)
info "Checking GUI applications..."
check_cask "brave-browser" "Brave Browser"
check_cask "firefox" "Firefox"
check_cask "notion" "Notion"
check_cask "iterm2" "iTerm2"
check_cask "slack" "Slack"
check_cask "intellij-idea" "IntelliJ IDEA"
check_cask "claude" "Claude (desktop app)"
check_cask "antigravity" "Google Antigravity"
check_cask "sequel-ace" "Sequel Ace"
check_cask "pgadmin4" "pgAdmin"
check_cask "rancher" "Rancher Desktop"

echo ""

# Check SDKMAN and Java
info "Checking Java environment..."
if [ -d "$HOME/.sdkman" ]; then
    log "✓ SDKMAN is installed"
    success_count=$((success_count + 1))

    # Source SDKMAN
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    if command -v java &> /dev/null; then
        log "✓ Java is available"
        success_count=$((success_count + 1))
        info "Current Java version: $(java -version 2>&1 | head -1)"
    else
        error "✗ Java is not available"
    fi

    for version in "21.0.11-amzn" "25.0.3-amzn"; do
        total_checks=$((total_checks + 1))
        if [ -d "$HOME/.sdkman/candidates/java/$version" ]; then
            log "✓ Java $version is installed"
            success_count=$((success_count + 1))
        else
            warn "Java $version not found"
        fi
    done
else
    error "✗ SDKMAN is not installed"
fi
total_checks=$((total_checks + 2))

echo ""

# Check configuration files
info "Checking configuration files..."
check_file "$HOME/.zshrc" "Zsh configuration"
check_file "$HOME/.gitconfig" "Git configuration"
check_file "$HOME/.ssh/config" "SSH configuration"
check_file "$HOME/.m2/settings.xml" "Maven settings"
check_file "$HOME/.gradle/gradle.properties" "Gradle properties"
check_file "$HOME/Library/Application Support/Code/User/settings.json" "VS Code settings"

echo ""

# Check Documents folder structure
info "Checking Documents folder structure..."
check_directory "$HOME/Documents/official" "Documents/official"
check_directory "$HOME/Documents/official/codebase" "Documents/official/codebase"
check_directory "$HOME/Documents/official/docs" "Documents/official/docs"
check_directory "$HOME/Documents/official/scripts" "Documents/official/scripts"
check_directory "$HOME/Documents/official/platforms" "Documents/official/platforms"
check_directory "$HOME/Documents/official/interview" "Documents/official/interview"
check_directory "$HOME/Documents/personal" "Documents/personal"
check_directory "$HOME/Documents/personal/scripts" "Documents/personal/scripts"
check_directory "$HOME/Documents/personal/platform" "Documents/personal/platform"
check_directory "$HOME/Documents/personal/practice" "Documents/personal/practice"
check_directory "$HOME/Documents/personal/interview" "Documents/personal/interview"
check_directory "$HOME/Documents/docker-volumes" "Documents/docker-volumes"
check_directory "$HOME/Documents/claude-temp" "Documents/claude-temp"
check_directory "$HOME/Documents/open-source" "Documents/open-source"

echo ""

# Check utility scripts (checked into this repo, not generated at runtime)
info "Checking utility scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check_file "$SCRIPT_DIR/switch-java.sh" "Java switcher script"
check_file "$SCRIPT_DIR/clean-dev.sh" "Development cleaner script"

echo ""

# Check SSH setup
info "Checking SSH setup..."
if [ -f "$HOME/.ssh/id_rsa" ]; then
    log "✓ SSH private key exists"
    success_count=$((success_count + 1))

    # Check permissions
    perms=$(stat -f "%A" "$HOME/.ssh/id_rsa" 2>/dev/null || echo "unknown")
    if [ "$perms" = "600" ]; then
        log "✓ SSH private key has correct permissions (600)"
        success_count=$((success_count + 1))
    else
        warn "SSH private key permissions: $perms (should be 600)"
    fi
else
    warn "SSH private key not found (this is normal for new setups)"
fi

if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    log "✓ SSH public key exists"
    success_count=$((success_count + 1))
else
    warn "SSH public key not found (this is normal for new setups)"
fi
total_checks=$((total_checks + 3))

echo ""

# Check Oh My Zsh
info "Checking Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "✓ Oh My Zsh is installed"
    success_count=$((success_count + 1))
else
    error "✗ Oh My Zsh is not installed"
fi
total_checks=$((total_checks + 1))

echo ""

# Check Kafka
info "Checking Kafka..."
if [ -d "$HOME/Downloads/kafka_2.13-3.8.1" ] && [ -f "$HOME/Downloads/kafka_2.13-3.8.1/bin/kafka-server-start.sh" ]; then
    log "✓ Kafka is downloaded and extracted to ~/Downloads/kafka_2.13-3.8.1"
    success_count=$((success_count + 1))
else
    warn "Kafka not found under ~/Downloads"
fi
total_checks=$((total_checks + 1))

echo ""

# Check Docker images (only meaningful if the docker engine is up)
info "Checking Docker images..."
if command -v docker &> /dev/null && docker info &> /dev/null; then
    for image in "apache/kafka:latest" "mysql:latest" "postgres:latest" "amazon/dynamodb-local:latest" "localstack/localstack:latest" "redis:latest"; do
        total_checks=$((total_checks + 1))
        if docker image inspect "$image" &> /dev/null; then
            log "✓ Docker image present: $image"
            success_count=$((success_count + 1))
        else
            warn "Docker image not found: $image"
        fi
    done
else
    warn "Docker engine not reachable; skipping image checks. Launch Rancher Desktop first."
fi

echo ""

# Summary
log "Validation Summary"
log "=================="
log "Successful checks: $success_count/$total_checks"

if [ $success_count -eq $total_checks ]; then
    log "🎉 All checks passed! Your Mac setup is complete."
elif [ $success_count -gt $((total_checks * 3 / 4)) ]; then
    warn "⚠️  Most checks passed. Some optional components may be missing."
else
    error "❌ Several checks failed. Please review the setup."
fi

echo ""
info "Next steps:"
info "1. Restart your terminal or run 'source ~/.zshrc'"
info "2. Configure AWS credentials: aws configure"
info "3. Generate SSH keys if needed: ~/.ssh/generate_ssh_key.sh"
info "4. Launch Rancher Desktop if Docker images are missing, then re-run this script"

log "Validation completed!"
