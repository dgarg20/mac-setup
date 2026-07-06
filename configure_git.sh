#!/bin/bash

# Git Configuration Script
# Sets up Git with user credentials and useful configurations

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log "Configuring Git..."

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git first."
    exit 1
fi

# GIT_CONFIG_MODE controls behavior when ~/.gitconfig or ~/.gitignore_global
# already exist:
#   replace        (default) - back up the existing file, then overwrite it
#   skip_if_exists - leave the existing file untouched
GIT_CONFIG_MODE="${GIT_CONFIG_MODE:-replace}"

# GitHub/Git identity used for [user] name/email. Overridden by the pre-flight
# prompt in mac_setup.sh; falls back to these defaults when run standalone.
GIT_USER_NAME="${GIT_USER_NAME:-Deepanshu Garg}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-deepanshu.garg@<...>.com}"

if [ "$GIT_CONFIG_MODE" = "skip_if_exists" ] && [ -f ~/.gitconfig ]; then
    log "~/.gitconfig already exists; skipping (GIT_CONFIG_MODE=skip_if_exists)"
else

# Backup existing .gitconfig if it exists
if [ -f ~/.gitconfig ]; then
    log "Backing up existing .gitconfig to .gitconfig.backup"
    cp ~/.gitconfig ~/.gitconfig.backup
fi

# Create .gitconfig
log "Creating Git configuration..."
cat > ~/.gitconfig << 'EOF'
# This is Git's per-user configuration file.
[user]
	name = Deepanshu Garg
	email = deepanshu.garg@<...>.com

[core]
	editor = code --wait
	autocrlf = input
	safecrlf = true
	excludesfile = ~/.gitignore_global

[init]
	defaultBranch = main

[pull]
	rebase = false

[push]
	default = simple
	autoSetupRemote = true

[merge]
	tool = vscode

[mergetool "vscode"]
	cmd = code --wait $MERGED

[diff]
	tool = vscode

[difftool "vscode"]
	cmd = code --wait --diff $LOCAL $REMOTE

[url "ssh://git@bitbucket.org/"]
	insteadOf = https://bitbucket.org/

[url "git@bitbucket.org:"]
	insteadOf = https://bitbucket.org/

[credential]
	helper = store

[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true

[alias]
	# Basic shortcuts
	st = status
	co = checkout
	br = branch
	ci = commit
	ca = commit -a
	cm = commit -m
	cam = commit -am
	
	# Logging
	lg = log --oneline --graph --decorate
	lga = log --oneline --graph --decorate --all
	ll = log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --numstat
	
	# Diff shortcuts
	d = diff
	dc = diff --cached
	
	# Reset shortcuts
	unstage = reset HEAD --
	last = log -1 HEAD
	
	# Stash shortcuts
	sl = stash list
	sa = stash apply
	ss = stash save
	
	# Remote shortcuts
	pu = push
	pl = pull
	
	# Branch management
	bra = branch -ra
	bd = branch -d
	bdd = branch -D
	
	# Clean up
	cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"

[color]
	ui = auto
	branch = auto
	diff = auto
	status = auto

[color "branch"]
	current = yellow reverse
	local = yellow
	remote = green

[color "diff"]
	meta = yellow bold
	frag = magenta bold
	old = red bold
	new = green bold

[color "status"]
	added = yellow
	changed = green
	untracked = cyan

[help]
	autocorrect = 1

[rerere]
	enabled = true

[branch]
	autosetupmerge = always
	autosetuprebase = always

EOF

# Apply the actual Git identity (heredoc above ships with placeholder values
# since its delimiter is quoted to keep git's own $MERGED/$LOCAL/$REMOTE
# variables from being expanded by the shell).
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

fi

if [ "$GIT_CONFIG_MODE" = "skip_if_exists" ] && [ -f ~/.gitignore_global ]; then
    log "~/.gitignore_global already exists; skipping (GIT_CONFIG_MODE=skip_if_exists)"
else

# Create global gitignore file
log "Creating global gitignore file..."
cat > ~/.gitignore_global << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
Icon

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Windows
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
ehthumbs_vista.db
*.tmp
*.temp
Desktop.ini
$RECYCLE.BIN/
*.cab
*.msi
*.msix
*.msm
*.msp
*.lnk

# Linux
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test
.env.local
.env.production

# Compiled Java class files
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs
hs_err_pid*

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# Gradle
.gradle
build/
!gradle/wrapper/gradle-wrapper.jar
!**/src/main/**/build/
!**/src/test/**/build/

# IntelliJ IDEA
.idea
*.iws
*.iml
*.ipr
out/
!**/src/main/**/out/
!**/src/test/**/out/

# Eclipse
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache
bin/
!**/src/main/**/bin/
!**/src/test/**/bin/

# NetBeans
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/

# VS Code
.vscode/

# Vim
*.swp
*.swo

# Emacs
*~
\#*\#
/.emacs.desktop
/.emacs.desktop.lock
*.elc
auto-save-list
tramp
.\#*

EOF

fi

log "Git configuration completed!"
info "Git user: $(git config --global user.name 2>/dev/null || echo "$GIT_USER_NAME") <$(git config --global user.email 2>/dev/null || echo "$GIT_USER_EMAIL")>"
info "Default editor: VS Code"
info "Global gitignore created at ~/.gitignore_global"
info "Useful aliases configured (st, co, br, lg, etc.)"

# Verify configuration
log "Verifying Git configuration..."
git config --global --list | grep -E "(user\.|core\.editor|init\.defaultBranch)"

log "Git setup completed successfully!"
