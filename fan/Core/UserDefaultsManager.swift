//
//  UserDefaultsManager.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Fan Control Settings
    
    var controlMode: ControlMode {
        get {
            if let mode = defaults.string(forKey: "fanControlMode"),
               mode == "automatic" {
                return .automatic
            }
            return .manual
        }
        set {
            defaults.set(newValue == .automatic ? "automatic" : "manual", forKey: "fanControlMode")
        }
    }
    
    var manualFanSpeed: Int {
        get {
            let speed = defaults.integer(forKey: "manualFanSpeed")
            return speed > 0 ? speed : 2000
        }
        set {
            defaults.set(newValue, forKey: "manualFanSpeed")
        }
    }
    
    var autoThreshold: Double {
        get {
            let threshold = defaults.double(forKey: "autoThreshold")
            return threshold > 0 ? threshold : 60.0
        }
        set {
            defaults.set(newValue, forKey: "autoThreshold")
        }
    }
    
    var autoMaxSpeed: Int {
        get {
            let speed = defaults.integer(forKey: "autoMaxSpeed")
            return speed > 0 ? speed : 4000
        }
        set {
            defaults.set(newValue, forKey: "autoMaxSpeed")
        }
    }
    
    // MARK: - Launch at Login
    
    var launchAtLogin: Bool {
        get {
            return defaults.bool(forKey: "launchAtLogin")
        }
        set {
            defaults.set(newValue, forKey: "launchAtLogin")
        }
    }
    
    // MARK: - Temperature Units
    
    var useCelsius: Bool {
        get {
            return defaults.object(forKey: "useCelsius") as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: "useCelsius")
        }
    }
    
    // MARK: - Monitoring Settings
    
    var monitoringInterval: TimeInterval {
        get {
            let interval = defaults.double(forKey: "monitoringInterval")
            return interval > 0 ? interval : 2.0
        }
        set {
            defaults.set(newValue, forKey: "monitoringInterval")
        }
    }
    
    // MARK: - UI Settings
    
    var statusBarDisplayMode: String {
        get {
            return defaults.string(forKey: "statusBarDisplayMode") ?? "temperature"
        }
        set {
            defaults.set(newValue, forKey: "statusBarDisplayMode")
        }
    }
    
    var enableNotifications: Bool {
        get {
            return defaults.object(forKey: "enableNotifications") as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: "enableNotifications")
        }
    }
    
    var highTempAlert: Double {
        get {
            let temp = defaults.double(forKey: "highTempAlert")
            return temp > 0 ? temp : 85.0
        }
        set {
            defaults.set(newValue, forKey: "highTempAlert")
        }
    }
    
    var autoSwitchMode: Bool {
        get {
            return defaults.object(forKey: "autoSwitchMode") as? Bool ?? false
        }
        set {
            defaults.set(newValue, forKey: "autoSwitchMode")
        }
    }
    
    // MARK: - Helper Methods
    
    func resetToDefaults() {
        defaults.removeObject(forKey: "fanControlMode")
        defaults.removeObject(forKey: "manualFanSpeed")
        defaults.removeObject(forKey: "autoThreshold")
        defaults.removeObject(forKey: "autoMaxSpeed")
        defaults.removeObject(forKey: "launchAtLogin")
        defaults.removeObject(forKey: "useCelsius")
        defaults.removeObject(forKey: "monitoringInterval")
        defaults.removeObject(forKey: "statusBarDisplayMode")
        defaults.removeObject(forKey: "enableNotifications")
        defaults.removeObject(forKey: "highTempAlert")
        defaults.removeObject(forKey: "autoSwitchMode")
    }
}
