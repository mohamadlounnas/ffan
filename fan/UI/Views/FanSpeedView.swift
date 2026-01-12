//
//  FanSpeedView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Enhanced UI with debounced slider
//

import SwiftUI
import Combine

struct FanSpeedView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @State private var localSpeed: Double = 2000
    @State private var isApplying: Bool = false
    @State private var debounceTask: Task<Void, Never>?
    
    // Use computed properties for safe bounds
    private var sliderMin: Double { 1000 }
    private var sliderMax: Double { 6500 }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fan.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Fan Speed")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                if viewModel.numberOfFans > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                        Text("\(viewModel.numberOfFans) fan\(viewModel.numberOfFans > 1 ? "s" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Current speed display
            HStack(alignment: .center, spacing: 16) {
                // RPM Display
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.currentFanSpeed)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("RPM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Speed gauge
                SpeedGauge(percentage: safePercentage)
                    .frame(width: 56, height: 56)
            }
            
            // Speed slider (manual mode only)
            if viewModel.controlMode == .manual {
                VStack(spacing: 10) {
                    // Slider with debounce
                    Slider(
                        value: $localSpeed,
                        in: sliderMin...sliderMax,
                        step: 100
                    )
                    .accentColor(.blue)
                    .onAppear {
                        localSpeed = Double(max(Int(sliderMin), min(Int(sliderMax), viewModel.manualSpeed)))
                    }
                    .onChange(of: localSpeed) { _, newValue in
                        // Cancel previous debounce task
                        debounceTask?.cancel()
                        
                        // Start new debounce (1 second delay)
                        debounceTask = Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            
                            if !Task.isCancelled && Int(newValue) != viewModel.manualSpeed {
                                await MainActor.run {
                                    isApplying = true
                                    viewModel.setManualSpeed(Int(newValue))
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.manualSpeed) { _, newValue in
                        localSpeed = Double(max(Int(sliderMin), min(Int(sliderMax), newValue)))
                        isApplying = false
                    }
                    
                    // Labels
                    HStack {
                        Text("\(Int(sliderMin))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            if isApplying {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 10, height: 10)
                            }
                            Text("Target: \(Int(localSpeed)) RPM")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Int(localSpeed) != viewModel.manualSpeed ? .orange : .secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(sliderMax))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Auto mode indicator
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Control")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Speed adjusts with temperature")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green.opacity(0.6))
                        .font(.system(size: 16))
                }
                .padding(10)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(14)
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
                .stroke(Color.gray.opacity(0.15), lineWidth: 5)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: safePercentage)
                .stroke(
                    AngularGradient(
                        colors: [gaugeColor.opacity(0.5), gaugeColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: safePercentage)
            
            // Center content
            VStack(spacing: 0) {
                Text("\(Int(safePercentage * 100))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(gaugeColor)
                Text("%")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
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
