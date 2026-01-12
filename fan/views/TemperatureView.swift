//
//  TemperatureView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//  Enhanced temperature display with icons and gradients
//

import SwiftUI

struct TemperatureView: View {
    let label: String
    let temperature: Double?
    let color: Color
    
    private var icon: String {
        switch label.lowercased() {
        case "cpu": return "cpu"
        case "gpu": return "gpu"
        default: return "thermometer"
        }
    }
    
    private var tempLevel: String {
        guard let temp = temperature else { return "--" }
        if temp < 50 { return "Cool" }
        else if temp < 70 { return "Normal" }
        else if temp < 85 { return "Warm" }
        else { return "Hot!" }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Header with icon
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(tempLevel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Temperature display
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if let temp = temperature {
                    Text(String(format: "%.0f", temp))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("°")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color.opacity(0.6))
                } else {
                    Text("--")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("°")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                Spacer()
            }
            
            // Temperature bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    if let temp = temperature {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.6), color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(1, max(0, (temp - 30) / 70)), height: 4)
                            .animation(.easeInOut(duration: 0.3), value: temp)
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
    HStack(spacing: 12) {
        TemperatureView(label: "CPU", temperature: 65.5, color: .yellow)
        TemperatureView(label: "GPU", temperature: 82.3, color: .orange)
    }
    .padding()
    .background(Color.black)
}
