# ffan - Fan Control for macOS

<div align="center">

**A lightweight, powerful menu bar application for monitoring system temperatures and controlling fan speeds on macOS.**

<!-- banner -->
![ffan banner](https://raw.githubusercontent.com/mohamadlounnas/ffan/main/docs/assets/banner.png)


[![Latest Release](https://img.shields.io/github/v/release/mohamadlounnas/ffan?style=for-the-badge)](https://github.com/mohamadlounnas/ffan/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/mohamadlounnas/ffan/total?style=for-the-badge)](https://github.com/mohamadlounnas/ffan/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-11.0+-blue.svg?style=for-the-badge&logo=apple)](https://www.apple.com/macos/)

### [⬇️ Download Latest Release](https://github.com/mohamadlounnas/ffan/releases/latest)

[📖 Documentation](docs/README.md) • [🐛 Report Bug](https://github.com/mohamadlounnas/ffan/issues) • [💡 Request Feature](https://github.com/mohamadlounnas/ffan/issues) • [⭐ Star on GitHub](https://github.com/mohamadlounnas/ffan)

</div>

---

## ⚡ Quick Start

```bash
# Download and install
curl -L https://github.com/mohamadlounnas/ffan/releases/latest/download/ffan-macos.zip -o ffan.zip
unzip ffan.zip
mv ffan.app /Applications/

# Install helper for fan control
cd /Applications/ffan.app/Contents/Resources/tools/smc-helper
sudo ./install.sh
```

## Features

- 🌡️ **Temperature Monitoring**: Real-time CPU and GPU temperature readings
- 💨 **Fan Speed Control**: Manual fan speed adjustment or automatic temperature-based control
- 📊 **Visual Feedback**: Color-coded temperature indicators and speed gauges
- 🚀 **Launch at Login**: Automatic startup support using modern ServiceManagement API
- 🎨 **Modern UI**: Liquid glass design with SwiftUI

## Requirements

- macOS 13.0 or later (for full functionality)
- macOS 11.0 minimum (with limited features)

## Important Notes

### SMC Access

This app accesses the System Management Controller (SMC) to read temperatures and control fans. Due to macOS security restrictions:

1. **Temperature Reading**: Works on most Macs without special privileges
2. **Fan Control**: Requires root/admin privileges on modern macOS versions

### Running with Admin Privileges

To enable fan control, you can run the app with sudo:

```bash
sudo /path/to/ffan.app/Contents/MacOS/ffan
```

### Demo Mode

If SMC access is restricted, you can enable Demo Mode to see how the app works with simulated data.

## Architecture

### Files

- **fanApp.swift**: Main app entry point and AppDelegate
- **SystemMonitor.swift**: SMC communication for temperature and fan speed readings
- **FanController.swift**: Fan speed control logic (manual and automatic modes)
- **FanControlViewModel.swift**: Main view model with Combine bindings
- **PermissionsManager.swift**: SMC access checking and permission dialogs
- **LaunchAtLoginManager.swift**: Login item registration (SMAppService for macOS 13+)
- **StatusBarManager.swift**: Menu bar icon and popover management
- **PopoverView.swift**: Main UI container
- **TemperatureView.swift**: Temperature display component
- **FanSpeedView.swift**: Fan speed display and slider
- **ControlModeView.swift**: Mode selection and settings

### SMC Keys Used

**Temperature Sensors:**
- `TC0P`, `TCXC`, `TC0E`, `TC0F`, `TC0D`, `TC1C-TC4C` - CPU temperatures
- `TGDD`, `TG0P`, `TG0D`, `TG0E`, `TG0F` - GPU temperatures
- `Tp09`, `Tp0T`, `Tp01`, `Tp05`, `Tp0D`, `Tp0b` - Apple Silicon temperatures

**Fan Control:**
- `F0Ac`, `F1Ac`, etc. - Actual fan speed
- `F0Mn`, `F0Mx` - Min/Max fan speed
- `F0Tg` - Target fan speed (for manual control)
- `F0Md` - Fan mode (0=auto, 1=manual)
- `FS! ` - Force bits for manual control

## Control Modes

### Manual Mode
- Set a fixed fan speed using the slider
- Speed is maintained regardless of temperature

### Automatic Mode
- Fan speed adjusts based on temperature threshold
- Below threshold: System manages fans
- Above threshold: Linear interpolation to max speed
- Critical (95°C+): Maximum fan speed

## Build Configuration

The project uses:
- Sandbox: **Disabled** (required for SMC access)
- Hardened Runtime: **Enabled**
- IOKit Framework: Linked
- ServiceManagement Framework: Linked

## Known Limitations

1. **Apple Silicon Macs**: SMC structure may differ; some temperature keys may not work
2. **Fan Control**: Writing to SMC requires elevated privileges
3. **Sandbox**: Must be disabled for SMC access; not suitable for App Store

## License

This project is provided as-is for educational purposes.

## Troubleshooting

### No Temperature Data
- Ensure the app has SMC access (not sandboxed)
- Try running with sudo for full access
- Enable Demo Mode to test the UI

### Fan Control Not Working
- Fan control requires root privileges on modern macOS
- Run with `sudo` or create a privileged helper tool

### App Not Appearing in Menu Bar
- Check if the app is running in Activity Monitor
- Look for the fan icon in the menu bar
