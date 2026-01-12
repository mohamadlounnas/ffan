//
//  PermissionsManager.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Manages installation of the helper tool
//

import Foundation
import Security
import AppKit

class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var isHelperInstalled = false
    
    private let helperPath = "/usr/local/bin/smc-helper"
    private let sudoersPath = "/etc/sudoers.d/smc-fan-helper"
    
    private init() {
        checkInstallation()
    }
    
    func checkInstallation() {
        // Run on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            let helperExists = fileManager.fileExists(atPath: self.helperPath)
            
            if !helperExists {
                DispatchQueue.main.async { self.isHelperInstalled = false }
                return
            }
            
            // Verify we can run it passwordless
            let success = self.verifySudoAccess()
            DispatchQueue.main.async {
                self.isHelperInstalled = success
            }
        }
    }
    
    private func verifySudoAccess() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        task.arguments = ["-n", self.helperPath, "info"]
        // Mute output
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func installHelper(completion: @escaping (Bool, String?) -> Void) {
        // 1. Locate the helper in the App Bundle
        guard let bundledHelperURL = Bundle.main.url(forResource: "smc-helper", withExtension: nil) else {
            completion(false, "App Bundle missing smc-helper. Re-build app.")
            return
        }
        
        let bundledPath = bundledHelperURL.path
        
        // 2. Construct the installation script
        // We handle everything in one sudo shell script for atomicity
        let script = """
        do shell script "mkdir -p /usr/local/bin && cp -f '\(bundledPath)' '\(helperPath)' && chown root:wheel '\(helperPath)' && chmod 755 '\(helperPath)' && mkdir -p /etc/sudoers.d && echo '%admin ALL=(root) NOPASSWD: \(helperPath)' > '\(sudoersPath)' && chmod 440 '\(sudoersPath)' && chown root:wheel '\(sudoersPath)'" with administrator privileges
        """
        
        // 3. Execute
        DispatchQueue.global(qos: .userInitiated).async {
             var error: NSDictionary?
             if let scriptObject = NSAppleScript(source: script) {
                 _ = scriptObject.executeAndReturnError(&error)
                 
                 DispatchQueue.main.async {
                     if let error = error {
                         let msg = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                         completion(false, msg)
                     } else {
                         self.checkInstallation() // Refresh state
                         completion(true, nil)
                     }
                 }
             } else {
                 DispatchQueue.main.async {
                     completion(false, "Failed to create installation script")
                 }
             }
        }
    }
}
