#!/bin/bash

# Development Environment Setup Script
# Sets up development tools and configurations

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

# Source SDKMAN if available
if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Create development directories
log "Creating development directories..."
mkdir -p ~/Development
mkdir -p ~/Development/projects
mkdir -p ~/Development/tools
mkdir -p ~/Development/scripts
mkdir -p ~/Development/workspace

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
            "name": "JavaSE-1.8",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/8.0.462-amzn"
        },
        {
            "name": "JavaSE-11",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/11.0.28-amzn"
        },
        {
            "name": "JavaSE-17",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/17.0.16-amzn"
        },
        {
            "name": "JavaSE-21",
            "path": "/Users/deepanshugarg/.sdkman/candidates/java/21.0.8-amzn"
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

# Create VS Code extensions list
log "Creating VS Code extensions list..."
cat > ~/Development/tools/vscode-extensions.txt << 'EOF'
# Essential Extensions for Development

# Language Support
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

# Git and Version Control
eamodio.gitlens
mhutchie.git-graph
donjayamanne.githistory

# Docker and Containers
ms-azuretools.vscode-docker
ms-vscode-remote.remote-containers

# AWS and Cloud
amazonwebservices.aws-toolkit-vscode

# Productivity
ms-vscode.vscode-todo-highlight
streetsidesoftware.code-spell-checker
ms-vsliveshare.vsliveshare
ms-vscode.remote-ssh

# Formatting and Linting
esbenp.prettier-vscode
ms-vscode.vscode-eslint
redhat.vscode-yaml
ms-vscode.vscode-json

# Themes and Icons
pkief.material-icon-theme
zhuangtongfa.material-theme

# Database
ms-mssql.mssql
cweijan.vscode-mysql-client2

# Markdown
yzhang.markdown-all-in-one
shd101wyy.markdown-preview-enhanced
EOF

# Create installation script for VS Code extensions
cat > ~/Development/tools/install-vscode-extensions.sh << 'EOF'
#!/bin/bash

# Install VS Code Extensions Script

echo "Installing VS Code extensions..."

# Read extensions from file and install
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
        continue
    fi
    
    echo "Installing: $line"
    code --install-extension "$line"
done < "$(dirname "$0")/vscode-extensions.txt"

echo "VS Code extensions installation completed!"
EOF

chmod +x ~/Development/tools/install-vscode-extensions.sh

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

# Create useful development scripts
log "Creating development utility scripts..."

# Script to switch Java versions
cat > ~/Development/scripts/switch-java.sh << 'EOF'
#!/bin/bash

# Java Version Switcher Script

echo "Available Java versions:"
echo "========================"

if command -v sdk &> /dev/null; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk list java | grep installed
    
    echo ""
    echo "Current Java version:"
    java -version
    
    echo ""
    echo "To switch Java version, use:"
    echo "sdk use java <version>"
    echo "sdk default java <version>"
else
    echo "SDKMAN not found. Please install SDKMAN first."
fi
EOF

chmod +x ~/Development/scripts/switch-java.sh

# Script to clean development environment
cat > ~/Development/scripts/clean-dev.sh << 'EOF'
#!/bin/bash

# Development Environment Cleanup Script

echo "Cleaning development environment..."

# Clean Maven
if [ -d ~/.m2/repository ]; then
    echo "Cleaning Maven repository..."
    find ~/.m2/repository -name "*.lastUpdated" -delete
    find ~/.m2/repository -name "_remote.repositories" -delete
fi

# Clean Gradle
if [ -d ~/.gradle ]; then
    echo "Cleaning Gradle cache..."
    rm -rf ~/.gradle/caches/
    rm -rf ~/.gradle/daemon/
fi

# Clean Docker
if command -v docker &> /dev/null; then
    echo "Cleaning Docker..."
    docker system prune -f
    docker volume prune -f
fi

# Clean npm cache (if Node.js is installed)
if command -v npm &> /dev/null; then
    echo "Cleaning npm cache..."
    npm cache clean --force
fi

echo "Development environment cleanup completed!"
EOF

chmod +x ~/Development/scripts/clean-dev.sh

# Script to show development environment status
cat > ~/Development/scripts/dev-status.sh << 'EOF'
#!/bin/bash

# Development Environment Status Script

echo "Development Environment Status"
echo "=============================="

# Java
echo ""
echo "Java:"
if command -v java &> /dev/null; then
    java -version 2>&1 | head -1
    echo "JAVA_HOME: $JAVA_HOME"
else
    echo "Java not found"
fi

# Maven
echo ""
echo "Maven:"
if command -v mvn &> /dev/null; then
    mvn -version | head -1
else
    echo "Maven not found"
fi

# Gradle
echo ""
echo "Gradle:"
if command -v gradle &> /dev/null; then
    gradle -version | grep "Gradle"
else
    echo "Gradle not found"
fi

# Go
echo ""
echo "Go:"
if command -v go &> /dev/null; then
    go version
else
    echo "Go not found"
fi

# Scala
echo ""
echo "Scala:"
if command -v scala &> /dev/null; then
    scala -version 2>&1 | head -1
else
    echo "Scala not found"
fi

# Git
echo ""
echo "Git:"
if command -v git &> /dev/null; then
    git --version
    echo "User: $(git config user.name) <$(git config user.email)>"
else
    echo "Git not found"
fi

# Docker
echo ""
echo "Docker:"
if command -v docker &> /dev/null; then
    docker --version
    echo "Container runtime: $(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo 'Not running')"
else
    echo "Docker not found"
fi

# Rancher Desktop
echo ""
echo "Rancher Desktop:"
if [ -d "/Applications/Rancher Desktop.app" ]; then
    echo "Rancher Desktop installed"
else
    echo "Rancher Desktop not found"
fi

# AWS CLI
echo ""
echo "AWS CLI:"
if command -v aws &> /dev/null; then
    aws --version
else
    echo "AWS CLI not found"
fi

# VS Code
echo ""
echo "VS Code:"
if command -v code &> /dev/null; then
    code --version | head -1
else
    echo "VS Code not found"
fi

# SDKMAN
echo ""
echo "SDKMAN:"
if [ -d "$HOME/.sdkman" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk version
else
    echo "SDKMAN not found"
fi

# Kafka
echo ""
echo "Kafka:"
if [ -L "$HOME/Development/tools/kafka" ] && [ -d "$HOME/Development/tools/kafka" ]; then
    echo "Kafka installed and linked to ~/Development/tools/kafka"
    if [ -f "$HOME/Development/tools/kafka/bin/kafka-server-start.sh" ]; then
        echo "Kafka scripts available"
    fi
else
    echo "Kafka not found or not linked"
fi

# Pulsar
echo ""
echo "Pulsar:"
if [ -L "$HOME/Development/tools/pulsar" ] && [ -d "$HOME/Development/tools/pulsar" ]; then
    echo "Pulsar installed and linked to ~/Development/tools/pulsar"
    if [ -f "$HOME/Development/tools/pulsar/bin/pulsar" ]; then
        echo "Pulsar scripts available"
    fi
else
    echo "Pulsar not found or not linked"
fi

echo ""
echo "=============================="
EOF

chmod +x ~/Development/scripts/dev-status.sh

# Create project template script
cat > ~/Development/scripts/create-project.sh << 'EOF'
#!/bin/bash

# Project Creation Script

echo "Project Creation Helper"
echo "======================"

read -p "Enter project name: " project_name
read -p "Enter project type (java/spring/node/python): " project_type

if [ -z "$project_name" ]; then
    echo "Project name is required"
    exit 1
fi

project_dir="$HOME/Development/projects/$project_name"

if [ -d "$project_dir" ]; then
    echo "Project directory already exists: $project_dir"
    exit 1
fi

mkdir -p "$project_dir"
cd "$project_dir"

case "$project_type" in
    "java")
        echo "Creating Java project..."
        mkdir -p src/main/java src/main/resources src/test/java
        echo "# $project_name" > README.md
        echo "Java project created at: $project_dir"
        ;;
    "spring")
        echo "Creating Spring Boot project..."
        echo "Visit https://start.spring.io/ to generate a Spring Boot project"
        echo "Then extract it to: $project_dir"
        ;;
    "node")
        echo "Creating Node.js project..."
        npm init -y
        mkdir -p src test
        echo "Node.js project created at: $project_dir"
        ;;
    "python")
        echo "Creating Python project..."
        mkdir -p src tests
        echo "# $project_name" > README.md
        echo "Python project created at: $project_dir"
        ;;
    *)
        echo "Creating generic project..."
        echo "# $project_name" > README.md
        echo "Generic project created at: $project_dir"
        ;;
esac

echo "Opening project in VS Code..."
code "$project_dir"
EOF

chmod +x ~/Development/scripts/create-project.sh

log "Development environment setup completed!"

info "Created directories:"
info "  ~/Development/projects - For your projects"
info "  ~/Development/tools - For development tools"
info "  ~/Development/scripts - For utility scripts"
info "  ~/Development/workspace - For temporary work"

info "Created scripts:"
info "  ~/Development/scripts/switch-java.sh - Switch Java versions"
info "  ~/Development/scripts/clean-dev.sh - Clean development environment"
info "  ~/Development/scripts/dev-status.sh - Show environment status"
info "  ~/Development/scripts/create-project.sh - Create new projects"
info "  ~/Development/tools/install-vscode-extensions.sh - Install VS Code extensions"

info "Configuration files created:"
info "  ~/.m2/settings.xml - Maven settings"
info "  ~/.gradle/gradle.properties - Gradle properties"
info "  VS Code settings and extensions list"

log "To install VS Code extensions, run:"
log "  ~/Development/tools/install-vscode-extensions.sh"

log "To check your development environment status, run:"
log "  ~/Development/scripts/dev-status.sh"
