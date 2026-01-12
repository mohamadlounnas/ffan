//
//  fanApp.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed app lifecycle for menu bar app
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?
    private var viewModel: FanControlViewModel?
    private var iconUpdateTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App: applicationDidFinishLaunching called")
        
        // Hide dock icon - MUST be called early
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize components immediately
        setupApplication()
    }
    
    private func setupApplication() {
        print("App: Setting up application...")
        
        // Initialize view model
        let viewModel = FanControlViewModel()
        self.viewModel = viewModel
        
        // Initialize and setup status bar immediately
        let statusBarManager = StatusBarManager()
        self.statusBarManager = statusBarManager
        statusBarManager.setupStatusBar()
        
        print("App: Status bar manager created")
        
        // Create popover content after a brief delay to ensure status bar is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self,
                  let statusBarManager = self.statusBarManager,
                  let viewModel = self.viewModel else { return }
            
            let popoverView = PopoverView(viewModel: viewModel)
            statusBarManager.setPopoverContent(popoverView)
            print("App: Popover content set")
            
            // Initialize monitoring
            self.initializeMonitoring()
        }
    }
    
    private func initializeMonitoring() {
        guard let viewModel = viewModel else { return }
        
        print("App: Initializing monitoring...")
        
        // Check SMC access
        // Try to access SMC first
        if viewModel.checkAccess() {
            print("App: SMC access granted, starting monitoring")
            viewModel.startMonitoring()
            startIconUpdateTimer()
        } else {
            print("App: SMC access denied")
            // Try to force start monitoring anyway - sometimes checkAccess fails but read works
            // or we might need to prompt for permissions (which we can't easily do for SMC IOKit)
            // For now, let's NOT enable demo mode by default unless explicitly asked
            // This way the user sees 0 or empty values which indicates an error rather than fake data
            
            if UserDefaults.standard.bool(forKey: "showDemoData") {
                print("App: Demo mode enabled by user setting")
                viewModel.startMonitoring()
            } else {
                print("App: Attempting to start monitoring despite check failure (hope for the best)")
                viewModel.startMonitoring()
            }
             startIconUpdateTimer()
        }
    }
    
    private func startIconUpdateTimer() {
        iconUpdateTimer?.invalidate()
        iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateStatusBarIcon()
        }
        RunLoop.current.add(iconUpdateTimer!, forMode: .common)
        
        // Initial update
        updateStatusBarIcon()
        print("App: Icon update timer started")
    }
    
    private func updateStatusBarIcon() {
        guard let viewModel = viewModel,
              let statusBarManager = statusBarManager else { return }
        
        let maxTemp = viewModel.getMaxTemperature()
        let fanSpeed = viewModel.currentFanSpeed
        statusBarManager.updateIcon(fanSpeed: fanSpeed, temperature: maxTemp > 0 ? maxTemp : nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("App: Terminating...")
        iconUpdateTimer?.invalidate()
        viewModel?.stopMonitoring()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// SwiftUI App entry point
@main
struct fanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use MenuBarExtra for macOS 13+ or Settings with empty content
        Settings {
            Text("Fan Control")
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}
