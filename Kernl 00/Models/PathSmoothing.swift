//
//  PathSmoothing.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import CoreGraphics

class PathSmoothing {
    
    // MARK: - Chaikin's Algorithm
    
    static func chaikinSmooth(path: GlyphPath, iterations: Int = 2) -> GlyphPath {
        var points = path.points.map { CGPoint(x: $0.x, y: $0.y) }
        
        for _ in 0..<iterations {
            var smoothed: [CGPoint] = []
            
            for i in 0..<points.count - 1 {
                let p1 = points[i]
                let p2 = points[i + 1]
                
                // Quarter points along the line
                let q = CGPoint(
                    x: 0.75 * p1.x + 0.25 * p2.x,
                    y: 0.75 * p1.y + 0.25 * p2.y
                )
                let r = CGPoint(
                    x: 0.25 * p1.x + 0.75 * p2.x,
                    y: 0.25 * p1.y + 0.75 * p2.y
                )
                
                smoothed.append(q)
                smoothed.append(r)
            }
            
            if path.isClosed {
                // Connect last to first
                let p1 = points.last!
                let p2 = points.first!
                
                let q = CGPoint(
                    x: 0.75 * p1.x + 0.25 * p2.x,
                    y: 0.75 * p1.y + 0.25 * p2.y
                )
                let r = CGPoint(
                    x: 0.25 * p1.x + 0.75 * p2.x,
                    y: 0.25 * p1.y + 0.75 * p2.y
                )
                
                smoothed.append(q)
                smoothed.append(r)
            }
            
            points = smoothed
        }
        
        // Convert back to GlyphPath
        let smoothedPath = GlyphPath()
        for point in points {
            smoothedPath.points.append(PathPoint(x: point.x, y: point.y, type: .curve))
        }
        smoothedPath.isClosed = path.isClosed
        
        return smoothedPath
    }
    
    // MARK: - Catmull-Rom Spline
    
    static func catmullRomSmooth(path: GlyphPath, tension: Double = 0.5) -> GlyphPath {
        let points = path.points.map { CGPoint(x: $0.x, y: $0.y) }
        guard points.count >= 4 else { return path }
        
        let smoothedPath = GlyphPath()
        
        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i < points.count - 2 ? points[i + 2] : points[i + 1]
            
            // Calculate control points
            let d1x = (p2.x - p0.x) * tension
            let d1y = (p2.y - p0.y) * tension
            let d2x = (p3.x - p1.x) * tension
            let d2y = (p3.y - p1.y) * tension
            
            let point = PathPoint(x: p1.x, y: p1.y, type: .curve)
            point.controlOutX = d1x
            point.controlOutY = d1y
            point.controlInX = -d2x
            point.controlInY = -d2y
            point.handleConstraint = .broken
            
            smoothedPath.points.append(point)
        }
        
        // Add last point
        if let last = points.last {
            smoothedPath.points.append(PathPoint(x: last.x, y: last.y, type: .curve))
        }
        
        smoothedPath.isClosed = path.isClosed
        return smoothedPath
    }
    
    // MARK: - Gaussian Smoothing
    
    static func gaussianSmooth(path: GlyphPath, radius: Int = 2, sigma: Double = 1.0) -> GlyphPath {
        let points = path.points.map { CGPoint(x: $0.x, y: $0.y) }
        guard points.count > radius * 2 else { return path }
        
        // Generate Gaussian kernel
        var kernel: [Double] = []
        for i in -radius...radius {
            let value = exp(-Double(i * i) / (2.0 * sigma * sigma))
            kernel.append(value)
        }
        let sum = kernel.reduce(0, +)
        kernel = kernel.map { $0 / sum }
        
        // Apply convolution
        var smoothed: [CGPoint] = []
        
        for i in 0..<points.count {
            var x: Double = 0
            var y: Double = 0
            
            for j in -radius...radius {
                var index = i + j
                
                // Handle boundaries
                if path.isClosed {
                    index = (index + points.count) % points.count
                } else {
                    index = max(0, min(points.count - 1, index))
                }
                
                x += points[index].x * kernel[j + radius]
                y += points[index].y * kernel[j + radius]
            }
            
            smoothed.append(CGPoint(x: x, y: y))
        }
        
        // Convert back to GlyphPath
        let smoothedPath = GlyphPath()
        for point in smoothed {
            smoothedPath.points.append(PathPoint(x: point.x, y: point.y, type: .curve))
        }
        smoothedPath.isClosed = path.isClosed
        
        return smoothedPath
    }
    
    // MARK: - Auto-Smooth (Hobby's Algorithm simplified)
    
    static func autoSmooth(path: GlyphPath) -> GlyphPath {
        let points = path.points
        guard points.count >= 3 else { return path }
        
        for i in 0..<points.count {
            let current = points[i]
            
            // Skip if already a control point
            if current.type == .control { continue }
            
            let prevIndex = (i - 1 + points.count) % points.count
            let nextIndex = (i + 1) % points.count
            
            let prev = points[prevIndex]
            let next = points[nextIndex]
            
            // Calculate tension based on angle
            let angle1 = atan2(current.y - prev.y, current.x - prev.x)
            let angle2 = atan2(next.y - current.y, next.x - current.x)
            var angleDiff = abs(angle2 - angle1)
            
            if angleDiff > .pi {
                angleDiff = 2 * .pi - angleDiff
            }
            
            // Smooth curves have symmetric handles
            let distance1 = sqrt(pow(current.x - prev.x, 2) + pow(current.y - prev.y, 2))
            let distance2 = sqrt(pow(next.x - current.x, 2) + pow(next.y - current.y, 2))
            
            let tension = min(distance1, distance2) / 3.0
            
            // Calculate handle directions
            let inAngle = angle1
            let outAngle = angle2
            
            current.type = .curve
            current.handleConstraint = .symmetric
            current.controlInX = -cos(inAngle) * tension
            current.controlInY = -sin(inAngle) * tension
            current.controlOutX = cos(outAngle) * tension
            current.controlOutY = sin(outAngle) * tension
        }
        
        return path
    }
    
    // MARK: - Corner Detection
    
    static func detectCorners(path: GlyphPath, angleThreshold: Double = 30.0) -> [Int] {
        var corners: [Int] = []
        let points = path.points
        
        guard points.count >= 3 else { return corners }
        
        for i in 1..<points.count - 1 {
            let prev = points[i - 1]
            let current = points[i]
            let next = points[i + 1]
            
            let angle1 = atan2(current.y - prev.y, current.x - prev.x)
            let angle2 = atan2(next.y - current.y, next.x - current.x)
            
            var angleDiff = abs((angle2 - angle1) * 180 / .pi)
            if angleDiff > 180 {
                angleDiff = 360 - angleDiff
            }
            
            if angleDiff > angleThreshold {
                corners.append(i)
            }
        }
        
        return corners
    }
}
