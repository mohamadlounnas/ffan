//
//  LiquidGlassModifier.swift
//  fan
//
//  Created by mohamad on 11/1/2026.
//

import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.3
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.6),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, opacity: Double = 0.3) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}
