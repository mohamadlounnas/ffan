//
//  FanControlTests.swift
//  ffanTests
//
//  Created by mohamad on 11/1/2026.
//

import XCTest
@testable import ffan

final class FanControlTests: XCTestCase {
    
    func testControlModeEnum() {
        XCTAssertEqual(ControlMode.manual, ControlMode.manual)
        XCTAssertEqual(ControlMode.automatic, ControlMode.automatic)
        XCTAssertNotEqual(ControlMode.manual, ControlMode.automatic)
    }
    
    func testFanControllerInitialization() {
        let monitor = SystemMonitor()
        let controller = FanController(systemMonitor: monitor)
        
        XCTAssertEqual(controller.mode, .manual)
        XCTAssertGreaterThanOrEqual(controller.manualSpeed, 1000)
        XCTAssertLessThanOrEqual(controller.manualSpeed, 6000)
    }
    
    func testFanControllerManualSpeed() {
        let monitor = SystemMonitor()
        let controller = FanController(systemMonitor: monitor)
        
        controller.setManualSpeed(3000)
        XCTAssertEqual(controller.manualSpeed, 3000)
        
        // Test clamping
        controller.setManualSpeed(10000)
        XCTAssertLessThanOrEqual(controller.manualSpeed, 6000)
        
        controller.setManualSpeed(500)
        XCTAssertGreaterThanOrEqual(controller.manualSpeed, 1000)
    }
    
    func testFanControllerModeSwitch() {
        let monitor = SystemMonitor()
        let controller = FanController(systemMonitor: monitor)
        
        XCTAssertEqual(controller.mode, .manual)
        
        controller.setMode(.automatic)
        XCTAssertEqual(controller.mode, .automatic)
        
        controller.setMode(.manual)
        XCTAssertEqual(controller.mode, .manual)
    }
    
    func testUserDefaultsManager() {
        let manager = UserDefaultsManager.shared
        
        // Test control mode
        manager.controlMode = .automatic
        XCTAssertEqual(manager.controlMode, .automatic)
        
        manager.controlMode = .manual
        XCTAssertEqual(manager.controlMode, .manual)
        
        // Test manual speed
        manager.manualFanSpeed = 2500
        XCTAssertEqual(manager.manualFanSpeed, 2500)
        
        // Test auto threshold
        manager.autoThreshold = 65.0
        XCTAssertEqual(manager.autoThreshold, 65.0)
        
        // Test auto max speed
        manager.autoMaxSpeed = 5000
        XCTAssertEqual(manager.autoMaxSpeed, 5000)
    }
    
    func testFanControlViewModelInitialization() {
        let viewModel = FanControlViewModel()
        
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.controlMode, .manual)
        XCTAssertEqual(viewModel.fanSpeeds.count, 0)
    }
    
    func testTemperatureColorCalculation() {
        let viewModel = FanControlViewModel()
        
        // Test with no temperature
        viewModel.cpuTemperature = nil
        viewModel.gpuTemperature = nil
        let color1 = viewModel.getTemperatureColor()
        XCTAssertEqual(color1, .blue) // Default to blue when no temp
        
        // Test cool temperature
        viewModel.cpuTemperature = 45.0
        let color2 = viewModel.getTemperatureColor()
        XCTAssertEqual(color2, .blue)
        
        // Test warm temperature
        viewModel.cpuTemperature = 65.0
        let color3 = viewModel.getTemperatureColor()
        XCTAssertEqual(color3, .yellow)
        
        // Test hot temperature
        viewModel.cpuTemperature = 75.0
        let color4 = viewModel.getTemperatureColor()
        XCTAssertEqual(color4, .red)
    }
    
    func testMaxTemperatureCalculation() {
        let viewModel = FanControlViewModel()
        
        viewModel.cpuTemperature = 50.0
        viewModel.gpuTemperature = 60.0
        XCTAssertEqual(viewModel.getMaxTemperature(), 60.0)
        
        viewModel.cpuTemperature = 70.0
        viewModel.gpuTemperature = 65.0
        XCTAssertEqual(viewModel.getMaxTemperature(), 70.0)
    }
}
