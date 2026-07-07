#!/bin/bash

# SSH Configuration Script
# Sets up SSH with proper permissions and configuration

# set -e is wanted here: SSH setup writes files and adjusts permissions, and a
# failure should stop rather than continue with a half-configured ~/.ssh.
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

log "Configuring SSH..."

# Create SSH directory if it doesn't exist
if [ ! -d ~/.ssh ]; then
    log "Creating ~/.ssh directory..."
    mkdir -p ~/.ssh
fi

# Set proper permissions for SSH directory
log "Setting proper permissions for SSH directory..."
chmod 700 ~/.ssh

# SSH_CONFIG_MODE controls behavior when ~/.ssh/config already exists:
#   replace        (default) - back up the existing file, then overwrite it
#   skip_if_exists - leave the existing file untouched
SSH_CONFIG_MODE="${SSH_CONFIG_MODE:-replace}"

if [ "$SSH_CONFIG_MODE" = "skip_if_exists" ] && [ -f ~/.ssh/config ]; then
    log "~/.ssh/config already exists; skipping (SSH_CONFIG_MODE=skip_if_exists)"
else

# Backup existing SSH config if it exists
if [ -f ~/.ssh/config ]; then
    log "Backing up existing SSH config to ~/.ssh/config.backup"
    cp ~/.ssh/config ~/.ssh/config.backup
fi

# Create SSH config file
log "Creating SSH configuration..."
cat > ~/.ssh/config << 'EOF'
# Global SSH Configuration

# Use keychain for all hosts
Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 30
    TCPKeepAlive yes
    
# Bitbucket configuration
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey

# GitHub configuration (if needed)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey

# GitLab configuration (if needed)
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey

# Example production server configuration
# Uncomment and modify as needed
# Host prod-server
#     HostName your-production-server.com
#     User your-username
#     IdentityFile ~/.ssh/prod-vpc.pem
#     Port 22

# Example development server configuration
# Host dev-server
#     HostName your-dev-server.com
#     User your-username
#     IdentityFile ~/.ssh/id_rsa
#     Port 22

EOF

fi

# Set proper permissions for SSH config
chmod 600 ~/.ssh/config

# Check if SSH keys exist; auto-generate an RSA key pair if neither the
# private nor public key is present (this step only runs when the user has
# not chosen to skip SSH configuration).
log "Checking SSH keys..."
if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_rsa.pub ]; then
    if [ -f ~/.ssh/id_rsa ]; then
        log "SSH private key found: ~/.ssh/id_rsa"
        chmod 600 ~/.ssh/id_rsa
    else
        warn "SSH private key not found at ~/.ssh/id_rsa (but a .pub file exists)"
        info "Not auto-generating, since that would risk orphaning the existing public key."
        info "Generate manually with: ssh-keygen -t rsa -b 4096 -C 'your-email@example.com' -f ~/.ssh/id_rsa"
    fi

    if [ -f ~/.ssh/id_rsa.pub ]; then
        log "SSH public key found: ~/.ssh/id_rsa.pub"
        chmod 644 ~/.ssh/id_rsa.pub
        info "Your public key:"
        cat ~/.ssh/id_rsa.pub
    else
        warn "SSH public key not found at ~/.ssh/id_rsa.pub"
    fi
else
    # SSH_KEY_MODE (set by the 3rd pre-flight prompt in mac_setup.sh) is either:
    #   generate (default) - create a brand new RSA key pair
    #   copy               - copy an existing key pair from SSH_KEY_SOURCE_PATH
    SSH_KEY_MODE="${SSH_KEY_MODE:-generate}"
    SSH_KEY_SOURCE_PATH="${SSH_KEY_SOURCE_PATH:-}"

    if [ "$SSH_KEY_MODE" = "copy" ] && [ -n "$SSH_KEY_SOURCE_PATH" ] && [ -f "$SSH_KEY_SOURCE_PATH" ]; then
        log "No SSH key pair found; copying RSA key from $SSH_KEY_SOURCE_PATH..."

        cp "$SSH_KEY_SOURCE_PATH" ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa

        if [ -f "${SSH_KEY_SOURCE_PATH}.pub" ]; then
            cp "${SSH_KEY_SOURCE_PATH}.pub" ~/.ssh/id_rsa.pub
            chmod 644 ~/.ssh/id_rsa.pub
        else
            info "No matching .pub file found next to source key; deriving the public key from the private key..."
            if ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub 2>/dev/null; then
                chmod 644 ~/.ssh/id_rsa.pub
            else
                warn "Could not derive a public key from $SSH_KEY_SOURCE_PATH"
            fi
        fi

        log "Copied SSH key pair to ~/.ssh/id_rsa$( [ -f ~/.ssh/id_rsa.pub ] && echo " / ~/.ssh/id_rsa.pub")"
        if [ -f ~/.ssh/id_rsa.pub ]; then
            info "Your public key:"
            cat ~/.ssh/id_rsa.pub
        fi
    else
        if [ "$SSH_KEY_MODE" = "copy" ]; then
            warn "SSH_KEY_MODE was 'copy' but no valid source key was provided; generating a new RSA key instead."
        fi

        log "No SSH key pair found; generating a new RSA key..."

        # Prefer the email already configured for Git (set up in configure_git.sh),
        # falling back to a generated placeholder if none is available.
        key_email="$(git config --global user.email 2>/dev/null || true)"
        if [ -z "$key_email" ]; then
            key_email="$(whoami)@$(hostname -s 2>/dev/null || hostname)"
        fi

        if ssh-keygen -t rsa -b 4096 -C "$key_email" -f ~/.ssh/id_rsa -N "" < /dev/null; then
            chmod 600 ~/.ssh/id_rsa
            chmod 644 ~/.ssh/id_rsa.pub
            log "Generated new SSH key pair: ~/.ssh/id_rsa / ~/.ssh/id_rsa.pub (comment: $key_email)"
            info "Your public key:"
            cat ~/.ssh/id_rsa.pub
            info "Add this public key to your Git hosting service(s):"
            info "  GitHub: https://github.com/settings/keys"
            info "  Bitbucket: https://bitbucket.org/account/settings/ssh-keys/"
            info "  GitLab: https://gitlab.com/-/profile/keys"
        else
            error "Failed to generate SSH key pair"
        fi
    fi
fi

# Check for other key files and set permissions
log "Setting permissions for other SSH files..."
for file in ~/.ssh/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        case "$filename" in
            *.pem)
                chmod 600 "$file"
                log "Set permissions for $filename (600)"
                ;;
            *.pub|*.pub.pem)
                chmod 644 "$file"
                log "Set permissions for $filename (644)"
                ;;
            known_hosts|known_hosts.old)
                chmod 644 "$file"
                log "Set permissions for $filename (644)"
                ;;
            config)
                chmod 600 "$file"
                log "Set permissions for $filename (600)"
                ;;
            *)
                if [[ "$filename" != *"."* ]]; then
                    # Likely a private key without extension
                    chmod 600 "$file"
                    log "Set permissions for $filename (600)"
                fi
                ;;
        esac
    fi
done

# Add SSH keys to ssh-agent if they exist
log "Adding SSH keys to ssh-agent..."
if command -v ssh-add &> /dev/null; then
    # Start ssh-agent if not running
    if ! pgrep -x "ssh-agent" > /dev/null; then
        eval "$(ssh-agent -s)"
    fi
    
    # Add keys to agent. On macOS 12+ the keychain flag is --apple-use-keychain;
    # -K is deprecated/removed, so try the modern flag first and fall back for
    # very old machines.
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add --apple-use-keychain ~/.ssh/id_rsa 2>/dev/null \
            || ssh-add -K ~/.ssh/id_rsa 2>/dev/null \
            || warn "Could not add id_rsa to ssh-agent"
    fi

    # Add other private keys (*.pem files)
    for keyfile in ~/.ssh/*.pem; do
        if [ -f "$keyfile" ] && [[ "$keyfile" != *".pub.pem" ]]; then
            ssh-add --apple-use-keychain "$keyfile" 2>/dev/null \
                || ssh-add -K "$keyfile" 2>/dev/null \
                || warn "Could not add $(basename "$keyfile") to ssh-agent"
        fi
    done
else
    warn "ssh-add command not found"
fi

# Create SSH key generation script
log "Creating SSH key generation helper script..."
cat > ~/.ssh/generate_ssh_key.sh << 'EOF'
#!/bin/bash

# SSH Key Generation Helper Script

echo "SSH Key Generation Helper"
echo "========================"

# Get email for key generation
read -p "Enter your email address: " email

if [ -z "$email" ]; then
    echo "Email is required for SSH key generation"
    exit 1
fi

# Check if key already exists
if [ -f ~/.ssh/id_rsa ]; then
    echo "SSH key already exists at ~/.ssh/id_rsa"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate SSH key
echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa

# Set proper permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Add to ssh-agent (modern keychain flag with fallback for old macOS)
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_rsa 2>/dev/null || ssh-add -K ~/.ssh/id_rsa

echo ""
echo "SSH key generated successfully!"
echo "Your public key:"
echo "=================="
cat ~/.ssh/id_rsa.pub
echo "=================="
echo ""
echo "Copy the above public key and add it to your Git hosting service:"
echo "- GitHub: https://github.com/settings/keys"
echo "- Bitbucket: https://bitbucket.org/account/settings/ssh-keys/"
echo "- GitLab: https://gitlab.com/-/profile/keys"

EOF

chmod +x ~/.ssh/generate_ssh_key.sh

log "SSH configuration completed!"
info "SSH config file created at ~/.ssh/config"
info "SSH key generation helper created at ~/.ssh/generate_ssh_key.sh"

# Display current SSH key status
log "Current SSH key status:"
if [ -f ~/.ssh/id_rsa ]; then
    info "✓ Private key exists: ~/.ssh/id_rsa"
else
    warn "✗ Private key missing: ~/.ssh/id_rsa"
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
    info "✓ Public key exists: ~/.ssh/id_rsa.pub"
else
    warn "✗ Public key missing: ~/.ssh/id_rsa.pub"
fi

# List all SSH files
log "SSH directory contents:"
ls -la ~/.ssh/

log "SSH setup completed successfully!"
info "To generate a new SSH key, run: ~/.ssh/generate_ssh_key.sh"
info "To test SSH connection to Bitbucket: ssh -T git@bitbucket.org"
info "To test SSH connection to GitHub: ssh -T git@github.com"
