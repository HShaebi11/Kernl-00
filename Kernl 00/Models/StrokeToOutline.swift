//
//  StrokeToOutline.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import CoreGraphics

class StrokeToOutline {
    
    // Convert a stroked path to an outlined path
    static func convert(path: GlyphPath, strokeWidth: Double, cap: StrokeCap = .round, join: StrokeJoin = .round) -> GlyphPath {
        let outline = GlyphPath()
        
        // Calculate perpendicular offset for each segment
        var leftSide: [CGPoint] = []
        var rightSide: [CGPoint] = []
        
        for i in 0..<path.points.count {
            let current = path.points[i]
            let next = path.points[(i + 1) % path.points.count]
            
            // Calculate direction vector
            let dx = next.x - current.x
            let dy = next.y - current.y
            let length = sqrt(dx * dx + dy * dy)
            
            if length > 0 {
                // Normalized perpendicular vector
                let perpX = -dy / length * strokeWidth / 2
                let perpY = dx / length * strokeWidth / 2
                
                // Points on both sides of the stroke
                leftSide.append(CGPoint(x: current.x + perpX, y: current.y + perpY))
                rightSide.append(CGPoint(x: current.x - perpX, y: current.y - perpY))
            }
        }
        
        // Create outline path (left side + reversed right side)
        for point in leftSide {
            outline.points.append(PathPoint(x: point.x, y: point.y, type: .corner))
        }
        
        for point in rightSide.reversed() {
            outline.points.append(PathPoint(x: point.x, y: point.y, type: .corner))
        }
        
        outline.isClosed = true
        
        // Apply cap and join styles (simplified)
        if cap == .round {
            smoothCorners(outline: outline)
        }
        
        return outline
    }
    
    // Smooth corners for round caps/joins
    private static func smoothCorners(outline: GlyphPath) {
        for point in outline.points {
            point.type = .curve
            // Add automatic smooth handles
            point.handleConstraint = .symmetric
            point.controlInX = -10
            point.controlInY = 0
            point.controlOutX = 10
            point.controlOutY = 0
        }
    }
    
    // Expand a path outward (for bold/stroke effects)
    static func expand(path: GlyphPath, amount: Double) -> GlyphPath {
        return convert(path: path, strokeWidth: amount * 2)
    }
    
    // Contract a path inward
    static func contract(path: GlyphPath, amount: Double) -> GlyphPath {
        let expanded = convert(path: path, strokeWidth: -amount * 2)
        return expanded
    }
}

enum StrokeCap {
    case butt
    case round
    case square
}

enum StrokeJoin {
    case miter
    case round
    case bevel
}
