//
//  LaunchAtLoginManager.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//  Updated for modern ServiceManagement API (macOS 13+)
//

import Foundation
import ServiceManagement
import Combine
import AppKit

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published private(set) var registrationStatus: String = "Unknown"
    
    private init() {
        updateStatus()
    }
    
    var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return UserDefaults.standard.bool(forKey: "launchAtLogin")
            }
        }
        set {
            if #available(macOS 13.0, *) {
                setLaunchAtLoginModern(newValue)
            } else {
                setLaunchAtLoginLegacy(newValue)
            }
        }
    }
    
    // Modern API (macOS 13+)
    @available(macOS 13.0, *)
    private func setLaunchAtLoginModern(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
                registrationStatus = "Enabled"
                print("LaunchAtLogin: Successfully registered")
            } else {
                try SMAppService.mainApp.unregister()
                registrationStatus = "Disabled"
                print("LaunchAtLogin: Successfully unregistered")
            }
        } catch {
            registrationStatus = "Error: \(error.localizedDescription)"
            print("LaunchAtLogin: Error - \(error)")
        }
        
        UserDefaults.standard.set(enable, forKey: "launchAtLogin")
    }
    
    // Legacy fallback (pre-macOS 13)
    private func setLaunchAtLoginLegacy(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: "launchAtLogin")
        registrationStatus = enable ? "Enabled (manual)" : "Disabled"
        
        // Note: LSSharedFileList APIs are deprecated and removed
        // Users on older macOS need to add manually to Login Items
        print("LaunchAtLogin: Preference saved. For macOS < 13, add manually in System Settings > General > Login Items")
    }
    
    private func updateStatus() {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                registrationStatus = "Enabled"
            case .notRegistered:
                registrationStatus = "Not registered"
            case .requiresApproval:
                registrationStatus = "Requires approval in System Settings"
            case .notFound:
                registrationStatus = "Not found"
            @unknown default:
                registrationStatus = "Unknown"
            }
        } else {
            registrationStatus = UserDefaults.standard.bool(forKey: "launchAtLogin") ? "Enabled (manual)" : "Disabled"
        }
    }
    
    func openLoginItemsSettings() {
        if #available(macOS 13.0, *) {
            // Open System Settings > General > Login Items
            if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Open System Preferences > Users & Groups
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.users") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
