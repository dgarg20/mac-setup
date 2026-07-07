# Mac Setup Scripts

Bash scripts that automate setting up a new Mac for development — installing tools and apps via Homebrew, configuring the shell, Git, and SSH, pulling common Docker images, and creating a standard folder layout.

## What it does

Running `mac_setup.sh` will:

0. Install the Xcode Command Line Tools if they're missing (prerequisite for everything below).
1. Install Homebrew and a set of CLI tools, browsers, editors, IDEs, and database GUIs.
2. Install SDKMAN with Java 21 & 25, plus Maven, Gradle, Go, Scala, protoc, and buf.
3. Install the AWS CLI and Apache Kafka.
4. Configure Zsh (Oh My Zsh, aliases), Git, and SSH (including RSA key setup).
5. Configure VS Code, Maven, and Gradle.
6. Create a `~/Documents` folder structure with matching shell aliases.
7. Install Rancher Desktop and pull a set of common Docker images.

The run is interactive at the start (four prompts), then hands-off. It is safe to re-run: each step checks whether the item is already present, and a package that fails to install is reported at the end rather than stopping the whole run.

## Requirements

- **macOS** (Apple Silicon or Intel)
- **Internet connection**
- **Run as your normal user, not `sudo`** — everything installs through Homebrew (which refuses to run as root). The script exits immediately if started with `sudo`, since that would write your dotfiles into root's home. The one privileged step (the Xcode Command Line Tools installer) prompts for admin rights on its own.
- **Xcode Command Line Tools** — required by Homebrew, git, and compilers. On a brand-new Mac these aren't present; the script installs them automatically as step 0 (a macOS dialog appears — click **Install** and accept the license), then waits for them to finish before continuing.

## Quick Start

```bash
# 1. Get this repository onto the Mac.
#    On a brand-new Mac without git yet, either:
#      a) run `git clone ...` — macOS will pop a dialog to install the
#         Command Line Tools (which include git); accept it, then clone; or
#      b) download the repo as a ZIP from GitHub and unzip it.
git clone git@github.com:dgarg20/mac-setup.git
cd mac-setup

# 2. Run the main script (can also be run by absolute path from anywhere)
./mac_setup.sh
```

> On a fresh Mac the script's first step installs the Xcode Command Line Tools and waits for them to finish before doing anything else.

The script prints a numbered list of everything it will do, then asks **four prompts** before making any changes:

1. **Items to skip** — comma-separated item numbers. Supports:
   - Specific items: `4.2,7.3,9`
   - Ranges of top-level items: `1-5` (skips items 1–5 and all their sub-items)
   - A mix: `1-5,9,12.2`

   Skipping a top-level number (e.g. `6`) skips all its sub-items (`6.1`, `6.2`, …). Press Enter to skip nothing.
2. **Config overwrite behavior** (items 15–18) — for each config-writing step, replace an existing config file (default; a `.backup` is made first) or keep it as-is.
3. **RSA SSH key setup** (item 17, only if no key exists at `~/.ssh/id_rsa`) — generate a new key pair, or copy one from another path.
4. **Git identity** (item 16) — the username and email for `git config user.name` / `user.email`.

All prompts have sensible defaults and are auto-answered in non-interactive shells.

## What Gets Installed

### CLI tools (Homebrew formulae)
| Tool | Purpose |
|---|---|
| Git | Version control |
| Zsh | Shell |
| Bash | Modern Bash (macOS ships 3.2) |
| htop | Process/resource monitor |
| Maven, Gradle | Java build tools |
| Go | Latest Go |
| Scala | JVM language |
| protoc | Protocol Buffers compiler |
| buf | Protobuf lint / breaking-change / codegen |
| AWS CLI | Amazon Web Services CLI |

### Applications (Homebrew casks)
| Category | Apps |
|---|---|
| Browsers & communication | Brave Browser, Firefox, Notion, iTerm2, Slack |
| Code editors | Sublime Text, Visual Studio Code |
| IDEs & AI tools | IntelliJ IDEA, Claude, Google Antigravity |
| Database GUI tools | Sequel Ace, pgAdmin, DBeaver |
| Container runtime | Rancher Desktop |

### Java (via SDKMAN)
- Java 21 (Amazon Corretto) — set as default
- Java 25 (Amazon Corretto)

### Other
- **Oh My Zsh** — Zsh framework
- **Apache Kafka** — downloaded and extracted to `~/Downloads`

## Docker Images Pulled

After Rancher Desktop is installed (item 21), the script pulls:

| Image | Use |
|---|---|
| `apache/kafka` | Kafka broker |
| `mysql` | MySQL database |
| `postgres` | PostgreSQL database |
| `amazon/dynamodb-local` | Local DynamoDB |
| `localstack/localstack` | Local AWS services (e.g. SQS) |
| `redis` | Redis cache |

> Rancher Desktop must be launched once (from Applications) to start its Docker engine before images can be pulled. The script waits up to 60 seconds for the engine; if it isn't ready, it prints the `docker pull` commands to run later.

## Documents Folder Structure

`mac_setup.sh` creates this layout under `~/Documents`:

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

Matching `cd` aliases are added to `~/.zshrc` (personal-side aliases are prefixed with `p`):

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

## Configuration Applied

### Shell (`~/.zshrc`)
- Oh My Zsh, theme `robbyrussell`
- Plugins: `git`, `brew`, `macos`, `docker`, `aws`, `gradle`
- Aliases for common commands, Git, Docker, and the Documents folders
- History and case-insensitive completion settings

### Git (`~/.gitconfig`, `~/.gitignore_global`)
- User name/email (from the identity prompt; defaults to Deepanshu Garg &lt;deepanshu.garg@&lt;...&gt;.com&gt;)
- VS Code as editor / mergetool / difftool
- ~30 aliases (`st`, `co`, `br`, `lg`, `cleanup`, …)
- Global gitignore

### SSH (`~/.ssh/config`)
- Keychain integration
- Key permissions (600 private, 644 public)
- Host entries for GitHub, Bitbucket, GitLab
- RSA key auto-generated (or copied from a path you provide) if none exists
- `~/.ssh/generate_ssh_key.sh` helper for regenerating keys later

### Development environment
- VS Code settings tuned for Java (Java 21/25 runtimes, Maven/Gradle paths)
- VS Code extensions installed directly via `code --install-extension`
- Maven settings (`~/.m2/settings.xml`) and Gradle properties (`~/.gradle/gradle.properties`)

## Scripts in This Repo

| Script | What it does |
|---|---|
| `mac_setup.sh` | Main orchestrator — runs all steps in order |
| `configure_shell.sh` | Zsh + Oh My Zsh, aliases |
| `configure_git.sh` | Git config, aliases, global gitignore |
| `configure_ssh.sh` | SSH config, key management, RSA key generation/copy |
| `setup_dev_environment.sh` | VS Code settings/extensions, Maven, Gradle |
| `switch-java.sh` | Lists installed Java versions and how to switch |
| `clean-dev.sh` | Cleans Maven/Gradle caches, prunes Docker, clears npm cache |
| `validate_setup.sh` | Read-only check of installed tools, config files, and directories with a pass/fail summary |

### Running scripts individually

```bash
./configure_shell.sh          # shell only
./configure_git.sh            # Git only
./configure_ssh.sh            # SSH only
./setup_dev_environment.sh    # VS Code / Maven / Gradle only

./switch-java.sh              # show Java versions
./clean-dev.sh                # clean caches
./validate_setup.sh           # verify the setup
~/.ssh/generate_ssh_key.sh    # generate an SSH key
```

## Aliases Reference

### Git
```bash
git st          # status
git co          # checkout
git br          # branch
git lg          # log --oneline --graph --decorate
git unstage     # reset HEAD --
git cleanup     # remove merged branches
```

### Shell
```bash
ll              # ls -alF
gs              # git status
dps             # docker ps
dcup            # docker-compose up
code.           # code . (open current dir in VS Code)
scripts         # cd ~/Documents/official/scripts
pscripts        # cd ~/Documents/personal/scripts
dockervolumes   # cd ~/Documents/docker-volumes
```

## Customization

### Git identity
Answer the identity prompt when running `mac_setup.sh`. To change the non-interactive defaults, edit `GIT_USER_NAME` / `GIT_USER_EMAIL` near the top of `configure_git.sh`.

### Adding apps
GUI apps are grouped by category in `mac_setup.sh`. Add your cask to the relevant array and add a matching menu line with the next item number:

```bash
declare -A BROWSER_APPS=( ["4.1"]="brave-browser" ["4.2"]="firefox" ["4.3"]="notion" ["4.4"]="iterm2" ["4.5"]="slack" )
declare -A EDITOR_APPS=(  ["5.1"]="sublime-text" ["5.2"]="visual-studio-code" )
declare -A IDE_APPS=(     ["6.1"]="intellij-idea" ["6.2"]="claude" ["6.3"]="antigravity" )
declare -A DB_APPS=(      ["19.1"]="sequel-ace" ["19.2"]="pgadmin4" ["19.3"]="dbeaver-community" )
```

### Adding Java versions
Edit the `JAVA_VERSIONS` array in `mac_setup.sh` (run `sdk list java` for identifiers):

```bash
declare -A JAVA_VERSIONS=( ["9.1"]="21.0.11-amzn" ["9.2"]="25.0.3-amzn" )
```

### VS Code extensions
Edit the `VSCODE_EXTENSIONS` array in `setup_dev_environment.sh`.

### Docker images
Edit the `DOCKER_IMAGES` array in `mac_setup.sh`.

## Post-Installation

1. Restart your terminal, or run `source ~/.zshrc`
2. Configure AWS credentials: `aws configure`
3. Add your SSH public key to GitHub/Bitbucket/GitLab (`cat ~/.ssh/id_rsa.pub`)
4. Launch Rancher Desktop so the Docker image pulls can complete (re-run item 21 if they were skipped)
5. Verify: `./validate_setup.sh`
6. Install any manual software (below)

## Manual Software

Not handled by Homebrew in this script:

- **[Arc Browser](https://arc.net/)**
- **Google Chrome** (install manually if you want it alongside Brave/Firefox)
- **Numbers** and other Mac App Store apps

## Troubleshooting

| Problem | What to do |
|---|---|
| "Do not run this script as root / with sudo" | Run it as your normal user: `./mac_setup.sh` (no `sudo`). Homebrew won't run as root, and sudo would put your dotfiles in root's home |
| `xcode-select: no developer tools` / Xcode not found | The script installs the Command Line Tools automatically (step 0). If the dialog was dismissed, run `xcode-select --install`, complete it, then re-run the script |
| Homebrew install fails | Ensure the Command Line Tools are installed (`xcode-select -p`), check your connection |
| `command not found` (brew, sdk, mvn, code…) mid-run | Run `source ~/.zshrc` and re-run the script |
| SDKMAN install fails | Restart terminal, then `source ~/.zshrc` |
| Java version won't switch | `source ~/.zshrc`; check `sdk version` |
| SSH keys not working | Check `ls -la ~/.ssh/`; regenerate with `~/.ssh/generate_ssh_key.sh` |
| VS Code extensions didn't install | Ensure the `code` CLI is on PATH (installed with the VS Code cask), then re-run `./setup_dev_environment.sh` |
| Docker image pulls skipped / engine not ready | Launch Rancher Desktop, wait for it to start, then re-run item 21 |

Scripts print colored, timestamped output. A summary of any failed installs is shown at the end of the run. Run `./validate_setup.sh` any time to check the current state.

## Security Notes

- **SSH keys**: correct permissions are set (600 private, 644 public); a new key is only generated when neither `~/.ssh/id_rsa` nor `~/.ssh/id_rsa.pub` exists.
- **No stored credentials** in any script.
- **Backups**: existing config files are backed up (`.backup`) before being replaced, unless you chose to keep them.
- **Shell history** files (`bash_history.txt`, `zsh_history.txt`) are gitignored, as they can contain sensitive data.

## License

Provided as-is for personal use. Modify and distribute as needed.
