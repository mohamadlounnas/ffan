//
//  ffanApp.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//  Fixed app lifecycle for menu bar app
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?
    var viewModel: FanControlViewModel?
    private var iconUpdateTimer: Timer?
    private var displayModeObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - MUST be called early
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize components immediately
        setupApplication()
    }
    
    private func setupApplication() {
        
        // Initialize view model
        let viewModel = FanControlViewModel()
        self.viewModel = viewModel
        
        // Initialize and setup status bar immediately
        let statusBarManager = StatusBarManager()
        self.statusBarManager = statusBarManager
        statusBarManager.setupStatusBar()
        
        // Set initial display mode
        let initialMode = UserDefaults.standard.string(forKey: "statusBarDisplayMode") ?? "temperature"
        statusBarManager.setDisplayMode(initialMode)
        
        // Listen for display mode changes
        displayModeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StatusBarDisplayModeChanged"),
            object: nil,
            queue: .main
        ) { [weak self, weak statusBarManager] notification in
            if let mode = notification.object as? String {
                statusBarManager?.setDisplayMode(mode)
            }
        }
        
        // Create popover content after a brief delay to ensure status bar is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self,
                  let statusBarManager = self.statusBarManager,
                  let viewModel = self.viewModel else { return }
            
            let popoverView = PopoverView(viewModel: viewModel, statusBarManager: statusBarManager)
            statusBarManager.setPopoverContent(popoverView)
            
            // Initialize monitoring
            self.initializeMonitoring()
            // TEST: force a display mode change to power to verify status bar updates (will be removed)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("App: TEST - forcing status bar mode to 'power'")
                statusBarManager.setDisplayMode("power")
            }
        }
    }
    
    private func initializeMonitoring() {
        guard let viewModel = viewModel else { return }
        
        // Start monitoring regardless of permission check
        // SMC read operations typically work without special privileges
        viewModel.startMonitoring()
        startIconUpdateTimer()
    }
    
    private func startIconUpdateTimer() {
        iconUpdateTimer?.invalidate()
        iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateStatusBarIcon()
        }
        RunLoop.current.add(iconUpdateTimer!, forMode: .common)
        print("App: started icon update timer")
        
        // Initial update
        updateStatusBarIcon()
        print("App: performed initial status bar update")
    }
    
    private func updateStatusBarIcon() {
        guard let viewModel = viewModel,
              let statusBarManager = statusBarManager else { return }
        
        let maxTemp = viewModel.getMaxTemperature()
        let fanSpeed = viewModel.currentFanSpeed
        let power = BatteryMonitor.shared.batteryInfo.powerWatts
        print("App: updateStatusBarIcon - fanSpeed=\(fanSpeed) temp=\(maxTemp) power=\(String(describing: power))")
        statusBarManager.updateIcon(fanSpeed: fanSpeed, temperature: maxTemp > 0 ? maxTemp : nil, powerWatts: power)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        iconUpdateTimer?.invalidate()
        viewModel?.stopMonitoring()
        
        if let observer = displayModeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// SwiftUI App entry point
@main
struct ffanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showSettingsWindow = false
    @StateObject private var viewModelForWindow = FanControlViewModel()
    
    var body: some Scene {
        // Use MenuBarExtra for macOS 13+ or Settings with empty content
        Settings {
            Text("ffan - Fan Control")
                .frame(width: 0, height: 0)
                .hidden()
        }
        
        // Settings Window Scene
        Window("ffan Settings", id: "settings") {
            SettingsWindowView(isOpen: $showSettingsWindow, viewModel: appDelegate.viewModel ?? viewModelForWindow)
                .onAppear {
                    print("Settings window opened")
                }
        }
        .keyboardShortcut(",", modifiers: .command)
    }
}
