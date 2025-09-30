//
//  AdvancedGridView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct AdvancedGridView: View {
    let gridSize: CGFloat
    let zoom: Double
    let panOffset: CGSize
    
    var body: some View {
        Canvas { context, size in
            let adjustedGridSize = gridSize * zoom
            let offsetX = panOffset.width.truncatingRemainder(dividingBy: adjustedGridSize)
            let offsetY = panOffset.height.truncatingRemainder(dividingBy: adjustedGridSize)
            
            // Draw grid lines
            context.stroke(
                Path { path in
                    // Vertical lines
                    for x in stride(from: offsetX, through: size.width, by: adjustedGridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: offsetY, through: size.height, by: adjustedGridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                },
                with: .color(.gray.opacity(0.3)),
                lineWidth: 0.5
            )
        }
    }
}

#Preview {
    AdvancedGridView(gridSize: 20, zoom: 1.0, panOffset: .zero)
        .frame(width: 400, height: 300)
}
