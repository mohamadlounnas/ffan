# Changelog

All notable changes to ffan will be documented in this file.

## [1.2.4] - 2026-01-16

### Fixed
- **Wake/Unlock Resume**: Fixed automatic mode not reapplying fan settings after subsequent wake/unlock events
- Settings now apply immediately on wake without waiting for temperature readings
- Uses last applied speed or safe default (3000 RPM) when temperature not yet available

## [1.2.3] - 2026-01-16

### Fixed
- **Unlock Detection**: Added proper macOS unlock detection using `DistributedNotificationCenter`
- Now listens to `com.apple.screenIsUnlocked` for reliable unlock events
- Added `sessionDidBecomeActiveNotification` as fallback for session activation

## [1.2.2] - 2026-01-16

### Fixed
- **Startup Settings**: Wait for fans detection before applying control settings
- Use Combine to observe `numberOfFans` and apply settings when > 0
- Add retry mechanism in `reapplySettings` for wake scenarios

## [1.2.1] - 2026-01-16

### Fixed
- Settings not applying on app start
- Added `applyInitialSettings()` called from init

## [1.2.0] - 2026-01-16

### Added
- **Sleep/Wake Support**: App now properly handles system sleep and wake events
- Restores system control on sleep/lock
- Reapplies user settings on wake/unlock
- Uses NSWorkspace notifications for comprehensive event detection

## [1.1.2] - 2026-01-15

### Added
- One-liner install script: `curl -fsSL ... | bash`
- Opens ffan.app automatically after installation

## [1.1.1] - 2026-01-15

### Improved
- Landing page design
- Added GUI installation instructions

## [1.1.0] - 2026-01-15

### Added
- Gumroad integration for distribution
- Updated landing page with download buttons

## [1.0.6] - 2026-01-15

### Fixed
- Installation instructions - corrected helper tool path

## [1.0.5] - 2026-01-15

### Fixed
- Release notes path corrections

## [1.0.4] - 2026-01-15

### Improved
- Documentation updates
- Intel support verification

## [1.0.0] - 2026-01-14

### Added
- Initial release
- Temperature monitoring (CPU/GPU)
- Fan speed control (manual/automatic)
- Menu bar integration
- Launch at login support
- Privileged helper tool for SMC access
- Liquid glass UI design
