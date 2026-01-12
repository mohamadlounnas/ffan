//
//  FanSpeedView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Fixed slider binding and added fan count display
//

import SwiftUI

struct FanSpeedView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @State private var localSpeed: Double = 2000
    
    // Use computed properties for safe bounds
    private var sliderMin: Double { 1000 }
    private var sliderMax: Double { 6500 }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Fan Speed")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                
                if viewModel.numberOfFans > 0 {
                    Text("\(viewModel.numberOfFans) fan\(viewModel.numberOfFans > 1 ? "s" : "")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // Current speed display
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.currentFanSpeed)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("RPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Speed percentage gauge
                SpeedGauge(percentage: safePercentage)
                    .frame(width: 44, height: 44)
            }
            
            // Speed slider (manual mode only)
            if viewModel.controlMode == .manual {
                VStack(spacing: 8) {
                    Slider(
                        value: $localSpeed,
                        in: sliderMin...sliderMax,
                        step: 100,
                        onEditingChanged: { editing in
                            if !editing {
                                viewModel.setManualSpeed(Int(localSpeed))
                            }
                        }
                    )
                    .accentColor(.blue)
                    .onAppear {
                        localSpeed = Double(max(Int(sliderMin), min(Int(sliderMax), viewModel.manualSpeed)))
                    }
                    .onChange(of: viewModel.manualSpeed) { _, newValue in
                        localSpeed = Double(max(Int(sliderMin), min(Int(sliderMax), newValue)))
                    }
                    
                    HStack {
                        Text("\(Int(sliderMin))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Target: \(Int(localSpeed)) RPM")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(sliderMax))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Auto mode indicator
                HStack(spacing: 8) {
                    Image(systemName: "thermometer")
                        .foregroundColor(viewModel.getTemperatureColor())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Control Active")
                            .font(.system(size: 12, weight: .medium))
                        Text("Speed adjusts based on temperature")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .liquidGlass(cornerRadius: 8)
            }
        }
        .padding()
        .liquidGlass()
    }
    
    // Safe percentage calculation
    private var safePercentage: Double {
        let percent = viewModel.getFanSpeedPercent()
        if percent.isNaN || percent.isInfinite {
            return 0
        }
        return max(0, min(1, percent))
    }
}

// MARK: - Speed Gauge

struct SpeedGauge: View {
    let percentage: Double
    
    private var safePercentage: Double {
        if percentage.isNaN || percentage.isInfinite {
            return 0
        }
        return max(0, min(1, percentage))
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: safePercentage)
                .stroke(
                    gaugeColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: safePercentage)
            
            // Percentage text
            Text("\(Int(safePercentage * 100))%")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
    
    private var gaugeColor: Color {
        if safePercentage < 0.3 {
            return .blue
        } else if safePercentage < 0.6 {
            return .green
        } else if safePercentage < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    FanSpeedView(viewModel: FanControlViewModel())
        .padding()
        .background(Color.black)
}
