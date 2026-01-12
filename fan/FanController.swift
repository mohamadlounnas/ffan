//
//  FanController.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed for proper SMC fan control
//

import Foundation
import Combine
import IOKit

enum ControlMode: String, CaseIterable {
    case manual
    case automatic
}

class FanController: ObservableObject {
    @Published var mode: ControlMode = .manual
    @Published var manualSpeed: Int = 2000
    @Published var autoThreshold: Double = 60.0
    @Published var autoMaxSpeed: Int = 4000
    @Published var isControlEnabled = false
    @Published var lastWriteSuccess = false
    @Published var statusMessage: String = ""
    
    private weak var systemMonitor: SystemMonitor?
    private var autoControlTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    let minSpeed = 1000
    let maxSpeed = 6500
    
    private let fanTargetKeys = ["F0Tg", "F1Tg", "F2Tg", "F3Tg"]
    private let fanModeKeys = ["F0Md", "F1Md", "F2Md", "F3Md"]
    private let forceBitsKey = "FS! "
    
    init(systemMonitor: SystemMonitor) {
        self.systemMonitor = systemMonitor
        loadSettings()
    }
    
    deinit {
        stopAutoControl()
        restoreAutomaticControl()
    }
    
    func setManualSpeed(_ speed: Int) {
        guard mode == .manual else { return }
        
        let clampedSpeed = max(minSpeed, min(maxSpeed, speed))
        manualSpeed = clampedSpeed
        
        if isControlEnabled {
            applyFanSpeed(clampedSpeed)
        }
        
        saveSettings()
    }
    
    func setMode(_ newMode: ControlMode) {
        mode = newMode
        
        if newMode == .automatic {
            restoreAutomaticControl()
            startAutoControl()
        } else {
            stopAutoControl()
            enableManualMode()
            applyFanSpeed(manualSpeed)
        }
        
        saveSettings()
    }
    
    private func enableManualMode() {
        guard let monitor = systemMonitor else {
            statusMessage = "No system monitor available"
            return
        }
        
        // We do NOT use F0Md or FS! anymore as they are unsafe/unreliable on some models
        // Instead, we just control the Minimum Speed (F0Mn)
        // macOS will ensure fans don't go below this, but strict "manual" mode is harder to enforce safely
        
        isControlEnabled = true
        statusMessage = "Manual control enabled"
        print("Fan Control: Manual control enabled (Min Speed)")
    }
    
    private func restoreAutomaticControl() {
        guard let monitor = systemMonitor else { return }
        
        // Restore default minimum speeds
        // We assume defaults are around 2000 RPM or check monitor.fanMinSpeeds initial values?
        // Better: Set to safe low value (e.g. 1000 or 1500), the OS will override if needed
        // Ideally we should have saved the initial values on startup
        
        // Hardcoded safe default for now, or use what we measured as min speed
        let safeMin = Double(minSpeed)
        
        for i in 0..<monitor.numberOfFans {
            let key = String(format: "F%dMn", i)
            _ = monitor.writeSMCKey(key, value: safeMin)
        }
        
        isControlEnabled = false
        statusMessage = "Automatic mode restored"
        print("Fan Control: Automatic mode restored")
    }
    
    private func applyFanSpeed(_ speed: Int) {
        guard let monitor = systemMonitor else {
            statusMessage = "No system monitor"
            lastWriteSuccess = false
            return
        }
        
        let targetSpeed = Double(speed)
        var anySuccess = false
        
        // Helper tool path (Hardcoded for dev environment)
        let toolUrl = URL(fileURLWithPath: "/Users/mohamad/Library/Developer/Xcode/DeviceLogs/Mohamad-00008020-001E68283AF1402E/fan/fan/smc-write")
        
        // Set F{n}Mn (Minimum Speed) instead of Target/Mode
        // This forces the fan to spin AT LEAST this fast
        for i in 0..<monitor.numberOfFans {
            let key = String(format: "F%dMn", i)
            
            // Try direct write first (will fail if not root)
            if monitor.writeSMCKey(key, value: targetSpeed) {
                anySuccess = true
                print("Fan Control: Set \(key) = \(speed) RPM (Direct)")
            } else {
                // Try Privileged Helper
                print("Fan Control: Direct write failed. Attempting privileged helper...")
                
                // Get data type for key (e.g. fpe2 or flt)
                let type = monitor.getDataType(key: key) ?? "fpe2" // Default to fpe2 if unknown
                
                let command = "'\(toolUrl.path)' \(key) \(type) \(targetSpeed)"
                
                // Wrap in AppleScript to prompt for password
                let script = "do shell script \"\(command)\" with administrator privileges"
                
                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: script) {
                    _ = scriptObject.executeAndReturnError(&error)
                    if let error = error {
                        print("Fan Control: Helper failed: \(error)")
                        statusMessage = "Auth failed: \(error["NSAppleScriptErrorMessage"] ?? "Unknown")"
                    } else {
                        anySuccess = true
                        print("Fan Control: Set \(key) = \(speed) RPM (Helper)")
                    }
                } else {
                    print("Fan Control: Could not create AppleScript")
                }
            }
        }
        
        lastWriteSuccess = anySuccess
        if anySuccess {
            statusMessage = "Min Fan speed set to \(speed) RPM"
        }
    }
    
    func startAutoControl() {
        stopAutoControl()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.autoControlTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.updateAutoControl()
            }
            RunLoop.current.add(self.autoControlTimer!, forMode: .common)
            
            self.updateAutoControl()
        }
    }
    
    func stopAutoControl() {
        autoControlTimer?.invalidate()
        autoControlTimer = nil
    }
    
    private func updateAutoControl() {
        guard mode == .automatic, let monitor = systemMonitor else { return }
        
        let maxTemp = max(
            monitor.cpuTemperature ?? 0,
            monitor.gpuTemperature ?? 0
        )
        
        guard maxTemp > 0 else { return }
        
        let targetSpeed: Int
        
        if maxTemp < autoThreshold {
            return
        } else if maxTemp >= 95.0 {
            targetSpeed = autoMaxSpeed
        } else if maxTemp >= 85.0 {
            let ratio = (maxTemp - 85.0) / 10.0
            targetSpeed = Int(Double(autoMaxSpeed - 1500) * ratio) + autoMaxSpeed - 500
        } else {
            let tempRange = 85.0 - autoThreshold
            let speedRange = autoMaxSpeed - minSpeed
            let tempAboveThreshold = maxTemp - autoThreshold
            let ratio = tempAboveThreshold / tempRange
            targetSpeed = minSpeed + Int(Double(speedRange) * ratio)
        }
        
        if !isControlEnabled {
            enableManualMode()
        }
        applyFanSpeed(min(targetSpeed, maxSpeed))
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let savedMode = defaults.string(forKey: "fanControlMode") {
            mode = ControlMode(rawValue: savedMode) ?? .manual
        }
        
        let savedManualSpeed = defaults.integer(forKey: "manualFanSpeed")
        if savedManualSpeed >= minSpeed && savedManualSpeed <= maxSpeed {
            manualSpeed = savedManualSpeed
        }
        
        let savedThreshold = defaults.double(forKey: "autoThreshold")
        if savedThreshold >= 40 && savedThreshold <= 90 {
            autoThreshold = savedThreshold
        }
        
        let savedMaxSpeed = defaults.integer(forKey: "autoMaxSpeed")
        if savedMaxSpeed >= minSpeed && savedMaxSpeed <= maxSpeed {
            autoMaxSpeed = savedMaxSpeed
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: "fanControlMode")
        defaults.set(manualSpeed, forKey: "manualFanSpeed")
        defaults.set(autoThreshold, forKey: "autoThreshold")
        defaults.set(autoMaxSpeed, forKey: "autoMaxSpeed")
    }
    
    func setAutoThreshold(_ threshold: Double) {
        autoThreshold = max(40, min(90, threshold))
        saveSettings()
    }
    
    func setAutoMaxSpeed(_ speed: Int) {
        autoMaxSpeed = max(minSpeed, min(maxSpeed, speed))
        saveSettings()
    }
}
