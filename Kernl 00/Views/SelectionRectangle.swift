//
//  SelectionRectangle.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct SelectionRectangle: View {
    let start: CGPoint
    let current: CGPoint
    let zoom: Double
    let panOffset: CGSize
    
    var body: some View {
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        
        Rectangle()
            .stroke(Color.blue, lineWidth: 1)
            .fill(Color.blue.opacity(0.1))
            .frame(width: rect.width, height: rect.height)
            .position(
                x: rect.midX,
                y: rect.midY
            )
    }
}

#Preview {
    SelectionRectangle(
        start: CGPoint(x: 100, y: 100),
        current: CGPoint(x: 200, y: 200),
        zoom: 1.0,
        panOffset: .zero
    )
    .frame(width: 400, height: 300)
}
