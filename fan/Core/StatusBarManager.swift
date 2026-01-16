//
//  StatusBarManager.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//  Animated status bar icon based on fan speed with dynamic display text
//

import AppKit
import SwiftUI
import Combine

class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var animationTimer: Timer?
    private var refreshTimer: Timer?
    private var currentRotation: CGFloat = 0
    private var currentFanSpeed: Int = 0
    private var currentTemperature: Double?
    private var currentPowerWatts: Double?
    private var displayMode: String = "temperature"
    
    func setupStatusBar() {
        DispatchQueue.main.async { [weak self] in
            self?.createStatusItem()
            // Start periodic refresh for power display
            self?.startRefreshTimer()
        }
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let power = BatteryMonitor.shared.batteryInfo.powerWatts
            self.currentPowerWatts = power
            self.updateDisplay()
        }
        RunLoop.current.add(refreshTimer!, forMode: .common)
    }
    
    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            return
        }
        
        // Set initial icon
        let image = createFanIcon(size: 16, rotation: 0)
        button.image = image
        button.image?.isTemplate = false // ensure visible regardless of system tint
        button.title = "ffan 85°"  // Initial temperature display with app name to ensure visibility
        button.imagePosition = .imageLeft
        button.toolTip = "ffan"
        
        print("StatusBar: Created status item - button exists: \(button), title=\(button.title), image=\(String(describing: button.image)), isTemplate=\(button.image?.isTemplate ?? false)")
        
        // Handle button click
        button.action = #selector(togglePopover)
        button.target = self
        
        // Create popover
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 340, height: 580)
    }
    
    private func createFanIcon(size: CGFloat, rotation: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSGraphicsContext.current?.cgContext.translateBy(x: size/2, y: size/2)
            NSGraphicsContext.current?.cgContext.rotate(by: rotation * .pi / 180)
            NSGraphicsContext.current?.cgContext.translateBy(x: -size/2, y: -size/2)
            
            let center = NSPoint(x: size/2, y: size/2)
            let bladeLength: CGFloat = size * 0.42
            
            for i in 0..<3 {
                let angle = CGFloat(i) * 120 * .pi / 180
                
                let bladePath = NSBezierPath()
                let hubRadius: CGFloat = size * 0.15
                
                let endX = center.x + cos(angle) * bladeLength
                let endY = center.y + sin(angle) * bladeLength
                
                let leftAngle = angle - 0.35
                let leftStartX = center.x + cos(leftAngle) * hubRadius
                let leftStartY = center.y + sin(leftAngle) * hubRadius
                let leftEndX = center.x + cos(angle - 0.2) * bladeLength * 0.9
                let leftEndY = center.y + sin(angle - 0.2) * bladeLength * 0.9
                
                let rightAngle = angle + 0.35
                let rightStartX = center.x + cos(rightAngle) * hubRadius
                let rightStartY = center.y + sin(rightAngle) * hubRadius
                let rightEndX = center.x + cos(angle + 0.15) * bladeLength * 0.95
                let rightEndY = center.y + sin(angle + 0.15) * bladeLength * 0.95
                
                bladePath.move(to: NSPoint(x: leftStartX, y: leftStartY))
                bladePath.curve(to: NSPoint(x: leftEndX, y: leftEndY),
                               controlPoint1: NSPoint(x: center.x + cos(angle - 0.25) * bladeLength * 0.5,
                                                     y: center.y + sin(angle - 0.25) * bladeLength * 0.5),
                               controlPoint2: NSPoint(x: leftEndX, y: leftEndY))
                
                bladePath.curve(to: NSPoint(x: rightEndX, y: rightEndY),
                               controlPoint1: NSPoint(x: endX, y: endY),
                               controlPoint2: NSPoint(x: rightEndX, y: rightEndY))
                
                bladePath.curve(to: NSPoint(x: rightStartX, y: rightStartY),
                               controlPoint1: NSPoint(x: center.x + cos(angle + 0.2) * bladeLength * 0.5,
                                                     y: center.y + sin(angle + 0.2) * bladeLength * 0.5),
                               controlPoint2: NSPoint(x: rightStartX, y: rightStartY))
                
                bladePath.close()
                
                NSColor.black.setFill()
                bladePath.fill()
            }
            
            let hubSize = size * 0.3
            let hubPath = NSBezierPath(ovalIn: NSRect(x: center.x - hubSize/2,
                                                       y: center.y - hubSize/2,
                                                       width: hubSize,
                                                       height: hubSize))
            NSColor.black.setFill()
            hubPath.fill()
            
            return true
        }
        
        image.isTemplate = true
        return image
    }
    
    func setPopoverContent<Content: View>(_ content: Content) {
        DispatchQueue.main.async { [weak self] in
            self?.popover?.contentViewController = NSHostingController(rootView: content)
        }
    }
    
    func updateIcon(fanSpeed: Int, temperature: Double?, powerWatts: Double? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.currentFanSpeed = fanSpeed
            self?.currentTemperature = temperature
            self?.currentPowerWatts = powerWatts
            self?.updateAnimationSpeed()
            self?.updateDisplay()
        }
    }
    
    func setDisplayMode(_ mode: String) {
        DispatchQueue.main.async { [weak self] in
            self?.displayMode = mode
            if let button = self?.statusItem?.button {
                if mode == "none" {
                    button.title = ""
                    button.imagePosition = .imageOnly
                } else {
                    button.imagePosition = .imageLeft
                }
            }
            self?.updateDisplay()
        }
    }
    
    private func updateDisplay() {
        guard let button = statusItem?.button else { return }
        
        // Update button title based on display mode
        let text = getDisplayText()
        // Use a compact font for the title to reduce visual length
        if text.isEmpty {
            button.title = ""
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .regular)
            ]
            button.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        }
        print("StatusBar: updateDisplay mode=\(displayMode) text='\(text)'")
    }
    
    private func getDisplayText() -> String {
        switch displayMode {
        case "none":
            return ""
        case "temperature":
            if let temp = currentTemperature {
                return String(format: "%.0f°", temp)
            }
            return "--°"
        case "power":
            // Prefer showing battery power in Watts when available
            if let pw = currentPowerWatts {
                return String(format: "%.1fW", pw)
            }
            // Fallback to fan percent if power not available
            let percentage = Int((Double(currentFanSpeed) / 6500.0) * 100)
            return "\(percentage)%"
        case "fanSpeedPercentage":
            let percentage = Int((Double(currentFanSpeed) / 6500.0) * 100)
            return "\(percentage)%"
        default:
            if let temp = currentTemperature {
                return String(format: "%.0f°", temp)
            }
            return "--°"
        }
    }
    
    private func updateAnimationSpeed() {
        // Stop existing animation
        animationTimer?.invalidate()
        animationTimer = nil
        
        guard currentFanSpeed > 0 else {
            // Fan is off, show static icon
            if let button = statusItem?.button {
                button.image = createFanIcon(size: 16, rotation: currentRotation)
            }
            return
        }
        
        // Calculate animation interval based on fan speed
        let minInterval: Double = 0.05  // ~20fps (smoother, less CPU)
        let speedFactor = Double(currentFanSpeed) / 6500.0
        let rotationSpeed = 1.0 + speedFactor * 5.0  // Much slower: 1-6 degrees per frame
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: minInterval, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem?.button else { return }
            
            self.currentRotation += rotationSpeed
            if self.currentRotation >= 360 {
                self.currentRotation -= 360
            }
            
            button.image = self.createFanIcon(size: 16, rotation: self.currentRotation)
        }
        
        RunLoop.current.add(animationTimer!, forMode: .common)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
    }
    
    deinit {
        animationTimer?.invalidate()
        refreshTimer?.invalidate()
    }
}
