//
//  GuideLinesView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct GuideLinesView: View {
    @ObservedObject var glyph: Glyph
    let zoom: Double
    let panOffset: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Baseline
            let baselineY = size.height / 2
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: baselineY))
                    path.addLine(to: CGPoint(x: size.width, y: baselineY))
                },
                with: .color(.blue.opacity(0.5)),
                lineWidth: 1
            )
            
            // Ascender line
            let ascenderY = baselineY - 200 * zoom
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: ascenderY))
                    path.addLine(to: CGPoint(x: size.width, y: ascenderY))
                },
                with: .color(.green.opacity(0.3)),
                lineWidth: 1
            )
            
            // Descender line
            let descenderY = baselineY + 200 * zoom
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: descenderY))
                    path.addLine(to: CGPoint(x: size.width, y: descenderY))
                },
                with: .color(.red.opacity(0.3)),
                lineWidth: 1
            )
            
            // Glyph bounds
            let glyphX = size.width / 2 - glyph.width * zoom / 2
            let glyphY = baselineY - 400 * zoom
            let glyphWidth = glyph.width * zoom
            let glyphHeight = 800 * zoom
            
            context.stroke(
                Path { path in
                    path.addRect(CGRect(
                        x: glyphX,
                        y: glyphY,
                        width: glyphWidth,
                        height: glyphHeight
                    ))
                },
                with: .color(.red.opacity(0.5)),
                lineWidth: 1
            )
        }
    }
}

#Preview {
    GuideLinesView(glyph: Glyph(character: "A"), zoom: 1.0, panOffset: .zero)
        .frame(width: 400, height: 300)
}
