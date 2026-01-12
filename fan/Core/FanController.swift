//
//  FanController.swift
//  ffan
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
    @Published var autoMaxSpeed: Int = 6500
    @Published var autoAggressiveness: Double = 1.5  // 0.0 = always min, 1.5 = temp-based, 3.0 = always max
    @Published var isControlEnabled = false
    @Published var lastWriteSuccess = false
    @Published var statusMessage: String = ""
    @Published var lastAppliedSpeed: Int = 0  // Track what we last applied
    
    private weak var systemMonitor: SystemMonitor?
    private var autoControlTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: Date = .distantPast
    
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
    
    /// Call after monitoring has started to apply the saved mode
    func applyCurrentSettings() {
        print("Fan Control: Applying current settings - Mode: \(mode)")
        
        // Give the system monitor a moment to detect fans
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if self.mode == .automatic {
                self.startAutoControl()
            } else {
                self.enableManualMode()
                self.applyFanSpeed(self.manualSpeed)
            }
        }
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
            
            // Run immediately
            self.updateAutoControl()
            
            // Then every 2 seconds for more responsive updates
            self.autoControlTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.updateAutoControl()
            }
            RunLoop.current.add(self.autoControlTimer!, forMode: .common)
        }
    }
    
    func stopAutoControl() {
        autoControlTimer?.invalidate()
        autoControlTimer = nil
    }
    
    private func updateAutoControl() {
        guard mode == .automatic, let monitor = systemMonitor else { return }
        
        let currentTemp = max(
            monitor.cpuTemperature ?? 0,
            monitor.gpuTemperature ?? 0
        )
        
        guard currentTemp > 0 else { return }
        
        // ═══════════════════════════════════════════════════════════════
        // Dynamic Control System - Blending Architecture
        // ═══════════════════════════════════════════════════════════════
        // Response parameter (0 to 3) controls the blend between three states:
        //   Response = 0.0  →  Always MINIMUM speed (override mode)
        //   Response = 1.5  →  Pure TEMPERATURE-based control (auto mode)
        //   Response = 3.0  →  Always MAXIMUM speed (override mode)
        // The system smoothly interpolates between these states.
        // ═══════════════════════════════════════════════════════════════
        
        let response = autoAggressiveness  // Range: 0.0 to 3.0
        let midPoint = 1.5  // The "pure auto" point
        
        // Step 1: Calculate pure temperature-based speed
        // Using fixed range 30°C-90°C for predictable behavior
        // At 50°C: ratio = 20/60 = 0.33 → speed ≈ 2800-3000 RPM
        let tempFloor = 30.0
        let tempCeiling = 90.0
        let tempRatio = max(0.0, min(1.0, (currentTemp - tempFloor) / (tempCeiling - tempFloor)))
        let tempBasedSpeed = Double(minSpeed) + Double(autoMaxSpeed - minSpeed) * tempRatio
        
        // Step 2: Blend based on response setting
        let targetSpeed: Double
        
        if response <= midPoint {
            // Region 1: Blend between MINIMUM and TEMPERATURE-BASED
            // response=0.0 → 100% minSpeed
            // response=1.5 → 100% tempBasedSpeed
            let blend = response / midPoint  // 0.0 to 1.0
            targetSpeed = Double(minSpeed) * (1.0 - blend) + tempBasedSpeed * blend
        } else {
            // Region 2: Blend between TEMPERATURE-BASED and MAXIMUM
            // response=1.5 → 100% tempBasedSpeed
            // response=3.0 → 100% maxSpeed
            let blend = (response - midPoint) / (3.0 - midPoint)  // 0.0 to 1.0
            targetSpeed = tempBasedSpeed * (1.0 - blend) + Double(autoMaxSpeed) * blend
        }
        
        // Step 3: Apply the calculated speed
        if !isControlEnabled {
            enableManualMode()
        }
        
        let finalSpeed = Int(max(Double(minSpeed), min(targetSpeed, Double(autoMaxSpeed))))
        
        // Only apply if speed changed significantly (avoid unnecessary SMC calls)
        if abs(finalSpeed - lastAppliedSpeed) >= 50 || lastAppliedSpeed == 0 {
            applyFanSpeed(finalSpeed)
            lastAppliedSpeed = finalSpeed
            
            // Update status with debug info
            DispatchQueue.main.async { [weak self] in
                self?.statusMessage = "Auto: \(finalSpeed) RPM (Response: \(String(format: "%.1f", self?.autoAggressiveness ?? 0)))"
            }
        }
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
        
        let savedAggressiveness = defaults.double(forKey: "autoAggressiveness")
        if savedAggressiveness >= 0.0 && savedAggressiveness <= 3.0 {
            autoAggressiveness = savedAggressiveness
        }
    }
    
    // Explicitly return control to system (SMC auto behavior) without app interference
    func resetToSystemControl() {
        print("Fan Control: Resetting to system default...")
        stopAutoControl()
        restoreAutomaticControl()
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: "fanControlMode")
        defaults.set(manualSpeed, forKey: "manualFanSpeed")
        defaults.set(autoThreshold, forKey: "autoThreshold")
        defaults.set(autoMaxSpeed, forKey: "autoMaxSpeed")
        defaults.set(autoAggressiveness, forKey: "autoAggressiveness")
    }
    
    func setAutoThreshold(_ threshold: Double) {
        autoThreshold = max(40, min(90, threshold))
        saveSettings()
        // Force immediate update in auto mode
        if mode == .automatic {
            lastAppliedSpeed = 0  // Reset to force update
            updateAutoControl()
        }
    }
    
    func setAutoMaxSpeed(_ speed: Int) {
        autoMaxSpeed = max(minSpeed, min(maxSpeed, speed))
        saveSettings()
        // Force immediate update in auto mode
        if mode == .automatic {
            lastAppliedSpeed = 0  // Reset to force update
            updateAutoControl()
        }
    }
    
    func setAutoAggressiveness(_ value: Double) {
        autoAggressiveness = max(0.0, min(3.0, value))
        saveSettings()
        // Force immediate update in auto mode
        if mode == .automatic {
            lastAppliedSpeed = 0  // Reset to force update
            updateAutoControl()
        }
    }
}
