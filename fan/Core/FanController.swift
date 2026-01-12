//
//  FanController.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed for proper SMC fan control with sudoers
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
    
    // Path to the installed smc-helper
    private var smcHelperPath: String {
        return "/usr/local/bin/smc-helper"
    }
    
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
        
        saveSettings() // Save immediately for UI responsiveness
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
        guard systemMonitor != nil else {
            statusMessage = "No system monitor available"
            return
        }
        isControlEnabled = true
        statusMessage = "Manual control enabled"
        print("Fan Control: Manual control enabled")
    }
    
    private func restoreAutomaticControl() {
        guard let monitor = systemMonitor else { return }
        guard monitor.numberOfFans > 0 else { return }
        
        // Execute 'auto' command for all fans
        var allSuccess = true
        for i in 0..<monitor.numberOfFans {
             if !runSmcHelper(args: ["auto", "\(i)"]) {
                 allSuccess = false
             }
        }
        
        if allSuccess {
            isControlEnabled = false
            statusMessage = "Automatic mode restored"
            print("Fan Control: Automatic mode restored")
        } else {
            statusMessage = "Failed to restore auto mode"
            print("Fan Control: Failed to restore auto mode")
        }
    }
    
    private func applyFanSpeed(_ speed: Int) {
        guard let monitor = systemMonitor else {
            statusMessage = "No system monitor"
            lastWriteSuccess = false
            return
        }
        
        guard monitor.numberOfFans > 0 else {
            statusMessage = "No fans detected"
            lastWriteSuccess = false
            return
        }
        
        // Apply speed to all fans
        var allSuccess = true
        for i in 0..<monitor.numberOfFans {
            if !runSmcHelper(args: ["set", "\(i)", "\(speed)"]) {
                allSuccess = false
            }
        }
        
        if allSuccess {
            statusMessage = "Fan target speed set to \(speed) RPM"
            lastWriteSuccess = true
            print("Fan Control: Set all fans target = \(speed) RPM")
        } else {
            statusMessage = "Failed to set fan speed"
            lastWriteSuccess = false
        }
    }
    
    /// Executes the smc-helper tool via sudo.
    /// Tries non-interactive (passwordless) sudo first.
    /// Falls back to AppleScript (prompt) if that fails.
    private func runSmcHelper(args: [String]) -> Bool {
        // 1. Try sudo -n (Non-interactive)
        // This relies on the sudoers file being set up correctly by install.sh
        let helperPath = smcHelperPath
        
        if !FileManager.default.fileExists(atPath: helperPath) {
            statusMessage = "Error: smc-helper not installed"
            print("Error: \(helperPath) not found")
            return false
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        task.arguments = ["-n", helperPath] + args
        task.environment = ["LANG": "C"] // Prevent locale issues
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                return true
            }
        } catch {
            print("Fan Control: sudo -n execution error: \(error)")
        }
        
        // 2. Fallback: AppleScript (Prompts user for password)
        // This handles cases where install.sh wasn't run or sudoers is broken.
        print("Fan Control: sudo -n failed. Falling back to AppleScript.")
        
        // Construct the full shell command string for AppleScript
        // e.g. '/usr/local/bin/smc-helper' set 0 4000
        let argsString = args.joined(separator: " ")
        let fullCommand = "'\(helperPath)' \(argsString)"
        
        let scriptSource = "do shell script \"\(fullCommand)\" with administrator privileges"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            _ = scriptObject.executeAndReturnError(&error)
            if let error = error {
                let errorMsg = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                print("Fan Control: AppleScript failed: \(errorMsg)")
                // Don't show confusing AppleScript errors to user in status, keep it simple
                return false
            }
            return true
        }
        
        return false
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
