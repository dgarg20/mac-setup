# Mac Setup — Script Review

**Reviewer:** experienced bash perspective
**Date:** 2026-07-03
**Scope:** `mac_setup.sh` (orchestrator) and the sub-scripts `configure_shell.sh`,
`configure_git.sh`, `configure_ssh.sh`, `setup_dev_environment.sh`, `validate_setup.sh`.
**Environment verified against:** macOS 26.3.1, Homebrew (Apple Silicon).

The script is in good shape overall: idempotent install guards, a clear numbered
menu, skip-list with ranges, graceful non-interactive fallbacks, and the Kafka
download hardening are all solid. The findings below are ordered by severity.
Nothing here is cosmetic-only until the "Low / Nits" section.

---

## Status (2026-07-03): all findings applied ✅

| ID | Finding | Status |
|----|---------|--------|
| C1 | Sub-scripts by relative path under `set -e` | ✅ Fixed — `SCRIPT_DIR` + `run_subscript` (absolute path, existence check, non-fatal) |
| C2 | One failed `brew install` aborts everything | ✅ Fixed — `brew_formula`/`brew_cask` helpers, failures collected in `FAILED_ITEMS` and summarized at the end |
| H1 | `brew update` failure aborts run | ✅ Fixed — `|| warn` |
| H2 | AWS CLI `curl`/`sudo` pkg install | ✅ Fixed — switched to `brew install awscli`; `sudo` fully removed from the script |
| H3 | `ssh-add -K` deprecated | ✅ Fixed — `--apple-use-keychain` with `-K` fallback (all 3 sites incl. the generated helper) |
| M1 | `~/.zprofile` duplicate append | ✅ Fixed — `grep -qF` guard |
| M2 | `curl -s \| bash` for SDKMAN | ✅ Fixed — `curl -fsSL` + `|| warn` guard |
| M3 | Add `set -o pipefail` | ✅ Applied — `set -eo pipefail` (kept install helpers tolerant; `set -u` intentionally deferred) |
| M4 | `echo \| xargs` trimming | ✅ Fixed — pure-bash `trim()` helper |

`set -u` (nounset) remains the one deliberately deferred item (see M3), pending a
dedicated test pass. The original findings are preserved below for reference.

---

## Legend

| Severity | Meaning |
|----------|---------|
| 🔴 Critical | Can abort the whole run or leave the machine half-configured |
| 🟠 High | Likely failure on a real fresh machine, or a correctness bug |
| 🟡 Medium | Fragile / inconsistent; fails in plausible conditions |
| 🟢 Low / Nit | Style, idempotency polish, future-proofing |

---

## 🔴 C1 — Sub-scripts are called by relative path under `set -e`

**Where:** `mac_setup.sh:827,829,841,843,855,857,869,871`

```bash
SHELL_CONFIG_MODE="replace" ./configure_shell.sh
```

**Problem:** The four config steps (15–18) invoke `./configure_*.sh` relative to
the **current working directory**, not the script's own location. If the script
is launched from anywhere other than its own folder — e.g.
`bash ~/Documents/scripts/mac_setup/mac_setup.sh`, or via an absolute path from
`$HOME` — the shell can't find `./configure_shell.sh`, exits 127, and because
`set -e` is active the **entire run aborts** at step 15, after everything up to
step 14 already ran. The machine is left half-configured with no config files.

This is aggravated by the Kafka block (item 12) doing `cd "$HOME/Downloads"` …
`cd -`; the run only survives because CWD happens to be restored, which is
implicit and fragile.

**Fix:** Resolve the script directory once at the top and call sub-scripts by
absolute path:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
...
SHELL_CONFIG_MODE="replace" "$SCRIPT_DIR/configure_shell.sh"
```

Also guard that each sub-script exists/executes before calling, so a missing file
degrades to a warning instead of killing the run:

```bash
run_subscript() {
    local script="$SCRIPT_DIR/$1"; shift
    if [ ! -x "$script" ]; then
        warn "Cannot run $script (missing or not executable); skipping"
        return 0
    fi
    "$@" "$script"
}
```

---

## 🔴 C2 — A single failed `brew install` aborts the whole script

**Where:** `mac_setup.sh` — every `brew install` **except item 6** lacks a
`|| warn` guard: lines `471, 481, 491, 501, 527, 551, 663, 673, 683, 693, 703,
713, 894, 909`.

**Problem:** With `set -e`, if any one package fails — a transient network error,
a cask renamed/removed upstream, a formula needing a license prompt, a checksum
mismatch — the script exits immediately and skips **all remaining steps**. On a
fresh machine installing ~20 casks/formulae, the probability that at least one
hiccups is not small. Item 6 (IDEs) already does this correctly:

```bash
brew install --cask "$app" || warn "Failed to install $app (cask may have been renamed/removed upstream)"
```

**Problem is also one of consistency:** items 4/5/19 are structurally identical
cask loops to item 6, but only item 6 is guarded.

**Fix:** Route every install through one helper and make failures non-fatal
(a setup script should be "best effort, report what failed at the end"):

```bash
FAILED_ITEMS=()

brew_formula() {   # $1 = formula, $2 = human label
    if brew list "$1" &>/dev/null; then log "$2 already installed"; return; fi
    log "Installing $2..."
    brew install "$1" || { warn "Failed to install $2"; FAILED_ITEMS+=("$2"); }
}

brew_cask() {      # $1 = cask, $2 = human label
    if brew list --cask "$1" &>/dev/null; then log "$2 already installed"; return; fi
    log "Installing $2..."
    brew install --cask "$1" || { warn "Failed to install $2"; FAILED_ITEMS+=("$2"); }
}
```

Then print a summary at the end:

```bash
if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
    warn "The following items failed and may need manual install: ${FAILED_ITEMS[*]}"
fi
```

This collapses ~12 near-identical `if ! brew list … else …` blocks into two
helpers and removes the abort-on-first-failure footgun in one move.

---

## 🟠 H1 — `brew update` failure aborts the run

**Where:** `mac_setup.sh:456`

```bash
brew update
```

**Problem:** Under `set -e`, a failed `brew update` (flaky network, git tap
issue — extremely common) kills the entire setup before a single package is
installed. An update failure is not fatal to the actual work.

**Fix:**

```bash
brew update || warn "brew update failed; continuing with possibly-stale formulae"
```

---

## 🟠 H2 — AWS CLI download reuses the exact bug already fixed for Kafka

**Where:** `mac_setup.sh:727–729`

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
sudo installer -pkg "/tmp/AWSCLIV2.pkg" -target /
rm "/tmp/AWSCLIV2.pkg"
```

**Problem:** No `-f` on `curl` — a 4xx/5xx response is saved as the `.pkg` (an
HTML error page), then `sudo installer` fails on it. This is the *same class of
bug* that was fixed for Kafka (where a 404 HTML page was saved as the `.tgz`).
Additionally the mid-script `sudo` triggers an interactive password prompt in the
middle of an otherwise hands-off run, and fails outright in any non-interactive
context.

**Fix (recommended): use the Homebrew formula and drop `sudo` entirely** — it
exists and is the cleaner path on macOS:

```bash
brew_formula awscli "AWS CLI"
```

**Fix (if the pkg approach is kept):** add `-f`, guard, and verify:

```bash
if curl -fL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o /tmp/AWSCLIV2.pkg; then
    sudo installer -pkg /tmp/AWSCLIV2.pkg -target / || warn "AWS CLI install failed"
    rm -f /tmp/AWSCLIV2.pkg
else
    warn "Failed to download AWS CLI installer"
fi
```

---

## 🟠 H3 — `ssh-add -K` is deprecated/removed on modern macOS

**Where:** `configure_ssh.sh:240, 246, 291`

```bash
ssh-add -K ~/.ssh/id_rsa
```

**Problem:** The `-K` flag was deprecated in macOS Monterey (12) and its behavior
moved to `--apple-use-keychain`. On this machine (macOS 26.3) `-K` prints a
deprecation error and, depending on the OpenSSH build, may not add the key to the
keychain at all. The `2>/dev/null || warn` masking hides that it silently did
nothing.

**Fix:**

```bash
ssh-add --apple-use-keychain ~/.ssh/id_rsa 2>/dev/null \
    || ssh-add -K ~/.ssh/id_rsa 2>/dev/null \
    || warn "Could not add id_rsa to ssh-agent"
```

(Try the modern flag first, fall back to `-K` for very old machines.)

---

## 🟡 M1 — `~/.zprofile` gets a duplicate line appended on every run

**Where:** `mac_setup.sh:442`

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
```

**Problem:** This appends unconditionally. The script is explicitly designed to be
re-run, so `~/.zprofile` accumulates a duplicate `brew shellenv` line every time.
Not fatal, but it's an idempotency leak in a script that otherwise prides itself
on idempotency.

**Fix:** Only append if not already present:

```bash
BREW_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
grep -qF "$BREW_LINE" ~/.zprofile 2>/dev/null || echo "$BREW_LINE" >> ~/.zprofile
```

---

## 🟡 M2 — `curl -s | bash` for SDKMAN hides download failures

**Where:** `mac_setup.sh:606`

```bash
curl -s "https://get.sdkman.io" | bash
```

**Problem:** `-s` silences errors and there's no `-f`, so an HTTP error pipes an
empty/error body straight into `bash`. Combined with `set -e`, behavior on a bad
fetch is undefined-ish (bash runs nothing, SDKMAN silently not installed, later
Java steps warn). Use fail-fast flags:

**Fix:**

```bash
curl -fsSL "https://get.sdkman.io" | bash
```

Apply the same `-fsSL` consistency to any other piped installer.

---

## 🟡 M3 — Consider `set -o pipefail` (and evaluate `set -u`)

**Where:** all scripts use bare `set -e`.

**Problem:** Without `pipefail`, a failure on the left side of a pipe
(`curl … | bash`, `docker … | …`) is invisible to `set -e` because only the
exit status of the last command in the pipeline counts. Adding `pipefail` makes
the Kafka/SDKMAN/OhMyZsh pipelines fail loudly instead of silently.

**Fix:**

```bash
set -eo pipefail
```

`set -u` (nounset) is also worth considering but needs a careful pass first: the
associative-array lookups (`${BROWSER_APPS[$id]}`) and optional env vars
(`${SSH_KEY_SOURCE_PATH}`) must all be safe. Recommend `pipefail` now, `-u` as a
follow-up after a dedicated test run. **Note:** if C2's "collect failures and
continue" model is adopted, keep the install helpers tolerant — don't let
`pipefail`/`-e` re-introduce abort-on-first-failure.

---

## 🟡 M4 — Whitespace trimming via `echo | xargs` is fragile

**Where:** `mac_setup.sh:209, 298`

```bash
trimmed=$(echo "$raw" | xargs)
```

**Problem:** Using `xargs` to trim whitespace mangles input containing quotes or
backslashes and spawns a subprocess per token. For menu numbers it works, but
it's a surprising idiom. Pure-bash trim is clearer and safe:

**Fix:**

```bash
trimmed="${raw#"${raw%%[![:space:]]*}"}"   # ltrim
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"  # rtrim
```

(or a small `trim()` helper).

---

## Ordering analysis

The overall order is sound. Dependencies are respected:

- **Homebrew (1) before everything** ✓ — every later `brew` call has it.
- **Git (3.1) before editors/IDEs (5,6)** ✓ — matches the stated intent.
- **Oh My Zsh (7) before shell config (15)** ✓ — OMZ writes a template `~/.zshrc`;
  step 15 backs it up and replaces it. Correct order, no clobber risk.
- **SDKMAN (8) before Java (9) before build tools (10)** ✓.
- **Rancher (20) before docker pulls (21)** ✓.

Two ordering notes worth calling out (not bugs):

1. **Docker image pulls (21) almost always no-op on a first run.** Rancher Desktop
   (20) is installed but not launched, and its `docker` shim lives in `~/.rd/bin`,
   which is not on this script's `PATH` (it's only added in the `~/.zshrc` written
   at step 15, which isn't sourced into the running process). So `command -v docker`
   at line 932 is typically false on a fresh machine → the step warns and prints
   the manual `docker pull` commands. This is handled *gracefully* and is the right
   trade-off given the "no blocking Y/N prompts" requirement — just be aware image
   pulls are effectively a second-run feature. If you want them to work first-run,
   you'd need to launch Rancher and wait for the engine, which reintroduces a long
   blocking wait.

2. **AWS CLI (11) mid-script `sudo`** interrupts the otherwise unattended flow with
   a password prompt (see H2). Switching to `brew install awscli` removes the only
   `sudo` in the script and lets the whole run be truly hands-off.

---

## 🟢 Low / Nits

- **N1 — `configure_shell.sh` writes a `~/.zshrc` referencing Rancher PATH
  (`~/.rd/bin`) and SDKMAN before those may exist.** Harmless because the `.zshrc`
  guards each with `[ -d ]`/`[ -s ]` — noted only for completeness.
- **N2 — `for i in $(seq 1 12)` (line 937):** loop var `i` is unused; `for _ in
  $(seq 1 12)` documents intent. Micro-nit.
- **N3 — `validate_setup.sh` correctly omits `set -e`** (documented in-file) so it
  can report a full pass/fail summary — good, keep it. Worth mirroring that
  reasoning as a one-line comment in the other scripts explaining *why* `set -e`
  *is* wanted there.
- **N4 — Menu/`MAX_ITEM_NUMBER` coupling:** `MAX_ITEM_NUMBER=21` is maintained by
  hand. If a top-level item is ever added, this must be bumped or range-skips
  silently cap wrong. Consider a comment tying them together, or deriving it.
- **N5 — Homebrew analytics/first-run:** none of the install steps set
  `HOMEBREW_NO_ENV_HINTS=1` / `HOMEBREW_NO_AUTO_UPDATE=1`; setting the latter for
  the bulk-install phase noticeably speeds up a fresh run (each `brew install`
  otherwise re-checks for updates).

---

## Suggested priority order for fixes

1. **C2** (guard every `brew install`, collect failures) — biggest robustness win,
   also removes the most code duplication.
2. **C1** (`SCRIPT_DIR` + absolute sub-script paths) — prevents a half-configured
   machine when run from the "wrong" directory.
3. **H1** (`brew update || warn`), **H2** (AWS CLI → `brew install awscli`),
   **H3** (`ssh-add --apple-use-keychain`).
4. **M1–M4** as polish.
5. **Low/Nits** opportunistically.

Items 1–3 are the ones that meaningfully change whether a fresh-machine run
completes end-to-end without babysitting; the rest are hardening and hygiene.
