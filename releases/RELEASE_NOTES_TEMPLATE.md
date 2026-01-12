# Release Notes Template for ffan

## v1.0.0 - Initial Release (2026-01-12)

### 🎉 First Public Release!

**ffan** is now available! A lightweight, powerful macOS fan control application with real-time temperature monitoring.

---

### ✨ What's New
- 🌡️ **Temperature Monitoring**: Real-time CPU/GPU temperature readings from SMC
- 💨 **Fan Control**: Manual speed control or intelligent automatic mode
- 📊 **Animated Icon**: Menu bar icon rotates based on actual fan speed
- 🎨 **Beautiful UI**: Modern liquid glass design with SwiftUI
- 🚀 **Launch at Login**: Start automatically when you log in
- 🔋 **Battery Monitoring**: Track battery status and health
- 🎯 **Smart Auto Mode**: Temperature-based control with configurable aggressiveness
- 🔒 **Privacy-First**: All processing happens locally, zero telemetry

### 📦 Installation

**Quick Install:**
```bash
curl -L https://github.com/USERNAME/ffan/releases/download/v1.0.0/ffan-v1.0.0-macos.zip -o ffan.zip
unzip ffan.zip && mv ffan.app /Applications/ && rm ffan.zip
```

**Enable Fan Control:**
```bash
cd /Applications/ffan.app/Contents/Resources/tools/smc-helper
sudo ./install.sh
```

### 📥 Downloads

| File | Size | Description |
|------|------|-------------|
| [ffan-v1.0.0-macos.zip](link) | ~2MB | Recommended - Direct download |
| [ffan-v1.0.0-macos.dmg](link) | ~3MB | Professional installer |

**SHA256 Checksums:**
```
[checksum]  ffan-v1.0.0-macos.zip
[checksum]  ffan-v1.0.0-macos.dmg
```

### 💻 System Requirements
- macOS 11.0 (Big Sur) or later
- Recommended: macOS 13.0+ for full features
- Intel x86_64 or Apple Silicon (M1/M2/M3+)
- ~10MB disk space

### 🎯 Key Features Explained

#### Temperature Monitoring
- Reads from SMC sensors: TC0P, TC0D, TC0E, TC0F (CPU)
- GPU temperature support (TG0P, TG0D)
- Color-coded indicators: 🟢 → 🟡 → 🟠 → 🔴
- Works without special privileges

#### Fan Control Modes
- **Manual Mode**: Set exact RPM (1000-6500)
- **Automatic Mode**: 
  - Configurable temperature threshold
  - Adjustable max speed limit
  - Three aggressiveness levels
  - Smooth speed transitions

#### Safety Features
- Min/max speed enforcement (1000-6500 RPM)
- Automatic restoration of system control on quit
- Graceful error handling
- No writes without explicit user consent

### ⚠️ Important Notes

**First Launch:**
- Right-click → Open (first time only)
- macOS Gatekeeper may show warning (app is not notarized)

**Fan Control:**
- Requires `sudo` access for SMC writes
- Install `smc-helper` once to avoid repeated password prompts
- Temperature reading works without sudo

**Permissions:**
- No special permissions needed for temp monitoring
- Fan control needs root (SMC write protection)

### 🐛 Known Issues
- [ ] Some M-series Macs have fewer exposed SMC sensors
- [ ] External GPU temps not yet supported  
- [ ] Per-fan control not implemented (controls all fans together)
- [ ] No custom fan curves yet

See all issues: https://github.com/USERNAME/ffan/issues

### 📚 Documentation
- [Full Documentation](https://github.com/USERNAME/ffan/blob/main/docs/README.md)
- [FAQ](https://github.com/USERNAME/ffan/blob/main/docs/README.md#-faq)
- [Architecture Overview](https://github.com/USERNAME/ffan/blob/main/docs/README.md#-architecture)

### 🤝 Contributing
Contributions welcome! Areas of interest:
- Testing on different Mac models
- Enhanced Apple Silicon support
- Per-fan control
- Custom temperature curves
- Localization

See [Contributing Guide](https://github.com/USERNAME/ffan/blob/main/docs/README.md#-contributing)

### 🙏 Acknowledgments
- SMC reverse engineering community
- Beta testers
- Everyone who provided feedback

### 📄 License
MIT License - free and open source forever

---

**🌟 Enjoying ffan? Please star the repo and share with others!**

**Questions?** Open an [issue](https://github.com/USERNAME/ffan/issues)

**Full Changelog**: https://github.com/USERNAME/ffan/commits/v1.0.0
