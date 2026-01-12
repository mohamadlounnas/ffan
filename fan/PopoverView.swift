//
//  PopoverView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Improved UI with better layout and quit functionality
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @ObservedObject var permissions = PermissionsManager.shared
    @State private var showingQuitConfirm = false
    @State private var isQuitting = false
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
                    } else if viewModel.cpuTemperature == nil && viewModel.gpuTemperature == nil && !viewModel.isDemoMode {
                        noDataView
                    } else {
                        // Temperature displays
                        temperatureSection
                        
                        // Fan speed control
                        FanSpeedView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Control mode
                        ControlModeView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Status message
                        if !viewModel.statusMessage.isEmpty {
                            statusBanner
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Footer
            footerView
        }
        .frame(width: 340, height: 520)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
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
            
            // Mode badge
            HStack(spacing: 4) {
                if viewModel.isDemoMode {
                    BadgeView(text: "DEMO", color: .orange)
                }
                
                BadgeView(
                    text: viewModel.controlMode == .automatic ? "AUTO" : "MANUAL",
                    color: viewModel.controlMode == .automatic ? .green : .blue
                )
            }
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
            
            TemperatureView(
                label: "GPU",
                temperature: viewModel.gpuTemperature,
                color: getTemperatureColor(viewModel.gpuTemperature)
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
            
            Button("Enable Demo Mode") {
                viewModel.toggleDemoMode()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 8)
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
            
            Button("Enable Demo Mode") {
                viewModel.toggleDemoMode()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 8)
        }
        .padding()
        .liquidGlass()
        .padding(.horizontal)
    }
    
    // MARK: - Status Banner
    
    private var statusBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.lastWriteSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(viewModel.lastWriteSuccess ? .green : .blue)
                .font(.system(size: 12))
            
            Text(viewModel.statusMessage)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack(spacing: 12) {
            // Demo mode toggle
            Button(action: {
                viewModel.toggleDemoMode()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isDemoMode ? "stop.circle" : "play.circle")
                    Text(viewModel.isDemoMode ? "Stop Demo" : "Demo")
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(viewModel.isDemoMode ? "Disable Demo Mode" : "Enable Demo Mode")
            
            Spacer()
            
            // Version or info
            Text("v1.0")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
            
            Spacer()
            
            // Quit button
            Button(action: {
                showingQuitConfirm = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Quit App (switches to auto mode)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Quit Function
    
    private func quitApp() {
        isQuitting = true
        
        // Switch to automatic mode before quitting
        viewModel.setControlMode(.automatic)
        
        // Give it a moment to apply
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
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.85))
            .cornerRadius(4)
    }
}

#Preview {
    PopoverView(viewModel: FanControlViewModel())
        .background(Color.black)
}
