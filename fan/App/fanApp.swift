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
    private var viewModel: FanControlViewModel?
    private var iconUpdateTimer: Timer?
    
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
        
        // Create popover content after a brief delay to ensure status bar is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self,
                  let statusBarManager = self.statusBarManager,
                  let viewModel = self.viewModel else { return }
            
            let popoverView = PopoverView(viewModel: viewModel)
            statusBarManager.setPopoverContent(popoverView)
            
            // Initialize monitoring
            self.initializeMonitoring()
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
        
        // Initial update
        updateStatusBarIcon()
    }
    
    private func updateStatusBarIcon() {
        guard let viewModel = viewModel,
              let statusBarManager = statusBarManager else { return }
        
        let maxTemp = viewModel.getMaxTemperature()
        let fanSpeed = viewModel.currentFanSpeed
        statusBarManager.updateIcon(fanSpeed: fanSpeed, temperature: maxTemp > 0 ? maxTemp : nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        iconUpdateTimer?.invalidate()
        viewModel?.stopMonitoring()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// SwiftUI App entry point
@main
struct ffanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use MenuBarExtra for macOS 13+ or Settings with empty content
        Settings {
            Text("ffan - Fan Control")
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}
