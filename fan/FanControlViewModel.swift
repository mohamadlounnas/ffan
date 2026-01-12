//
//  FanControlViewModel.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//  Fixed bindings and added proper state management
//

import Foundation
import Combine
import SwiftUI

@MainActor
class FanControlViewModel: ObservableObject {
    // Temperature readings
    @Published var cpuTemperature: Double?
    @Published var gpuTemperature: Double?
    
    // Fan data
    @Published var fanSpeeds: [Int] = []
    @Published var fanMinSpeeds: [Int] = []
    @Published var fanMaxSpeeds: [Int] = []
    @Published var numberOfFans: Int = 0
    @Published var currentFanSpeed: Int = 0
    
    // Control state
    @Published var controlMode: ControlMode = .manual
    @Published var manualSpeed: Int = 2000
    @Published var autoThreshold: Double = 60.0
    @Published var autoMaxSpeed: Int = 4000
    @Published var autoAggressiveness: Double = 1.5
    
    // Status
    @Published var isMonitoring = false
    @Published var hasAccess = false
    @Published var lastError: String?
    @Published var statusMessage: String = ""
    @Published var launchAtLogin = false
    @Published var lastWriteSuccess = false
    
    // Demo mode
    @Published var isDemoMode = false
    
    private let systemMonitor = SystemMonitor()
    let fanController: FanController
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.fanController = FanController(systemMonitor: systemMonitor)
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        self.isDemoMode = UserDefaults.standard.bool(forKey: "showDemoData")
        setupBindings()
    }
    
    private func setupBindings() {
        // System monitor bindings
        systemMonitor.$cpuTemperature
            .receive(on: DispatchQueue.main)
            .assign(to: &$cpuTemperature)
        
        systemMonitor.$gpuTemperature
            .receive(on: DispatchQueue.main)
            .assign(to: &$gpuTemperature)
        
        systemMonitor.$fanSpeeds
            .receive(on: DispatchQueue.main)
            .assign(to: &$fanSpeeds)
        
        systemMonitor.$fanMinSpeeds
            .receive(on: DispatchQueue.main)
            .assign(to: &$fanMinSpeeds)
        
        systemMonitor.$fanMaxSpeeds
            .receive(on: DispatchQueue.main)
            .assign(to: &$fanMaxSpeeds)
        
        systemMonitor.$numberOfFans
            .receive(on: DispatchQueue.main)
            .assign(to: &$numberOfFans)
        
        systemMonitor.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)
        
        systemMonitor.$hasAccess
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasAccess)
        
        systemMonitor.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
        
        // Fan controller bindings
        fanController.$mode
            .receive(on: DispatchQueue.main)
            .assign(to: &$controlMode)
        
        fanController.$manualSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: &$manualSpeed)
        
        fanController.$autoThreshold
            .receive(on: DispatchQueue.main)
            .assign(to: &$autoThreshold)
        
        fanController.$autoMaxSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: &$autoMaxSpeed)
        
        fanController.$autoAggressiveness
            .receive(on: DispatchQueue.main)
            .assign(to: &$autoAggressiveness)
        
        fanController.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage)
        
        fanController.$lastWriteSuccess
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastWriteSuccess)
        
        // Current fan speed from first fan
        $fanSpeeds
            .map { $0.first ?? 0 }
            .assign(to: &$currentFanSpeed)
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        systemMonitor.startMonitoring()
    }
    
    func stopMonitoring() {
        systemMonitor.stopMonitoring()
    }
    
    // MARK: - Fan Control
    
    func setManualSpeed(_ speed: Int) {
        fanController.setManualSpeed(speed)
    }
    
    func setControlMode(_ mode: ControlMode) {
        fanController.setMode(mode)
    }
    
    func resetToSystemControl() {
        fanController.resetToSystemControl()
    }
    
    func setAutoThreshold(_ threshold: Double) {
        fanController.setAutoThreshold(threshold)
    }
    
    func setAutoMaxSpeed(_ speed: Int) {
        fanController.setAutoMaxSpeed(speed)
    }
    
    func setAutoAggressiveness(_ value: Double) {
        fanController.setAutoAggressiveness(value)
    }
    
    // MARK: - Access Control
    
    func checkAccess() -> Bool {
        return systemMonitor.checkAccess()
    }
    
    func requestPermissions() {
        // Permissions are handled via smc-helper installation
        // The helper should already be installed via install.sh
        PermissionsManager.shared.checkInstallation()
    }
    
    // MARK: - Demo Mode
    
    func toggleDemoMode() {
        isDemoMode.toggle()
        UserDefaults.standard.set(isDemoMode, forKey: "showDemoData")
        
        // Restart monitoring to apply demo mode
        stopMonitoring()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }
    
    // MARK: - Helper Functions
    
    func getMaxTemperature() -> Double {
        return max(cpuTemperature ?? 0, gpuTemperature ?? 0)
    }
    
    func getTemperatureColor() -> Color {
        let maxTemp = getMaxTemperature()
        if maxTemp <= 0 {
            return .gray
        } else if maxTemp < 50 {
            return .blue
        } else if maxTemp < 70 {
            return .yellow
        } else if maxTemp < 85 {
            return .orange
        } else {
            return .red
        }
    }
    
    func getTemperatureStatus() -> String {
        let maxTemp = getMaxTemperature()
        if maxTemp <= 0 {
            return "No data"
        } else if maxTemp < 50 {
            return "Cool"
        } else if maxTemp < 70 {
            return "Normal"
        } else if maxTemp < 85 {
            return "Warm"
        } else {
            return "Hot!"
        }
    }
    
    func getFanSpeedPercent() -> Double {
        guard numberOfFans > 0,
              let minSpeed = fanMinSpeeds.first,
              let maxSpeed = fanMaxSpeeds.first,
              maxSpeed > minSpeed,
              currentFanSpeed >= 0 else {
            return 0
        }
        
        let range = Double(maxSpeed - minSpeed)
        guard range > 0 else { return 0 }
        
        let current = Double(max(0, currentFanSpeed - minSpeed))
        let percent = current / range
        
        // Ensure we return a valid percentage
        if percent.isNaN || percent.isInfinite {
            return 0
        }
        return min(1.0, max(0.0, percent))
    }
}
