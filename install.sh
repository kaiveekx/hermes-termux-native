#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#   Hermes Agent — Native Termux Installer
#   github.com/kaiveekx/hermes-termux-native
#   No proot. No glibc. Pure Bionic. Pure Termux.
# ═══════════════════════════════════════════════════════════════

set -e

# ── Colors ───────────────────────────────────────────────────────
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

step()  { echo -e "${B}${BOLD}  ▶  $1${NC}"; }
ok()    { echo -e "${G}  ✓  $1${NC}"; }
warn()  { echo -e "${Y}  ⚠  $1${NC}"; }
err()   { echo -e "${R}  ✗  $1${NC}"; }
info()  { echo -e "${DIM}     $1${NC}"; }
ask()   { echo -e "${M}  ?  ${BOLD}$1${NC}"; echo -ne "${M}  ❯  ${NC}"; }
readtty() { read "$@" < /dev/tty; }
divider() { echo -e "${DIM}     ────────────────────────────────────────────${NC}"; }

# ── Header ───────────────────────────────────────────────────────
clear
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║         ⚕  HERMES AGENT — NATIVE TERMUX             ║"
echo "  ║                                                       ║"
echo "  ║   No proot  •  No glibc  •  Pure Android native      ║"
echo "  ║   github.com/kaiveekx/hermes-termux-native           ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DIM}  This installer sets up Hermes Agent v0.16.0 natively in"
echo -e "  Termux — no proot-distro, no Linux container needed."
echo -e "  Pre-built ARM64 wheels skip all Rust/C compilation."
echo -e "  Estimated time: 5–10 minutes${NC}"
echo ""
echo -ne "${Y}  Press ENTER to begin installation...${NC}"
readtty DUMMY

# ── Step 1: Environment Check ────────────────────────────────────
banner "Step 1 of 8 — Checking Environment"

if [ -z "$PREFIX" ]; then
  err "This script must be run inside Termux."
  exit 1
fi
ok "Termux environment detected"

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
  warn "Architecture is $ARCH — optimized for aarch64 (ARM64). Proceeding anyway..."
else
  ok "Architecture: aarch64 (ARM64)"
fi

ANDROID_API=$(getprop ro.build.version.sdk 2>/dev/null || echo "unknown")
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
ok "Android $ANDROID_VER (API $ANDROID_API)"

# ── Step 2: System Packages ──────────────────────────────────────
banner "Step 2 of 8 — Installing System Packages"

step "Updating package lists..."
pkg update -y -q 2>/dev/null || true
ok "Package lists updated"

PKGS="git clang rust make pkg-config libffi openssl nodejs ripgrep ffmpeg tmux python3.11"
step "Installing required packages..."
echo ""
for pkg in $PKGS; do
  echo -ne "${DIM}     Installing $pkg...${NC}"
  if pkg install -y -q "$pkg" 2>/dev/null; then
    echo -e "\r${G}  ✓  $pkg${NC}                         "
  else
    echo -e "\r${Y}  ⚠  $pkg (skipped/already installed)${NC}   "
  fi
done
ok "System packages ready"

# ── Step 3: Python 3.11 Venv ────────────────────────────────────
banner "Step 3 of 8 — Setting Up Python 3.11 Environment"

INSTALL_DIR="$HOME/hermes-native"
VENV_DIR="$INSTALL_DIR/venv"

if [ -d "$INSTALL_DIR" ]; then
  warn "Directory $INSTALL_DIR already exists."
  ask "Remove and reinstall? (y/n)"
  readtty CONFIRM
  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed existing installation"
  fi
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

step "Creating Python 3.11 virtual environment..."
python3.11 -m venv venv
ok "Virtual environment created at $VENV_DIR"

step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
ok "Virtual environment active"

step "Upgrading pip, setuptools, wheel..."
python -m pip install --upgrade pip setuptools wheel setuptools-rust -q
ok "pip tools upgraded"

export ANDROID_API_LEVEL="$ANDROID_API"

# ── Step 4: Pre-built Wheels ─────────────────────────────────────
banner "Step 4 of 8 — Installing Pre-built Native Wheels"

info "These wheels were compiled on Android ARM64 —"
info "no 30-minute Rust/C compilation needed."
echo ""

WHEELS_DIR="$HOME/.hermes-wheels"
if [ ! -d "$WHEELS_DIR" ] || [ -z "$(ls -A $WHEELS_DIR 2>/dev/null)" ]; then
  step "Downloading pre-built ARM64 wheels..."
  mkdir -p "$WHEELS_DIR"
  curl -L --progress-bar https://github.com/kaiveekx/hermes-termux-native/releases/latest/download/wheels-arm64.tar.gz | tar -xz -C "$WHEELS_DIR" --strip-components=1
  ok "Wheels downloaded to $WHEELS_DIR"
else
  ok "Wheels already cached at $WHEELS_DIR"
fi

install_wheel() {
  PKG=$1
  echo -ne "${DIM}     Installing $PKG...${NC}"
  if pip install "$PKG" --find-links="$WHEELS_DIR" --no-build-isolation -q 2>/dev/null; then
    echo -e "\r${G}  ✓  $PKG${NC}                              "
  else
    echo -e "\r${Y}  ⚠  $PKG — building from source (slow)...${NC}"
    pip install "$PKG" --no-build-isolation -q 2>/dev/null || warn "$PKG failed — skipping"
  fi
}

# Install in dependency order
install_wheel "cffi"
install_wheel "maturin"
install_wheel "psutil==7.2.2"
install_wheel "pyyaml==6.0.3"
install_wheel "MarkupSafe"
install_wheel "ruamel.yaml.clib==0.2.15"
install_wheel "jiter"
install_wheel "pydantic-core==2.46.4"
install_wheel "cryptography"
install_wheel "httptools"
install_wheel "uvloop"
install_wheel "watchfiles"
install_wheel "aiohttp"

ok "All native wheels installed"

# ── Step 5: Hermes Agent ─────────────────────────────────────────
banner "Step 5 of 8 — Installing Hermes Agent v0.16.0"

step "Installing hermes-agent and dependencies..."
info "Installing pure Python packages (1-2 minutes)..."
echo ""

pip install "hermes-agent==0.16.0" --only-binary=:all: -q
ok "hermes-agent 0.16.0 installed"

step "Installing Text-to-Speech (Edge TTS)..."
pip install edge-tts -q 2>/dev/null && ok "edge-tts installed" || warn "edge-tts skipped"

step "Installing browser automation..."
npm install -g agent-browser --silent 2>/dev/null && ok "agent-browser installed" || warn "agent-browser skipped"

step "Creating hermes system command..."
ln -sf "$VENV_DIR/bin/hermes" "$PREFIX/bin/hermes"
ok "hermes available system-wide (no venv activation needed)"

# ── Step 6: Configuration ────────────────────────────────────────
banner "Step 6 of 8 — Configuring Hermes"

mkdir -p "$HOME/.hermes"

step "Running initial setup..."
hermes setup --defaults 2>/dev/null || true
step "Migrating config to latest version..."
hermes doctor --fix 2>/dev/null || true

step "Writing .env configuration..."
python3 << 'PYEOF'
import os

env_path = os.path.expanduser('~/.hermes/.env')
config = """# ═══════════════════════════════════════════════════════
#   Hermes Agent — Environment Configuration
#   github.com/kaiveekx/hermes-termux-native
# ═══════════════════════════════════════════════════════

# ── Web Search (Free — public SearXNG instance) ──────
SEARXNG_URL=https://searx.be

# ── Gateway Access ───────────────────────────────────
# Uncomment to allow all users (not recommended):
# GATEWAY_ALLOW_ALL_USERS=true
# Or set your Telegram user ID (recommended):
# TELEGRAM_ALLOWED_USERS=your_numeric_telegram_id

# ── Telegram ─────────────────────────────────────────
# TELEGRAM_BOT_TOKEN=        # from @BotFather

# ── Optional — unlock more tools ─────────────────────
# OPENROUTER_API_KEY=        # openrouter.ai (free tier) — Mixture of Agents
# GITHUB_TOKEN=              # GitHub personal token — Skills Hub
# GROQ_API_KEY=              # groq.com (free tier) — Voice/STT
# FAL_KEY=                   # fal.ai — Image generation
# TAVILY_API_KEY=            # tavily.com (free tier) — Web search
# EXA_API_KEY=               # exa.ai — Premium web search
"""
with open(env_path, 'w') as f:
    f.write(config)
print("done")
PYEOF

hermes config set SEARXNG_URL https://searx.be 2>/dev/null || true
ok "Configuration written to ~/.hermes/.env"

# ── Step 7: Post-install Notes ──────────────────────────────────
banner "Step 7 of 8 — Optional Setup"

echo -e "${W}  The following tools can be configured after installation:${NC}"
echo ""
echo -e "${G}  📱 Telegram Gateway${NC}"
echo -e "${DIM}     Chat with Hermes from anywhere via Telegram."
echo -e "     1. Get a bot token from @BotFather on Telegram"
echo -e "     2. Run: ${W}hermes setup gateway${NC}"
echo -e "${DIM}     3. Start gateway: ${W}hermes gateway${NC}"
echo ""
echo -e "${G}  🔑 API Keys (add to ~/.hermes/.env)${NC}"
echo -e "${DIM}     OPENROUTER_API_KEY  — Mixture of Agents (openrouter.ai free tier)"
echo -e "     GITHUB_TOKEN        — Skills Hub (github.com settings)"
echo -e "     GROQ_API_KEY        — Voice/STT (groq.com free tier)"
echo -e "     TAVILY_API_KEY      — Web search (tavily.com free tier)${NC}"
echo ""

# ── Step 8: Final Check ──────────────────────────────────────────
banner "Step 8 of 8 — Final Verification"

step "Running hermes doctor..."
echo ""
hermes doctor 2>/dev/null || true

# ── Done ─────────────────────────────────────────────────────────
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║           🎉  Installation Complete!                 ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${W}  Quick reference:${NC}"
echo ""
echo -e "  ${G}hermes${NC}                 Start chatting"
echo -e "  ${G}hermes gateway${NC}         Start Telegram gateway"
echo -e "  ${G}hermes doctor${NC}          Check tool status"
echo -e "  ${G}hermes setup model${NC}     Change AI model/provider"
echo -e "  ${G}nano ~/.hermes/.env${NC}    Add API keys for more tools"
echo ""
echo -e "${DIM}  Config:  ~/.hermes/config.yaml"
echo -e "  Keys:    ~/.hermes/.env"
echo -e "  Logs:    ~/.hermes/logs/${NC}"
echo ""
echo -e "${C}  ⭐ Star us: github.com/kaiveekx/hermes-termux-native${NC}"
echo ""
