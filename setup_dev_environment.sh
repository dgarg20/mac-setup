#!/bin/bash

# Development Environment Setup Script
# Sets up development tools and configurations

# set -e is wanted here: this script writes config files, and a failed write
# should stop rather than continue with a partially-configured environment.
# (Contrast validate_setup.sh, which deliberately omits it to run every check.)
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

log "Setting up development environment..."

# DEVENV_CONFIG_MODE controls behavior when a config file this script manages
# (VS Code settings.json, ~/.m2/settings.xml, ~/.gradle/gradle.properties)
# already exists:
#   replace        (default) - back up the existing file, then overwrite it
#   skip_if_exists - leave the existing file untouched
DEVENV_CONFIG_MODE="${DEVENV_CONFIG_MODE:-replace}"

# Source Homebrew/SDKMAN so `code`, `mvn`, `gradle` etc. are on PATH even if
# this script is invoked directly rather than through mac_setup.sh.
if [ -d /opt/homebrew/bin ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d /usr/local/bin ] && [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Create VS Code settings directory
log "Setting up VS Code configuration..."
mkdir -p ~/Library/Application\ Support/Code/User

# Create VS Code settings.json
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
if [ "$DEVENV_CONFIG_MODE" = "skip_if_exists" ] && [ -f "$VSCODE_SETTINGS" ]; then
    log "VS Code settings.json already exists; skipping (DEVENV_CONFIG_MODE=skip_if_exists)"
else

if [ -f "$VSCODE_SETTINGS" ]; then
    log "Backing up existing VS Code settings.json to settings.json.backup"
    cp "$VSCODE_SETTINGS" "$VSCODE_SETTINGS.backup"
fi

cat > ~/Library/Application\ Support/Code/User/settings.json << 'EOF'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "SF Mono, Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.wordWrap": "on",
    "editor.minimap.enabled": true,
    "editor.rulers": [80, 120],
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
    },
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "workbench.colorTheme": "Default Dark+",
    "workbench.iconTheme": "vs-seti",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.shell.osx": "/bin/zsh",
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "java.home": "/Users/deepanshugarg/.sdkman/candidates/java/current",
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-21",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/21.0.11-amzn"
        },
        {
            "name": "JavaSE-25",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/25.0.3-amzn"
        }
    ],
    "maven.executable.path": "/opt/homebrew/bin/mvn",
    "gradle.nestedProjects": true,
    "docker.showStartPage": false,
    "extensions.autoUpdate": true,
    "telemetry.telemetryLevel": "off"
}
EOF

fi

# Install VS Code extensions directly (rather than just generating a script
# for the user to run manually later).
log "Installing VS Code extensions..."

VSCODE_EXTENSIONS=(
    ms-vscode.vscode-java-pack
    vscjava.vscode-java-debug
    vscjava.vscode-java-test
    vscjava.vscode-maven
    vscjava.vscode-gradle
    redhat.java
    ms-python.python
    ms-python.pylint
    ms-python.flake8
    bradlc.vscode-tailwindcss
    ms-vscode.vscode-typescript-next
    eamodio.gitlens
    mhutchie.git-graph
    donjayamanne.githistory
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-containers
    amazonwebservices.aws-toolkit-vscode
    ms-vscode.vscode-todo-highlight
    streetsidesoftware.code-spell-checker
    ms-vsliveshare.vsliveshare
    ms-vscode.remote-ssh
    esbenp.prettier-vscode
    ms-vscode.vscode-eslint
    redhat.vscode-yaml
    ms-vscode.vscode-json
    pkief.material-icon-theme
    zhuangtongfa.material-theme
    ms-mssql.mssql
    cweijan.vscode-mysql-client2
    yzhang.markdown-all-in-one
    shd101wyy.markdown-preview-enhanced
)

if command -v code &> /dev/null; then
    installed_extensions="$(code --list-extensions 2>/dev/null || true)"
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        if echo "$installed_extensions" | grep -qix "$ext"; then
            log "VS Code extension already installed: $ext"
        else
            log "Installing VS Code extension: $ext"
            code --install-extension "$ext" || warn "Failed to install VS Code extension: $ext"
        fi
    done
else
    warn "'code' command not found; skipping VS Code extension installation."
    info "Install VS Code (item 5.2) first, then re-run this script."
fi

# Create Maven settings directory and file
log "Setting up Maven configuration..."
mkdir -p ~/.m2

if [ "$DEVENV_CONFIG_MODE" = "skip_if_exists" ] && [ -f ~/.m2/settings.xml ]; then
    log "~/.m2/settings.xml already exists; skipping (DEVENV_CONFIG_MODE=skip_if_exists)"
else

if [ -f ~/.m2/settings.xml ]; then
    log "Backing up existing ~/.m2/settings.xml to settings.xml.backup"
    cp ~/.m2/settings.xml ~/.m2/settings.xml.backup
fi

cat > ~/.m2/settings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">

    <localRepository>${user.home}/.m2/repository</localRepository>

    <profiles>
        <profile>
            <id>default</id>
            <properties>
                <maven.compiler.source>21</maven.compiler.source>
                <maven.compiler.target>21</maven.compiler.target>
                <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
                <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
            </properties>
        </profile>
    </profiles>

    <activeProfiles>
        <activeProfile>default</activeProfile>
    </activeProfiles>

</settings>
EOF

fi

# Create Gradle init script
log "Setting up Gradle configuration..."
mkdir -p ~/.gradle

if [ "$DEVENV_CONFIG_MODE" = "skip_if_exists" ] && [ -f ~/.gradle/gradle.properties ]; then
    log "~/.gradle/gradle.properties already exists; skipping (DEVENV_CONFIG_MODE=skip_if_exists)"
else

if [ -f ~/.gradle/gradle.properties ]; then
    log "Backing up existing ~/.gradle/gradle.properties to gradle.properties.backup"
    cp ~/.gradle/gradle.properties ~/.gradle/gradle.properties.backup
fi

cat > ~/.gradle/gradle.properties << 'EOF'
# Gradle Properties

# JVM settings
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8

# Gradle settings
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.daemon=true

# Build settings
org.gradle.console=auto
org.gradle.warning.mode=all
EOF

fi

log "Development environment setup completed!"

info "Configuration files created:"
info "  ~/.m2/settings.xml - Maven settings"
info "  ~/.gradle/gradle.properties - Gradle properties"
info "  VS Code settings.json"

info "Utility scripts (checked into this repo, not generated at runtime):"
info "  ./switch-java.sh - Switch Java versions"
info "  ./clean-dev.sh - Clean development environment caches"
