//
//  PermissionsManager.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed with proper SMC access checking
//

import Foundation
import Security
import AppKit
import IOKit
import Combine

class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var smcAccessGranted = false
    @Published var lastError: String?
    
    private init() {
        checkSMCAccess()
    }
    
    // MARK: - SMC Access Check
    
    @discardableResult
    func checkSMCAccess() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else {
            lastError = "AppleSMC service not found"
            smcAccessGranted = false
            return false
        }
        
        defer { IOObjectRelease(service) }
        
        var connection: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        
        if result == kIOReturnSuccess {
            IOServiceClose(connection)
            smcAccessGranted = true
            lastError = nil
            return true
        } else {
            lastError = describeIOReturn(result)
            smcAccessGranted = false
            return false
        }
    }
    
    private func describeIOReturn(_ result: IOReturn) -> String {
        switch Int32(bitPattern: UInt32(result)) {
        case kIOReturnSuccess: return "Success"
        case kIOReturnNotPrivileged: return "Not privileged - run with sudo or as root"
        case kIOReturnNotOpen: return "Not open"
        case kIOReturnNotFound: return "Not found"
        default: return "Error code: \(result)"
        }
    }
    
    // MARK: - Admin Privileges
    
    func requestAdminPrivileges() -> Bool {
        if hasAdminPrivileges() {
            return true
        }
        
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)
        
        guard status == errAuthorizationSuccess, let auth = authRef else {
            return false
        }
        
        defer { AuthorizationFree(auth, AuthorizationFlags()) }
        
        var right = AuthorizationItem(name: kAuthorizationRightExecute, valueLength: 0, value: nil, flags: 0)
        var rights = AuthorizationRights(count: 1, items: &right)
        
        let authStatus = AuthorizationCopyRights(
            auth,
            &rights,
            nil,
            [.interactionAllowed, .extendRights, .preAuthorize],
            nil
        )
        
        return authStatus == errAuthorizationSuccess
    }
    
    func hasAdminPrivileges() -> Bool {
        return getuid() == 0
    }
    
    // MARK: - Alerts
    
    func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "SMC Access Required"
            alert.informativeText = """
            Fan Control needs to access the System Management Controller (SMC) to read temperatures and control fans.
            
            On macOS, this requires either:
            • Running the app with administrator privileges (sudo)
            • Disabling SIP (not recommended)
            • Using a privileged helper tool
            
            For now, you can enable Demo Mode to see how the app works.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Enable Demo Mode")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                UserDefaults.standard.set(true, forKey: "showDemoData")
            }
        }
    }
    
    func showRootRequiredAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Root Privileges Required"
            alert.informativeText = """
            To control fan speeds, the app needs root privileges.
            
            You can run the app from Terminal using:
            sudo /path/to/fan.app/Contents/MacOS/fan
            
            Reading temperatures should work without root.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - Sandbox Check
    
    func isSandboxed() -> Bool {
        let environ = ProcessInfo.processInfo.environment
        return environ["APP_SANDBOX_CONTAINER_ID"] != nil
    }
}
