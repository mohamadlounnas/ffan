//
//  PopoverView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed layout and improved status display
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: FanControlViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Status indicator (if no access)
            if !viewModel.hasAccess {
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
                    Text(viewModel.statusMessage)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            
            Spacer(minLength: 8)
            
            // Footer
            footerView
        }
        .frame(width: 320, height: 480)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
        .onAppear {
            if viewModel.hasAccess && !viewModel.isMonitoring {
                viewModel.startMonitoring()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "fanblades")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(viewModel.getTemperatureColor())
                .symbolEffect(.rotate, isActive: viewModel.currentFanSpeed > 0)
            
            Text("Fan Control")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            // Demo mode indicator
            if viewModel.isDemoMode {
                Text("DEMO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
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
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button(action: {
                viewModel.toggleDemoMode()
            }) {
                Image(systemName: viewModel.isDemoMode ? "play.slash" : "play")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(viewModel.isDemoMode ? "Disable Demo Mode" : "Enable Demo Mode")
            
            Spacer()
            
            Text(viewModel.getTemperatureStatus())
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Quit App")
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
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

#Preview {
    PopoverView(viewModel: FanControlViewModel())
        .background(Color.black)
}
