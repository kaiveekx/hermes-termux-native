#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#   Hermes Agent — Native Termux Installer
#   github.com/krishnakaushik25/hermes-termux-native
#   No proot. No glibc. Pure Bionic. Pure Termux.
# ═══════════════════════════════════════════════════════════════

set -e

# ── Colors ──────────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
B='\033[0;34m'
M='\033[0;35m'
C='\033[0;36m'
W='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${C}${BOLD}  $1${NC}"
  echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

step() {
  echo -e "${B}${BOLD}  ▶  $1${NC}"
}

ok() {
  echo -e "${G}  ✓  $1${NC}"
}

warn() {
  echo -e "${Y}  ⚠  $1${NC}"
}

err() {
  echo -e "${R}  ✗  $1${NC}"
}

info() {
  echo -e "${DIM}     $1${NC}"
}

ask() {
  echo -e "${M}  ?  ${BOLD}$1${NC}"
  echo -ne "${M}  ❯  ${NC}"
}

divider() {
  echo -e "${DIM}     ────────────────────────────────────────────${NC}"
}

# ── Header ───────────────────────────────────────────────────────
clear
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║         ⚕  HERMES AGENT — NATIVE TERMUX             ║"
echo "  ║                                                       ║"
echo "  ║   No proot  •  No glibc  •  Pure Android native      ║"
echo "  ║   github.com/krishnakaushik25/hermes-termux-native   ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DIM}  This installer will set up Hermes Agent natively in"
echo -e "  Termux without proot-distro or any Linux container."
echo -e "  Estimated time: 5–10 minutes (no Rust compilation needed)${NC}"
echo ""
echo -ne "${Y}  Press ENTER to begin installation...${NC}"
read

# ── Step 1: Environment Check ────────────────────────────────────
banner "Step 1 of 8 — Checking Environment"

if [ -z "$PREFIX" ]; then
  err "This script must be run inside Termux."
  exit 1
fi
ok "Termux environment detected"

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
  warn "Architecture is $ARCH — this installer is optimized for aarch64 (ARM64)."
  warn "Pre-built wheels may not work. Proceeding anyway..."
else
  ok "Architecture: aarch64 (ARM64) ✓"
fi

ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
ok "Android version: $ANDROID_VER"
ok "Environment check passed"

# ── Step 2: System Packages ──────────────────────────────────────
banner "Step 2 of 8 — Installing System Packages"

step "Updating package lists..."
pkg update -y -q 2>/dev/null || true
ok "Package lists updated"

PKGS="git clang rust make pkg-config libffi openssl nodejs ripgrep ffmpeg tmux python3.11"
step "Installing required packages..."
info "Packages: $PKGS"
echo ""

for pkg in $PKGS; do
  echo -ne "${DIM}     Installing $pkg...${NC}"
  if pkg install -y -q "$pkg" 2>/dev/null; then
    echo -e "\r${G}  ✓  $pkg${NC}                    "
  else
    echo -e "\r${Y}  ⚠  $pkg (already installed or skipped)${NC}          "
  fi
done

ok "All system packages ready"

# ── Step 3: Python 3.11 Venv ────────────────────────────────────
banner "Step 3 of 8 — Setting Up Python 3.11 Environment"

INSTALL_DIR="$HOME/hermes-agent-native"
VENV_DIR="$INSTALL_DIR/venv311"

if [ -d "$INSTALL_DIR" ]; then
  warn "Directory $INSTALL_DIR already exists."
  ask "Remove and reinstall? (y/n)"
  read CONFIRM
  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed existing installation"
  else
    info "Keeping existing directory and continuing..."
  fi
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

step "Creating Python 3.11 virtual environment..."
python3.11 -m venv venv311
ok "Virtual environment created at $VENV_DIR"

step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
ok "Virtual environment active"

step "Upgrading pip, setuptools, wheel..."
python -m pip install --upgrade pip setuptools wheel -q
ok "pip tools upgraded"

export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
ok "Android API level: $ANDROID_API_LEVEL"

# ── Step 4: Pre-built Wheels ─────────────────────────────────────
banner "Step 4 of 8 — Installing Pre-built Native Wheels"

info "These wheels were compiled on Android ARM64 so you don't"
info "need to wait 30+ minutes for Rust/C compilation."
echo ""

WHEELS_DIR="$(dirname "$0")/wheels"
WHEEL_INSTALL_FLAGS="--no-index --find-links=$WHEELS_DIR --no-build-isolation"

install_wheel() {
  PKG=$1
  echo -ne "${DIM}     Installing $PKG...${NC}"
  if pip install "$PKG" --find-links="$WHEELS_DIR" --no-build-isolation -q 2>/dev/null; then
    echo -e "\r${G}  ✓  $PKG installed from pre-built wheel${NC}                    "
  else
    echo -e "\r${Y}  ⚠  $PKG — falling back to build from source...${NC}           "
    pip install "$PKG" --no-build-isolation -q 2>/dev/null || warn "$PKG build failed — skipping"
  fi
}

install_wheel "psutil==7.2.2"
install_wheel "pyyaml==6.0.3"
install_wheel "MarkupSafe"
install_wheel "ruamel.yaml.clib==0.2.15"
install_wheel "cffi"
install_wheel "maturin"
install_wheel "jiter"
install_wheel "pydantic-core==2.41.5"
install_wheel "cryptography"

ok "All native wheels installed"

# ── Step 5: Hermes Agent ─────────────────────────────────────────
banner "Step 5 of 8 — Installing Hermes Agent"

step "Installing hermes-agent and all dependencies..."
info "This may take 1-2 minutes for pure Python packages..."
echo ""

pip install hermes-agent --only-binary=:all: -q
ok "hermes-agent installed successfully"

step "Installing additional tool dependencies..."
pip install edge-tts -q 2>/dev/null && ok "edge-tts (Text-to-Speech) installed" || warn "edge-tts skipped"
pip install setuptools-rust -q 2>/dev/null && ok "setuptools-rust installed" || true

step "Installing browser automation..."
npm install -g agent-browser --silent 2>/dev/null && ok "agent-browser installed" || warn "agent-browser skipped"

step "Creating hermes command symlink..."
ln -sf "$VENV_DIR/bin/hermes" "$PREFIX/bin/hermes"
ok "hermes command available system-wide"

# ── Step 6: Configuration ────────────────────────────────────────
banner "Step 6 of 8 — Configuring Hermes"

step "Running initial hermes setup (non-interactive)..."
hermes setup --defaults 2>/dev/null || true

mkdir -p "$HOME/.hermes"

step "Writing base configuration..."
python3 << 'PYEOF'
import os

env_path = os.path.expanduser('~/.hermes/.env')
config = """# ═══════════════════════════════════════════════════════
#   Hermes Agent — Environment Configuration
#   Edit this file to add your API keys
# ═══════════════════════════════════════════════════════

# ── Web Search (Free — SearXNG public instance) ──────
SEARXNG_URL=https://searx.be

# ── Gateway Access ───────────────────────────────────
# Set to true to allow all Telegram users (not recommended)
# GATEWAY_ALLOW_ALL_USERS=true
# Or set your Telegram user ID for secure access:
# TELEGRAM_ALLOWED_USERS=your_telegram_user_id

# ── Optional API Keys (add to unlock more tools) ─────
# TELEGRAM_BOT_TOKEN=         # Telegram bot token from @BotFather
# OPENROUTER_API_KEY=         # openrouter.ai — unlocks Mixture of Agents
# GITHUB_TOKEN=               # GitHub personal access token
# FAL_KEY=                    # fal.ai — Image Generation
# GROQ_API_KEY=               # Groq — Voice/STT (free tier available)
# EXA_API_KEY=                # Exa — Premium web search
# TAVILY_API_KEY=             # Tavily — Web search
"""

with open(env_path, 'w') as f:
    f.write(config)
print("  ✓  .env written")
PYEOF

# Set SEARXNG in config.yaml too
hermes config set SEARXNG_URL https://searx.be 2>/dev/null && ok "Web search configured (SearXNG)" || true

ok "Base configuration complete"

# ── Step 7: Telegram Setup ───────────────────────────────────────
banner "Step 7 of 8 — Telegram Setup (Optional)"

echo -e "${W}  Hermes can be controlled from Telegram — chat with your"
echo -e "  AI agent from anywhere, even when Termux is in the background.${NC}"
echo ""
divider
echo ""
ask "Set up Telegram now? (y/n)"
read SETUP_TG

if [ "$SETUP_TG" = "y" ] || [ "$SETUP_TG" = "Y" ]; then

  echo ""
  echo -e "${W}${BOLD}  📌 Getting Your Bot Token${NC}"
  echo ""
  echo -e "${DIM}  1. Open Telegram and search for ${W}@BotFather${DIM}"
  echo -e "  2. Send ${W}/newbot${DIM}"
  echo -e "  3. Choose a name  (e.g. \"My Hermes\")"
  echo -e "  4. Choose a username  (e.g. \"myhermes_bot\")"
  echo -e "  5. BotFather will give you a token like:"
  echo -e "     ${W}123456789:ABCDefghIJKlmnoPQRstu${NC}"
  echo ""
  ask "Paste your Bot Token here"
  read BOT_TOKEN

  echo ""
  echo -e "${W}${BOLD}  📌 Getting Your Telegram User ID${NC}"
  echo ""
  echo -e "${DIM}  1. Open Telegram and search for ${W}@userinfobot${DIM}"
  echo -e "  2. Send any message to it"
  echo -e "  3. It will reply with your numeric ID like: ${W}123456789${NC}"
  echo ""
  ask "Paste your Telegram User ID here"
  read TG_USER_ID

  # Write to .env
  python3 << PYEOF
import os

env_path = os.path.expanduser('~/.hermes/.env')
with open(env_path, 'r') as f:
    content = f.read()

content = content.replace('# TELEGRAM_BOT_TOKEN=', 'TELEGRAM_BOT_TOKEN=$BOT_TOKEN')
content = content.replace('# TELEGRAM_ALLOWED_USERS=your_telegram_user_id', 'TELEGRAM_ALLOWED_USERS=$TG_USER_ID')

with open(env_path, 'w') as f:
    f.write(content)
print("done")
PYEOF

  ok "Bot token and User ID saved to ~/.hermes/.env"

  echo ""
  divider
  echo ""
  echo -e "${W}${BOLD}  🚀 Starting Hermes Gateway for Pairing...${NC}"
  echo ""
  echo -e "${DIM}  Starting gateway in a background tmux session..."
  echo -e "  (You can view it anytime with: ${W}tmux attach -t hermes-gateway${DIM})${NC}"
  echo ""

  tmux new-session -d -s hermes-gateway "hermes gateway" 2>/dev/null || true
  sleep 3
  ok "Gateway started in tmux session: hermes-gateway"

  echo ""
  divider
  echo ""
  echo -e "${W}${BOLD}  📱 Now pair your Telegram account:${NC}"
  echo ""
  echo -e "${DIM}  1. Open Telegram"
  echo -e "  2. Search for your bot (the one you just created)"
  echo -e "  3. Send any message to it"
  echo -e "  4. The bot will reply with something like:"
  echo ""
  echo -e "     ${W}Hi~ I don't recognize you yet!"
  echo -e "     Here's your pairing code: ${C}9tsgdy${W}"
  echo -e "     Ask the bot owner to run:"
  echo -e "     hermes pairing approve telegram 9tsgdy${NC}"
  echo ""
  echo -e "${DIM}  5. Copy ONLY the pairing code (e.g. ${W}9tsgdy${DIM}) and paste below${NC}"
  echo ""
  ask "Paste your pairing code here"
  read PAIRING_CODE

  echo ""
  step "Approving pairing code: $PAIRING_CODE"
  if hermes pairing approve telegram "$PAIRING_CODE" 2>/dev/null; then
    ok "Pairing successful!"
  else
    warn "Pairing command returned an error — check if gateway is running with:"
    info "tmux attach -t hermes-gateway"
  fi

  echo ""
  step "Stopping temporary gateway session..."
  tmux kill-session -t hermes-gateway 2>/dev/null || true
  ok "Gateway stopped"

  echo ""
  echo -e "${G}${BOLD}  ✅ Telegram Setup Complete!${NC}"
  echo ""
  echo -e "${DIM}  Your bot is now paired and ready to use."
  echo ""
  echo -e "  To start the gateway anytime, run:"
  echo -e "    ${W}hermes gateway${NC}"
  echo ""
  echo -e "${DIM}  To keep it running in background:"
  echo -e "    ${W}tmux new-session -d -s hermes 'hermes gateway'${NC}"
  echo ""
  echo -e "${DIM}  Go ahead and message your bot on Telegram — it's live! 🎉${NC}"

else
  warn "Telegram setup skipped. You can set it up later with: hermes setup gateway"
fi

# ── Step 8: Final Check ──────────────────────────────────────────
banner "Step 8 of 8 — Final Verification"

step "Running hermes doctor..."
echo ""
hermes doctor 2>/dev/null || true

# ── Done ─────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║          🎉  Installation Complete!                  ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${W}  Quick reference:${NC}"
echo ""
echo -e "${G}  hermes${NC}                    Start chatting"
echo -e "${G}  hermes gateway${NC}            Start Telegram/messaging gateway"
echo -e "${G}  hermes doctor${NC}             Check tool status"
echo -e "${G}  hermes setup${NC}              Re-run configuration wizard"
echo -e "${G}  hermes setup model${NC}        Change AI model/provider"
echo -e "${G}  nano ~/.hermes/.env${NC}       Add API keys for more tools"
echo ""
echo -e "${DIM}  Config:  ~/.hermes/config.yaml"
echo -e "  Keys:    ~/.hermes/.env"
echo -e "  Logs:    ~/.hermes/logs/${NC}"
echo ""
echo -e "${C}  ⭐ Star the repo: github.com/krishnakaushik25/hermes-termux-native${NC}"
echo ""

