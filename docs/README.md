# ffan - macOS Fan Control 🌬️

<div align="center">

**A lightweight, powerful menu bar application for monitoring system temperatures and controlling fan speeds on macOS.**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 🎯 Overview

**ffan** is a modern macOS application that provides real-time monitoring of CPU/GPU temperatures and intelligent fan speed control. Built with SwiftUI and leveraging direct System Management Controller (SMC) access, ffan offers both manual and automatic temperature-based fan control for keeping your Mac cool and quiet.

### Why ffan?

- **🎨 Beautiful Design**: Liquid glass UI with modern macOS aesthetics
- **⚡ Lightweight**: Minimal resource usage, lives in your menu bar
- **🔒 Privacy-First**: All processing happens locally, no data collection
- **🛠️ Flexible Control**: Manual override or intelligent automatic mode
- **📊 Real-Time Monitoring**: Live temperature and fan speed readings
- **🚀 Native Performance**: Pure Swift implementation with no unnecessary dependencies

---

## ✨ Features

### Temperature Monitoring
- **Real-time CPU Temperature**: Accurate readings from SMC sensors (TC0P, TC0D, TC0E, TC0F)
- **GPU Temperature Tracking**: Monitor dedicated GPU thermal levels
- **Visual Feedback**: Color-coded indicators (green → yellow → orange → red)
- **History Tracking**: See temperature trends over time

### Fan Control
- **Manual Mode**: Set precise fan speeds (1000-6500 RPM)
- **Automatic Mode**: 
  - Temperature-based automatic adjustment
  - Configurable temperature thresholds
  - Adjustable aggressiveness levels (conservative, balanced, aggressive)
  - Intelligent ramping to prevent sudden speed changes
- **Multi-Fan Support**: Control all system fans simultaneously
- **Safe Fallback**: Automatic restoration of system-managed control on exit

### System Integration
- **Menu Bar Interface**: Quick access without cluttering your desktop
- **Launch at Login**: Auto-start support using modern ServiceManagement API (macOS 13+)
- **Demo Mode**: Test the interface with simulated data
- **Battery Awareness**: Monitor battery status and health (optional)
- **User Preferences**: Persistent settings stored securely

---

## 📋 Requirements

### System Requirements
- **Minimum**: macOS 11.0 (Big Sur)
- **Recommended**: macOS 13.0+ (Ventura or later) for full feature support
- **Architecture**: Intel x86_64 and Apple Silicon (M1/M2/M3+) compatible

### Permissions
- **Temperature Reading**: Works without special privileges on most Macs
- **Fan Control**: Requires root/admin access due to SMC write operations

---

## 🚀 Installation

### Option 1: Pre-built Binary (Recommended)
1. Download the latest release from the [Releases](../../releases) page
2. Move `ffan.app` to your `/Applications` folder
3. Right-click and select "Open" (first launch only, due to Gatekeeper)

### Option 2: Build from Source

#### Prerequisites
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Clone the repository
git clone https://github.com/yourusername/ffan.git
cd ffan
```

#### Build Steps
```bash
# Build with Xcode
open fan.xcodeproj
# Build using: Product → Build (⌘B)

# Or build via command line
xcodebuild -project fan.xcodeproj -scheme fan -configuration Release
```

#### Installing SMC Helper (Required for Fan Control)
```bash
cd tools/smc-helper
make
sudo ./install.sh
```

This installs the `smc-helper` binary with setuid permissions to `/usr/local/bin/`, allowing fan control without repeated password prompts.

---

## 📖 Usage

### First Launch

1. **Launch the App**: Click the ffan icon in your menu bar
2. **Permission Check**: ffan will test SMC access automatically
3. **Demo Mode**: If SMC access is restricted, enable Demo Mode to explore features

### Enabling Fan Control

#### Method 1: Using SMC Helper (Recommended)
```bash
# Install once (requires admin password)
cd tools/smc-helper
sudo ./install.sh
```

After installation, fan control will work seamlessly within the app.

#### Method 2: Running with sudo
```bash
sudo /Applications/ffan.app/Contents/MacOS/ffan
```

⚠️ **Note**: Running with sudo is not recommended for daily use due to security implications.

### Control Modes

#### Manual Mode
- **Purpose**: Direct fan speed control
- **Use Case**: When you need specific RPM for tasks (gaming, rendering, silence)
- **How to**:
  1. Toggle "Enable Fan Control"
  2. Select "Manual" mode
  3. Drag the speed slider to desired RPM

#### Automatic Mode
- **Purpose**: Temperature-responsive fan control
- **Use Case**: Automatic thermal management
- **Configuration**:
  - **Threshold Temperature**: When auto control kicks in (default: 60°C)
  - **Max Speed**: Upper RPM limit (default: 6500)
  - **Aggressiveness**: How quickly fans ramp up (0.0 = minimal, 1.5 = balanced, 3.0 = aggressive)

### Settings

- **Launch at Login**: Enable from the app's preferences
- **Temperature Units**: Celsius (default) or Fahrenheit
- **Refresh Rate**: Adjust polling frequency (balance between responsiveness and CPU usage)

---

## 🏗️ Architecture

### Project Structure

```
fan/
├── App/
│   └── fanApp.swift           # Main app entry, AppDelegate
├── Core/
│   ├── FanController.swift    # Fan control logic (manual + auto)
│   ├── SystemMonitor.swift    # SMC communication layer
│   ├── BatteryMonitor.swift   # Battery status tracking
│   ├── LaunchAtLoginManager.swift  # Login item management
│   ├── PermissionsManager.swift    # SMC access verification
│   ├── StatusBarManager.swift      # Menu bar interface
│   └── UserDefaultsManager.swift   # Persistent settings
├── UI/
│   ├── Views/                 # SwiftUI view components
│   └── Modifiers/             # Custom view modifiers
├── ViewModels/
│   └── FanControlViewModel.swift  # Main app state & business logic
└── Resources/
    ├── smc-helper             # Setuid helper for SMC writes
    └── smc-write.swift        # Alternative Swift implementation

tools/
├── smc-helper/
│   ├── smc.c                  # Low-level SMC C implementation
│   ├── smc.h                  # SMC definitions and structures
│   ├── Makefile               # Build configuration
│   └── install.sh             # Installation script
└── smc-write/
    └── Sources/               # Swift-based SMC writer
```

### Key Components

#### SystemMonitor
- **Responsibility**: Direct IOKit/SMC communication
- **Capabilities**: 
  - Temperature sensor readings (CPU, GPU, ambient)
  - Fan speed queries (current, min, max)
  - Multi-sensor aggregation
- **Implementation**: Uses IOKit framework for kernel-level SMC access

#### FanController
- **Modes**: Manual (fixed RPM) and Automatic (temp-based)
- **Safety**: 
  - Enforces min/max speed limits (1000-6500 RPM)
  - Automatic fallback on errors
  - Restoration of system control on exit
- **Algorithm**: Proportional-based auto control with configurable aggressiveness

#### FanControlViewModel
- **Pattern**: MVVM architecture with Combine
- **State Management**: Centralized app state with reactive bindings
- **Publishers**: Exposes temperature, fan speed, and control state

#### StatusBarManager
- **UI Layer**: NSStatusItem with SwiftUI popover
- **Icon Updates**: Dynamic menu bar icon reflecting current temperature
- **Lifecycle**: Manages popover show/hide and window focus

---

## 🔧 SMC Implementation

### What is SMC?

The **System Management Controller** is a subsystem in Mac computers that manages:
- Thermal sensors and cooling fans
- Battery charging and power management  
- Keyboard backlighting and ambient light sensing
- System power states

### How ffan Accesses SMC

```swift
// Simplified flow
1. Open IOService connection to "AppleSMC"
2. Create SMCParamStruct with desired key (e.g., "F0Tg" for fan 0 target)
3. Send IOConnectCallStructMethod with appropriate command
4. Parse response bytes based on SMC data type (fpe2, ui16, etc.)
```

### SMC Keys Used

| Key | Description | Type | Access |
|-----|-------------|------|--------|
| `TC0P` | CPU Package Temperature | sp78 | Read |
| `TC0D` | CPU Die Temperature | sp78 | Read |
| `TG0P` | GPU Package Temperature | sp78 | Read |
| `F0Ac` | Fan 0 Actual RPM | fpe2 | Read |
| `F0Mn` | Fan 0 Minimum RPM | fpe2 | Read |
| `F0Mx` | Fan 0 Maximum RPM | fpe2 | Read |
| `F0Tg` | Fan 0 Target RPM | fpe2 | Write* |
| `FS! ` | Force Fan Mode | ui8 | Write* |

*Write operations require root privileges

### Why Root Access?

macOS kernel restricts SMC write operations to protect against:
- Thermal damage from insufficient cooling
- Hardware instability from invalid commands
- Malicious software manipulating system thermals

**ffan's solution**: A small setuid helper binary (`smc-helper`) that validates and executes only safe fan control commands.

---

## 🛡️ Security Considerations

### Setuid Binary
- **Location**: `/usr/local/bin/smc-helper`
- **Permissions**: `4755` (setuid root)
- **Validation**: Helper validates all inputs before SMC writes
- **Scope**: Limited to fan control operations only

### Best Practices
- ✅ Review `smc-helper` source code before installation
- ✅ Install from trusted sources only
- ✅ Monitor system temperatures initially to ensure safe operation
- ❌ Don't run the main app with sudo (unnecessary security risk)
- ❌ Don't set extremely low fan speeds that could cause thermal throttling

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Areas for Contribution
- **Testing**: Report compatibility with different Mac models
- **Localization**: Translate UI to other languages
- **Features**: 
  - Per-fan control (current implementation controls all fans together)
  - Custom temperature curves
  - Notification on thermal events
  - Menu bar customization options
- **Documentation**: Improve setup guides, troubleshooting
- **Platform Support**: Enhanced Apple Silicon optimizations

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/ffan.git
cd ffan

# Open in Xcode
open fan.xcodeproj

# Build and run
# Select "fan" scheme and press ⌘R
```

### Coding Standards
- **Language**: Swift 5.9+
- **Style**: Follow Swift API Design Guidelines
- **Architecture**: MVVM with Combine for reactive bindings
- **UI**: SwiftUI with backwards compatibility considerations
- **Comments**: Document non-obvious SMC operations and thermal algorithms

### Pull Request Process
1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit changes (`git commit -m 'Add amazing feature'`)
3. Push to branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request with detailed description

---

## 📚 Additional Documentation

- [SMC Protocol Reference](./smc-protocol.md) *(coming soon)*
- [Thermal Management Guide](./thermal-guide.md) *(coming soon)*
- [Troubleshooting](./troubleshooting.md) *(coming soon)*
- [API Documentation](./api-docs.md) *(coming soon)*

---

## 🐛 Known Issues

- **Apple Silicon Macs**: Some M-series Macs have limited SMC sensor exposure compared to Intel models
- **External GPUs**: eGPU temperature monitoring not yet supported
- **MacBook Pro 2016-2019**: Fan control may require additional permissions on T2 chip models
- **macOS Sonoma Beta**: Minor UI glitches in early beta versions

See [Issues](../../issues) for current bugs and feature requests.

---

## ❓ FAQ

**Q: Is it safe to manually control my Mac's fans?**  
A: Yes, as long as you keep fans running at reasonable speeds. ffan enforces minimum speeds and monitors temperatures. If you're unsure, use Automatic mode.

**Q: Will this void my warranty?**  
A: No. You're only adjusting existing hardware controls, not modifying hardware or firmware.

**Q: Why does fan control need root access?**  
A: macOS protects SMC write operations in the kernel. This is a security feature to prevent malicious software from damaging hardware.

**Q: Can I use this on a MacBook?**  
A: Yes! ffan works on both MacBooks and desktop Macs. Consider battery impact when running fans at high speeds.

**Q: My temperatures aren't shown correctly.**  
A: Try these sensors: TC0P, TC0D, TC0E. Different Mac models use different sensor keys. Check the SystemMonitor code to add your model's sensors.

**Q: Does this work on Linux or Windows?**  
A: No, ffan is macOS-only due to SMC being Apple-specific hardware.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

### Third-Party Components
- **IOKit Framework**: Apple Inc. (system framework)
- **SwiftUI**: Apple Inc. (system framework)

---

## 🙏 Acknowledgments

- **SMC Research**: Thanks to the open-source community for SMC reverse engineering efforts
- **Beta Testers**: *(community members who helped test)*

---

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Email**: [mohamad@feeef.org](mailto:mohamad@feeef.org)

---

<div align="center">

**Made with ❤️ for the Mac community**

If you find ffan useful, consider starring ⭐ the repository!

[⬆ Back to Top](#ffan---macos-fan-control-)

</div>
