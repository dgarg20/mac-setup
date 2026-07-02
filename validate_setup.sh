#!/bin/bash

# Setup Validation Script
# Tests the Mac setup to ensure everything is working correctly

set -e

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

log "Starting Mac Setup Validation..."
echo ""

# Check essential commands
info "Checking essential commands..."
check_command "brew" "Homebrew"
check_command "git" "Git"
check_command "zsh" "Zsh"
check_command "code" "VS Code"
check_command "mvn" "Maven"
check_command "gradle" "Gradle"
check_command "aws" "AWS CLI"
check_command "docker" "Docker (via Rancher Desktop)"
check_command "go" "Go"
check_command "scala" "Scala"

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

echo ""

# Check directories
info "Checking development directories..."
check_directory "$HOME/Development" "Development directory"
check_directory "$HOME/Development/projects" "Projects directory"
check_directory "$HOME/Development/scripts" "Scripts directory"
check_directory "$HOME/Development/tools" "Tools directory"

echo ""

# Check utility scripts
info "Checking utility scripts..."
check_file "$HOME/Development/scripts/dev-status.sh" "Development status script"
check_file "$HOME/Development/scripts/switch-java.sh" "Java switcher script"
check_file "$HOME/Development/scripts/clean-dev.sh" "Development cleaner script"
check_file "$HOME/Development/scripts/create-project.sh" "Project creator script"
check_file "$HOME/Development/tools/install-vscode-extensions.sh" "VS Code extensions installer"

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

# Check Kafka and Pulsar
info "Checking Kafka and Pulsar..."
if [ -L "$HOME/Development/tools/kafka" ] && [ -d "$HOME/Development/tools/kafka" ]; then
    log "✓ Kafka is installed and linked"
    success_count=$((success_count + 1))
else
    warn "Kafka not found or not linked"
fi

if [ -L "$HOME/Development/tools/pulsar" ] && [ -d "$HOME/Development/tools/pulsar" ]; then
    log "✓ Pulsar is installed and linked"
    success_count=$((success_count + 1))
else
    warn "Pulsar not found or not linked"
fi
total_checks=$((total_checks + 2))

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
info "2. Install VS Code extensions: ~/Development/tools/install-vscode-extensions.sh"
info "3. Configure AWS credentials: aws configure"
info "4. Generate SSH keys if needed: ~/.ssh/generate_ssh_key.sh"
info "5. Check development status: ~/Development/scripts/dev-status.sh"

log "Validation completed!"
