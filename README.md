<div align="center">

# ⚕ Hermes Agent — Native Termux Installer

**The first native Android Termux installer for Hermes Agent.**
No proot. No glibc. No Linux container. Pure Bionic. Pure Termux.

[![Android](https://img.shields.io/badge/Android-7%2B-green?logo=android)](https://android.com)
[![Termux](https://img.shields.io/badge/Termux-F--Droid-blue?logo=f-droid)](https://f-droid.org/packages/com.termux/)
[![Architecture](https://img.shields.io/badge/arch-aarch64%20ARM64-orange)](https://github.com)
[![Hermes](https://img.shields.io/badge/Hermes%20Agent-v0.14.0-purple)](https://github.com/NousResearch/hermes-agent)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

</div>

---

## 🤔 Why This Repo Exists

Every other Hermes Agent guide for Android uses **proot-distro** — a compatibility layer that emulates a Linux environment inside Termux. While it works, it comes with real costs:

| | proot-distro | **This installer (native)** |
|---|---|---|
| Overhead | High (emulation layer) | None |
| Storage | ~2GB+ (full Linux distro) | ~400MB |
| Boot time | Slow | Instant |
| Termux integration | Poor | Full |
| Android tools access | Limited | Complete |
| Battery impact | Higher | Lower |

**Native = running directly on Android's Bionic libc**, the same way every Android app runs. No emulation, no container, no overhead.

---

## ✨ What's Included

- ✅ One-click install script
- ✅ Pre-built ARM64 wheels for all Rust/C packages (no 30-min compilation)
- ✅ Python 3.11 venv (required — Hermes has strict dependency pins)
- ✅ Web search pre-configured (SearXNG public instance, free)
- ✅ Text-to-Speech via Edge TTS (free)
- ✅ Browser automation via agent-browser
- ✅ Interactive Telegram onboarding with auto-pairing
- ✅ Full `.env` template with all configurable options

---

## 📋 Requirements

- Android 7.0+ (API 24+)
- **Termux from F-Droid** (NOT Google Play — the Play version is outdated)
- ARM64 device (aarch64) — most Android phones since 2015
- ~600MB free storage
- Internet connection

> ⚠️ **Important:** Install Termux from [F-Droid](https://f-droid.org/packages/com.termux/), not the Google Play Store. The Play Store version hasn't been updated since 2020 and will fail.

---

## 🚀 Installation

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/hermes-termux-native/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/YOUR_USERNAME/hermes-termux-native.git
cd hermes-termux-native
bash install.sh
```

The installer will guide you through everything interactively with clear explanations at each step.

---

## 📱 Telegram Setup

During installation, the script will:

1. Ask you for your **Bot Token** (get one from [@BotFather](https://t.me/BotFather) in 30 seconds)
2. Ask for your **Telegram User ID** (get it from [@userinfobot](https://t.me/userinfobot))
3. Auto-start the gateway and walk you through the pairing process
4. You just paste the pairing code — the script handles the rest

After setup, start the gateway anytime with:
```bash
hermes gateway
# or in background:
tmux new-session -d -s hermes 'hermes gateway'
```

---

## 🔧 Post-Install: Add API Keys

Edit `~/.hermes/.env` to unlock more tools:

```bash
nano ~/.hermes/.env
```

| Key | Tool | Cost |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Telegram gateway | Free |
| `OPENROUTER_API_KEY` | Mixture of Agents, fallback models | Free tier |
| `GITHUB_TOKEN` | Skills Hub, GitHub automation | Free |
| `GROQ_API_KEY` | Voice/STT | Free tier |
| `FAL_KEY` | Image generation | Paid |
| `EXA_API_KEY` | Premium web search | Paid |
| `TAVILY_API_KEY` | Web search | Free tier |

---

## 🛠️ Pre-built Wheels

The `wheels/` directory contains Android ARM64 pre-built wheels for packages that require Rust/C compilation. Without these, installation would require 30–60 minutes of compilation on-device.

| Wheel | Why needed |
|---|---|
| `psutil` | System monitoring — no Android wheel on PyPI |
| `pyyaml` | Config parsing — C extension |
| `jiter` | JSON parsing (OpenAI SDK dep) — Rust |
| `pydantic-core` | Data validation — Rust |
| `cryptography` | JWT/TLS — Rust + C |
| `ruamel.yaml.clib` | YAML parsing — C extension |
| `maturin` | Rust build backend |
| `cffi` | C foreign function interface |
| `MarkupSafe` | Jinja2 dep — C extension |

---

## ⚠️ Known Limitations on Android

| Feature | Status | Reason |
|---|---|---|
| Core CLI agent | ✅ Works | |
| Telegram gateway | ✅ Works | |
| Web search | ✅ Works | Via SearXNG |
| TTS | ✅ Works | Edge TTS |
| Browser automation | ✅ Works | agent-browser |
| Memory & Skills | ✅ Works | |
| Cron jobs | ✅ Works | |
| Voice/STT (local) | ❌ | No `ctranslate2` Android wheel |
| Docker backend | ❌ | No Docker in Termux |
| TUI rendering | ⚠️ Partial | Cursor rendering issues in some terminals |
| Background persistence | ⚠️ | Use `termux-wake-lock` + `tmux` |

---

## 💡 Tips

**Keep gateway running in background:**
```bash
tmux new-session -d -s hermes 'hermes gateway'
termux-wake-lock
```

**Prevent Android from killing Termux:**
- Enable "Disable battery optimization" for Termux in Android settings
- Run `termux-wake-lock` before starting the gateway

**Switch AI model:**
```bash
hermes setup model
```

**Check tool status:**
```bash
hermes doctor
```

---

## 🔄 Updating Hermes

```bash
cd ~/hermes-agent-native
source venv311/bin/activate
pip install --upgrade hermes-agent --only-binary=:all:
```

---

## 🤝 Contributing

Found a package that fails? Built a wheel for a new package? PRs welcome!

Especially needed:
- Wheels for newer Python versions (3.12, 3.13 when supported)
- Fixes for TUI rendering on Android terminals
- SSE streaming proxy for Gemini API compatibility

---

## 📜 Credits

- [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) — the agent itself
- This repo — native Android packaging, pre-built wheels, Telegram onboarding

---

<div align="center">
<b>Made with ❤️ for Android developers who refuse to use a PC</b>
</div>
