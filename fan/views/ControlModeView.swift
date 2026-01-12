//
//  ControlModeView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Enhanced control mode with better UI
//

import SwiftUI

struct ControlModeView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @State private var localThreshold: Double = 60.0
    @State private var localMaxSpeed: Double = 4000
    
    // Safe slider bounds
    private let minSpeed: Double = 1000
    private let maxSpeed: Double = 6500
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("Control Mode")
                        .font(.system(size: 14, weight: .semibold))
                }
                Spacer()
            }
            
            // Mode toggle - Custom style
            HStack(spacing: 0) {
                ModeButton(
                    title: "Manual",
                    icon: "hand.raised.fill",
                    isSelected: viewModel.controlMode == .manual,
                    color: .blue
                ) {
                    viewModel.setControlMode(.manual)
                }
                
                ModeButton(
                    title: "Auto",
                    icon: "waveform.path.ecg",
                    isSelected: viewModel.controlMode == .automatic,
                    color: .green
                ) {
                    viewModel.setControlMode(.automatic)
                }
            }
            .padding(3)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // Auto mode settings
            if viewModel.controlMode == .automatic {
                VStack(spacing: 14) {
                    // Temperature threshold
                    VStack(spacing: 6) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("Temp Threshold")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f°C", localThreshold))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        
                        Slider(
                            value: $localThreshold,
                            in: 40...90,
                            step: 5,
                            onEditingChanged: { editing in
                                if !editing {
                                    viewModel.setAutoThreshold(localThreshold)
                                }
                            }
                        )
                        .accentColor(.orange)
                        .onAppear {
                            localThreshold = viewModel.autoThreshold
                        }
                    }
                    
                    // Max speed
                    VStack(spacing: 6) {
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
                            Text("\(Int(localMaxSpeed)) RPM")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        
                        Slider(
                            value: $localMaxSpeed,
                            in: minSpeed...maxSpeed,
                            step: 500,
                            onEditingChanged: { editing in
                                if !editing {
                                    viewModel.setAutoMaxSpeed(Int(localMaxSpeed))
                                }
                            }
                        )
                        .accentColor(.blue)
                        .onAppear {
                            localMaxSpeed = Double(max(Int(minSpeed), min(Int(maxSpeed), viewModel.autoMaxSpeed)))
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Launch at login toggle
            HStack {
                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { newValue in
                        viewModel.launchAtLogin = newValue
                        LaunchAtLoginManager.shared.isEnabled = newValue
                    }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Launch at Login")
                            .font(.system(size: 12))
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
        }
        .padding(14)
        .liquidGlass()
    }
}

// MARK: - Mode Button

struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ControlModeView(viewModel: FanControlViewModel())
        .padding()
        .background(Color.black)
}
