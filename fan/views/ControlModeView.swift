//
//  ControlModeView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed control mode toggle and added threshold slider
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
        VStack(spacing: 12) {
            HStack {
                Text("Control Mode")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            
            // Mode toggle
            Picker("Mode", selection: Binding(
                get: { viewModel.controlMode },
                set: { viewModel.setControlMode($0) }
            )) {
                Label("Manual", systemImage: "hand.raised")
                    .tag(ControlMode.manual)
                Label("Automatic", systemImage: "thermometer")
                    .tag(ControlMode.automatic)
            }
            .pickerStyle(.segmented)
            
            // Auto mode settings
            if viewModel.controlMode == .automatic {
                VStack(spacing: 12) {
                    // Temperature threshold
                    VStack(spacing: 4) {
                        HStack {
                            Text("Temperature Threshold")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f°C", localThreshold))
                                .font(.system(size: 11, weight: .medium))
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
                    VStack(spacing: 4) {
                        HStack {
                            Text("Max Speed")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(localMaxSpeed)) RPM")
                                .font(.system(size: 11, weight: .medium))
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
                .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Launch at login toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { newValue in
                        viewModel.launchAtLogin = newValue
                        LaunchAtLoginManager.shared.isEnabled = newValue
                    }
                )) {
                    Text("Launch at Login")
                        .font(.system(size: 12))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                
                Text(LaunchAtLoginManager.shared.registrationStatus)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Button("Open Login Items Settings") {
                    LaunchAtLoginManager.shared.openLoginItemsSettings()
                }
                .font(.system(size: 10))
                .buttonStyle(.link)
            }
        }
        .padding()
        .liquidGlass()
    }
}

#Preview {
    ControlModeView(viewModel: FanControlViewModel())
        .padding()
        .background(Color.black)
}
