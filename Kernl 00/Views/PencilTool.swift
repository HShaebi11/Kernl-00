//
//  PencilTool.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct PencilTool: View {
    @ObservedObject var glyph: Glyph
    @State private var drawnPoints: [CGPoint] = []
    @State private var isDrawing = false
    @State private var smoothness: Double = 0.5
    @State private var simplifyTolerance: Double = 5.0
    @State private var autoSmooth: Bool = true
    
    var body: some View {
        VStack {
            // Drawing canvas
            ZStack {
                Canvas { context, size in
                    var path = Path()
                    if drawnPoints.count > 1 {
                        path.move(to: drawnPoints[0])
                        for point in drawnPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(path, with: .color(.black), lineWidth: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDrawing {
                                isDrawing = true
                                drawnPoints = []
                            }
                            drawnPoints.append(value.location)
                        }
                        .onEnded { _ in
                            isDrawing = false
                        }
                )
            }
            
            // Controls
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smoothness")
                        .font(.caption)
                    Slider(value: $smoothness, in: 0...1)
                        .frame(width: 150)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Simplify")
                        .font(.caption)
                    Slider(value: $simplifyTolerance, in: 1...20)
                        .frame(width: 150)
                }
                
                Toggle("Auto Smooth", isOn: $autoSmooth)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button("Convert to Outline") {
                    convertDrawingToPath()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear") {
                    drawnPoints = []
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    private func convertDrawingToPath() {
        guard !drawnPoints.isEmpty else { return }
        
        let glyphPath = convertPointsToGlyphPath(drawnPoints)
        glyph.paths.append(glyphPath)
        
        // Clear canvas after conversion
        drawnPoints = []
    }
    
    private func convertPointsToGlyphPath(_ points: [CGPoint]) -> GlyphPath {
        let glyphPath = GlyphPath()
        
        // Sample points from the stroke
        let sampledPoints = points
        
        // Simplify the path
        let simplified = simplifyPath(sampledPoints, tolerance: simplifyTolerance)
        
        // Convert to PathPoints with smoothing
        for (index, point) in simplified.enumerated() {
            let pathPoint = PathPoint(
                x: point.x,
                y: point.y,
                type: autoSmooth ? .curve : .corner
            )
            
            // Add automatic smooth handles for curves
            if autoSmooth && index > 0 && index < simplified.count - 1 {
                let prev = simplified[index - 1]
                let next = simplified[index + 1]
                
                // Calculate tangent
                let dx = (next.x - prev.x) * smoothness
                let dy = (next.y - prev.y) * smoothness
                
                pathPoint.controlInX = -dx / 3
                pathPoint.controlInY = -dy / 3
                pathPoint.controlOutX = dx / 3
                pathPoint.controlOutY = dy / 3
                pathPoint.handleConstraint = .symmetric
            }
            
            glyphPath.points.append(pathPoint)
        }
        
        glyphPath.isClosed = false
        return glyphPath
    }
    
    // Ramer-Douglas-Peucker algorithm for path simplification
    private func simplifyPath(_ points: [CGPoint], tolerance: Double) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        // Find the point with maximum distance from line segment
        var maxDistance: Double = 0
        var maxIndex = 0
        let start = points.first!
        let end = points.last!
        
        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(points[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // If max distance is greater than tolerance, recursively simplify
        if maxDistance > tolerance {
            let left = simplifyPath(Array(points[0...maxIndex]), tolerance: tolerance)
            let right = simplifyPath(Array(points[maxIndex..<points.count]), tolerance: tolerance)
            
            // Combine results (remove duplicate middle point)
            return left.dropLast() + right
        } else {
            // Return just the endpoints
            return [start, end]
        }
    }
    
    private func perpendicularDistance(_ point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Double {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        if dx == 0 && dy == 0 {
            return sqrt(pow(point.x - lineStart.x, 2) + pow(point.y - lineStart.y, 2))
        }
        
        let num = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        let den = sqrt(dx * dx + dy * dy)
        
        return num / den
    }
}

#Preview {
    PencilTool(glyph: Glyph(character: "A"))
        .frame(width: 600, height: 500)
}
