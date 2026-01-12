//
//  TemperatureView.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//

import SwiftUI

struct TemperatureView: View {
    let label: String
    let temperature: Double?
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let temp = temperature {
                    Text(String(format: "%.1f", temp))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    Text("°C")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("°C")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .liquidGlass()
    }
}

#Preview {
    HStack(spacing: 12) {
        TemperatureView(label: "CPU", temperature: 65.5, color: .yellow)
        TemperatureView(label: "GPU", temperature: 72.3, color: .orange)
    }
    .padding()
    .background(Color.black)
}
