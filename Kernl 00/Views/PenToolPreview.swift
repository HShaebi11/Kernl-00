//
//  PenToolPreview.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct PenToolPreview: View {
    let currentPoint: CGPoint
    let zoom: Double
    let panOffset: CGSize
    
    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 2)
            .fill(Color.blue.opacity(0.2))
            .frame(width: 20, height: 20)
            .position(x: currentPoint.x, y: currentPoint.y)
    }
}

#Preview {
    PenToolPreview(
        currentPoint: CGPoint(x: 200, y: 150),
        zoom: 1.0,
        panOffset: .zero
    )
    .frame(width: 400, height: 300)
}
