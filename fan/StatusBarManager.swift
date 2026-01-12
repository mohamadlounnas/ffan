//
//  StatusBarManager.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed status bar icon visibility
//

import AppKit
import SwiftUI
import Combine

class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    func setupStatusBar() {
        // Create status bar item - MUST be called on main thread
        DispatchQueue.main.async { [weak self] in
            self?.createStatusItem()
        }
    }
    
    private func createStatusItem() {
        // Create status bar item with fixed length for better visibility
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {
            print("StatusBar: Failed to get button")
            return
        }
        
        // Set initial icon - use a simple approach first
        if let image = NSImage(systemSymbolName: "fan", accessibilityDescription: "Fan Control") {
            image.isTemplate = true
            button.image = image
        } else {
            // Fallback: create a simple text-based icon
            button.title = "🌀"
        }
        
        // Create popover
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 320, height: 480)
        
        // Handle button click
        button.action = #selector(togglePopover)
        button.target = self
        
        print("StatusBar: Status item created successfully")
    }
    
    func setPopoverContent<Content: View>(_ content: Content) {
        DispatchQueue.main.async { [weak self] in
            self?.popover?.contentViewController = NSHostingController(rootView: content)
        }
    }
    
    func updateIcon(temperature: Double?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateIconOnMainThread(temperature: temperature)
        }
    }
    
    private func updateIconOnMainThread(temperature: Double?) {
        guard let button = statusItem?.button else { return }
        
        // Color code based on temperature
        let color: NSColor
        if let temp = temperature {
            if temp < 50 {
                color = .systemBlue
            } else if temp < 70 {
                color = .systemYellow
            } else if temp < 85 {
                color = .systemOrange
            } else {
                color = .systemRed
            }
        } else {
            color = .labelColor
        }
        
        // Try multiple symbol names for compatibility
        let symbolNames = ["fan", "fanblades", "wind", "leaf"]
        var iconSet = false
        
        for symbolName in symbolNames {
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Fan Control") {
                image.isTemplate = true
                button.image = image
                button.contentTintColor = color
                iconSet = true
                break
            }
        }
        
        // Fallback if no symbol found
        if !iconSet {
            button.title = "🌀"
            button.image = nil
        }
        
        // Update tooltip
        if let temp = temperature {
            button.toolTip = String(format: "Temperature: %.1f°C", temp)
        } else {
            button.toolTip = "Fan Control"
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button,
              let popover = popover else {
            print("StatusBar: Cannot toggle - button or popover is nil")
            return
        }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Ensure we show relative to the button
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Make sure the popover window becomes key
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
    }
}
