//
//  StatusBarManager.swift
//  ffan
//
//  Created by mohamad on 11/1/2026.
//  Animated status bar icon based on fan speed
//

import AppKit
import SwiftUI
import Combine

class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var animationTimer: Timer?
    private var currentRotation: CGFloat = 0
    private var currentFanSpeed: Int = 0
    
    func setupStatusBar() {
        DispatchQueue.main.async { [weak self] in
            self?.createStatusItem()
        }
    }
    
    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {

            return
        }
        
        // Set initial icon
        updateButtonIcon(button: button, rotation: 0)
        
        // Create popover
        popover = NSPopover()
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 340, height: 580)
        
        // Handle button click
        button.action = #selector(togglePopover)
        button.target = self

    }
    
    private func updateButtonIcon(button: NSStatusBarButton, rotation: CGFloat) {
        let size: CGFloat = 18
        
        // Create custom fan icon that renders as template (white in dark mode, black in light)
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSGraphicsContext.current?.cgContext.translateBy(x: size/2, y: size/2)
            NSGraphicsContext.current?.cgContext.rotate(by: rotation * .pi / 180)
            NSGraphicsContext.current?.cgContext.translateBy(x: -size/2, y: -size/2)
            
            let center = NSPoint(x: size/2, y: size/2)
            let bladeLength: CGFloat = size * 0.42  // Longer blades
            
            // Draw 3 fan blades with solid, visible shape
            for i in 0..<3 {
                let angle = CGFloat(i) * 120 * .pi / 180
                
                let bladePath = NSBezierPath()
                
                // Start from center hub edge
                let hubRadius: CGFloat = size * 0.15
                
                // End point of blade (tip)
                let endX = center.x + cos(angle) * bladeLength
                let endY = center.y + sin(angle) * bladeLength
                
                // Create a wider, more visible blade shape
                // Left edge of blade
                let leftAngle = angle - 0.35
                let leftStartX = center.x + cos(leftAngle) * hubRadius
                let leftStartY = center.y + sin(leftAngle) * hubRadius
                let leftEndX = center.x + cos(angle - 0.2) * bladeLength * 0.9
                let leftEndY = center.y + sin(angle - 0.2) * bladeLength * 0.9
                
                // Right edge of blade  
                let rightAngle = angle + 0.35
                let rightStartX = center.x + cos(rightAngle) * hubRadius
                let rightStartY = center.y + sin(rightAngle) * hubRadius
                let rightEndX = center.x + cos(angle + 0.15) * bladeLength * 0.95
                let rightEndY = center.y + sin(angle + 0.15) * bladeLength * 0.95
                
                // Draw blade as curved shape
                bladePath.move(to: NSPoint(x: leftStartX, y: leftStartY))
                bladePath.curve(to: NSPoint(x: leftEndX, y: leftEndY),
                               controlPoint1: NSPoint(x: center.x + cos(angle - 0.25) * bladeLength * 0.5,
                                                     y: center.y + sin(angle - 0.25) * bladeLength * 0.5),
                               controlPoint2: NSPoint(x: leftEndX, y: leftEndY))
                
                // Tip of blade (rounded)
                bladePath.curve(to: NSPoint(x: rightEndX, y: rightEndY),
                               controlPoint1: NSPoint(x: endX, y: endY),
                               controlPoint2: NSPoint(x: rightEndX, y: rightEndY))
                
                // Right edge back to center
                bladePath.curve(to: NSPoint(x: rightStartX, y: rightStartY),
                               controlPoint1: NSPoint(x: center.x + cos(angle + 0.2) * bladeLength * 0.5,
                                                     y: center.y + sin(angle + 0.2) * bladeLength * 0.5),
                               controlPoint2: NSPoint(x: rightStartX, y: rightStartY))
                
                bladePath.close()
                
                NSColor.black.setFill()
                bladePath.fill()
            }
            
            // Center hub (slightly larger)
            let hubSize = size * 0.3
            let hubPath = NSBezierPath(ovalIn: NSRect(x: center.x - hubSize/2,
                                                       y: center.y - hubSize/2,
                                                       width: hubSize,
                                                       height: hubSize))
            NSColor.black.setFill()
            hubPath.fill()
            
            return true
        }
        
        // CRITICAL: Set as template so macOS handles light/dark mode automatically
        image.isTemplate = true
        button.image = image
    }
    
    func setPopoverContent<Content: View>(_ content: Content) {
        DispatchQueue.main.async { [weak self] in
            self?.popover?.contentViewController = NSHostingController(rootView: content)
        }
    }
    
    func updateIcon(fanSpeed: Int, temperature: Double?) {
        DispatchQueue.main.async { [weak self] in
            self?.currentFanSpeed = fanSpeed
            self?.updateAnimationSpeed()
            self?.updateTooltip(temperature: temperature)
        }
    }
    
    private func updateAnimationSpeed() {
        // Stop existing animation
        animationTimer?.invalidate()
        animationTimer = nil
        
        guard currentFanSpeed > 0 else {
            // Fan is off, show static icon
            if let button = statusItem?.button {
                updateButtonIcon(button: button, rotation: currentRotation)
            }
            return
        }
        
        // Calculate animation interval based on fan speed
        // Higher speed = faster rotation (but still smooth and pleasant)
        // At 1000 RPM: very slow rotation
        // At 6500 RPM: moderate rotation (not too fast)
        let minInterval: Double = 0.05  // ~20fps (smoother, less CPU)
        let speedFactor = Double(currentFanSpeed) / 6500.0
        let rotationSpeed = 1.0 + speedFactor * 5.0  // Much slower: 1-6 degrees per frame
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: minInterval, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem?.button else { return }
            
            self.currentRotation += rotationSpeed
            if self.currentRotation >= 360 {
                self.currentRotation -= 360
            }
            
            self.updateButtonIcon(button: button, rotation: self.currentRotation)
        }
        
        RunLoop.current.add(animationTimer!, forMode: .common)
    }
    
    private func updateTooltip(temperature: Double?) {
        guard let button = statusItem?.button else { return }
        
        if let temp = temperature {
            button.toolTip = String(format: "%.0f°C - %d RPM", temp, currentFanSpeed)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover?.performClose(nil)
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}
