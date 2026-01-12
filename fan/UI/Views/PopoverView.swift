//
//  PopoverView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Clean, organized UI with battery info
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @ObservedObject var permissions = PermissionsManager.shared
    @ObservedObject var battery = BatteryMonitor.shared
    @State private var showingQuitConfirm = false
    @State private var installError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 14) {
                    // Check helper installation first
                    if !permissions.isHelperInstalled {
                        installHelperView
                    } else if !viewModel.hasAccess {
                        noAccessView
                    } else if viewModel.cpuTemperature == nil {
                        noDataView
                    } else {
                        // Temperature displays
                        temperatureSection
                        
                        // Fan speed control
                        FanSpeedView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Auto mode settings (only show when in auto mode)
                        if viewModel.controlMode == .automatic {
                            autoModeSettings
                        }
                        
                        // Battery & System Info (always show if battery exists)
                        if battery.hasBattery {
                            batteryInfoSection
                        }
                        
                        // Additional temperatures
                        systemInfoSection
                    }
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Footer
            footerView
        }
        .frame(width: 340, height: 580)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                LinearGradient(
                    colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            if viewModel.hasAccess && !viewModel.isMonitoring {
                viewModel.startMonitoring()
            }
            battery.startMonitoring()
        }
        .onDisappear {
            battery.stopMonitoring()
        }
        .alert("Quit Fan Control?", isPresented: $showingQuitConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) {
                quitApp()
            }
        } message: {
            Text("Fans will be set to automatic mode before quitting.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 10) {
            // App icon with animation
            ZStack {
                Circle()
                    .fill(viewModel.getTemperatureColor().opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "fan.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.getTemperatureColor())
                    .rotationEffect(.degrees(viewModel.currentFanSpeed > 0 ? 360 : 0))
                    .animation(
                        viewModel.currentFanSpeed > 0 
                            ? .linear(duration: max(0.3, 3.0 - Double(viewModel.currentFanSpeed) / 2500)).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.currentFanSpeed > 0
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Fan Control")
                    .font(.system(size: 16, weight: .bold))
                
                Text(viewModel.getTemperatureStatus())
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.getTemperatureColor())
            }
            
            Spacer()
            
            // Quit button (top right)
            Button(action: {
                showingQuitConfirm = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Quit App")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Install View
    
    private var installHelperView: some View {
        VStack(spacing: 8) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("Helper Tool Required")
                .font(.system(size: 14, weight: .semibold))
            
            Text("To control fans without constant password prompts, a helper tool must be installed.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let error = installError {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                installError = nil
                permissions.installHelper { success, error in
                    if !success {
                        installError = error ?? "Installation failed"
                    }
                }
            }) {
                Text("Install Helper")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 8)
            .padding(.horizontal, 40)
            
            Text("Helper is installed to /usr/local/bin")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding()
        .liquidGlass()
        .padding(.horizontal)
    }

    // MARK: - Temperature Section
    
    private var temperatureSection: some View {
        HStack(spacing: 12) {
            TemperatureView(
                label: "CPU",
                temperature: viewModel.cpuTemperature,
                color: getTemperatureColor(viewModel.cpuTemperature)
            )
            
            // Power consumption card
            PowerCardView(
                powerWatts: battery.batteryInfo.powerWatts,
                isCharging: battery.batteryInfo.isCharging,
                isPluggedIn: battery.batteryInfo.isPluggedIn
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - No Access View
    
    private var noAccessView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("System Access Required")
                .font(.system(size: 14, weight: .semibold))
            
            Text("The app needs to access the System Management Controller (SMC) to read temperatures.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let error = viewModel.lastError {
                Text(error)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .liquidGlass()
        .padding(.horizontal)
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "thermometer.medium.slash")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("No Temperature Data")
                .font(.system(size: 14, weight: .semibold))
            
            Text("SMC connected but no temperature readings available. This may happen on some Mac models.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .liquidGlass()
        .padding(.horizontal)
    }
    
    // MARK: - Auto Mode Settings
    
    private var autoModeSettings: some View {
        VStack(spacing: 10) {
            // Temperature threshold
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Threshold")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f°C", viewModel.autoThreshold))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.autoThreshold },
                    set: { viewModel.setAutoThreshold($0) }
                ),
                in: 40...90,
                step: 5
            )
            .accentColor(.orange)
            
            // Max speed
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("Max Speed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(viewModel.autoMaxSpeed) RPM")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }
            
            Slider(
                value: Binding(
                    get: { Double(viewModel.autoMaxSpeed) },
                    set: { viewModel.setAutoMaxSpeed(Int($0)) }
                ),
                in: 1000...6500,
                step: 500
            )
            .accentColor(.blue)
            
            // Aggressiveness / Response curve
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "dial.medium")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                    Text("Response")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(aggressivenessLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.purple)
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.autoAggressiveness },
                    set: { viewModel.setAutoAggressiveness($0) }
                ),
                in: 0.0...3.0,
                step: 0.1
            )
            .accentColor(.purple)
        }
        .padding(12)
        .liquidGlass()
        .padding(.horizontal)
    }
    
    private var aggressivenessLabel: String {
        let val = viewModel.autoAggressiveness
        if val <= 0.3 {
            return "Min Override"
        } else if val <= 0.8 {
            return "Quiet"
        } else if val <= 1.2 {
            return "Balanced"
        } else if val <= 1.8 {
            return "Auto"
        } else if val <= 2.3 {
            return "Performance"
        } else if val <= 2.7 {
            return "Aggressive"
        } else {
            return "Max Override"
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack(spacing: 8) {
            // Mode picker (Manual/Auto) - Left side
            Picker("", selection: Binding(
                get: { viewModel.controlMode },
                set: { viewModel.setControlMode($0) }
            )) {
                Text("Manual").tag(ControlMode.manual)
                Text("Auto").tag(ControlMode.automatic)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
            
            Spacer()
            
            // Launch at login toggle - Right side
            Toggle(isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { newValue in
                    viewModel.launchAtLogin = newValue
                    LaunchAtLoginManager.shared.isEnabled = newValue
                }
            )) {
                Text("Startup?")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .help("Launch at Login")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Quit Function
    
    private func quitApp() {
        // Return control to system before quitting
        viewModel.resetToSystemControl()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Helpers
    
    private func getTemperatureColor(_ temp: Double?) -> Color {
        guard let temp = temp else { return .gray }
        if temp < 50 {
            return .blue
        } else if temp < 70 {
            return .yellow
        } else if temp < 85 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Battery Info Section
    
    private var batteryInfoSection: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Image(systemName: getBatteryIcon())
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Battery")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(battery.batteryInfo.percentage)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.8))
            }
            
            Divider().opacity(0.5)
            
            // Compact grid
            VStack(spacing: 4) {
                HStack(spacing: 16) {
                    CompactInfoItem(label: "Health", value: "\(battery.batteryInfo.health)%")
                    CompactInfoItem(label: "Cycles", value: "\(battery.batteryInfo.cycleCount)")
                    CompactInfoItem(label: "Status", value: battery.batteryInfo.condition)
                }
                
                HStack(spacing: 16) {
                    if let temp = battery.batteryInfo.temperature {
                        CompactInfoItem(label: "Temp", value: String(format: "%.1f°", temp))
                    }
                    if let voltage = battery.batteryInfo.voltage {
                        CompactInfoItem(label: "Voltage", value: String(format: "%.2fV", voltage))
                    }
                    if let power = battery.batteryInfo.powerWatts, power > 0.1 {
                        CompactInfoItem(label: "Power", value: String(format: "%.1fW", power))
                    }
                }
                
                if let maxCap = battery.batteryInfo.maxCapacity, let designCap = battery.batteryInfo.designCapacity {
                    HStack(spacing: 16) {
                        CompactInfoItem(label: "Capacity", value: "\(maxCap)/\(designCap)mAh")
                        CompactInfoItem(label: "Source", value: battery.batteryInfo.isPluggedIn ? "AC" : "Battery")
                        if let timeStr = battery.batteryInfo.formattedTimeRemaining {
                            CompactInfoItem(label: battery.batteryInfo.isCharging ? "Full in" : "Left", value: timeStr)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func getBatteryIcon() -> String {
        let pct = battery.batteryInfo.percentage
        let charging = battery.batteryInfo.isCharging
        
        if charging {
            return "battery.100.bolt"
        } else if pct > 75 {
            return "battery.100"
        } else if pct > 50 {
            return "battery.75"
        } else if pct > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
    
    // MARK: - System Info Section
    
    private var systemInfoSection: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("System")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Divider().opacity(0.5)
            
            VStack(spacing: 4) {
                HStack(spacing: 16) {
                    if let cpuTemp = viewModel.cpuTemperature {
                        CompactInfoItem(label: "CPU", value: String(format: "%.0f°", cpuTemp))
                    }
                    if let gpuTemp = viewModel.gpuTemperature {
                        CompactInfoItem(label: "GPU", value: String(format: "%.0f°", gpuTemp))
                    }
                    CompactInfoItem(label: "Fans", value: "\(viewModel.numberOfFans)")
                    CompactInfoItem(label: "RPM", value: "\(viewModel.currentFanSpeed)")
                }
                
                HStack(spacing: 16) {
                    if let minSpeed = viewModel.fanMinSpeeds.first, let maxSpeed = viewModel.fanMaxSpeeds.first {
                        CompactInfoItem(label: "Range", value: "\(minSpeed)-\(maxSpeed)")
                    }
                    CompactInfoItem(label: "Mode", value: viewModel.controlMode == .automatic ? "Auto" : "Manual")
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var batteryColor: Color {
        let pct = battery.batteryInfo.percentage
        if pct > 50 { return .green }
        if pct > 20 { return .yellow }
        return .red
    }
    
    private var batteryHealthColor: Color {
        let health = battery.batteryInfo.health
        if health >= 80 { return .green }
        if health >= 60 { return .yellow }
        return .red
    }
}

// MARK: - Info Row Helper View

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
                .frame(width: 12)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Compact Info Item (Cold, Minimal)

struct CompactInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.7))
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.primary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Power Card View

struct PowerCardView: View {
    let powerWatts: Double?
    let isCharging: Bool
    let isPluggedIn: Bool
    
    private var displayValue: String {
        if let power = powerWatts, power > 0.01 {
            return String(format: "%.1f", power)
        }
        return "--"
    }
    
    private var color: Color {
        if isCharging {
            return .green
        } else if let power = powerWatts {
            if power > 30 {
                return .red
            } else if power > 20 {
                return .orange
            } else if power > 10 {
                return .yellow
            }
        }
        return .blue
    }
    
    private var statusText: String {
        if isCharging {
            return "Charging"
        } else if isPluggedIn {
            return "Plugged In"
        } else {
            return "Battery"
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Header - matches TemperatureView
            HStack(spacing: 6) {
                Image(systemName: isCharging ? "bolt.fill" : "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                
                Text("Power")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(statusText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Power value - matches TemperatureView font sizes
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(displayValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("W")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color.opacity(0.6))
                
                Spacer()
            }
            
            // Progress bar (power level 0-50W range)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    if let power = powerWatts, power > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.6), color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(1, power / 50.0), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: power)
                    }
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .liquidGlass()
    }
}

#Preview {
    PopoverView(viewModel: FanControlViewModel())
        .background(Color.black)
}
