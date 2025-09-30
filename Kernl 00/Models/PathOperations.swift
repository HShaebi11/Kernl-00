//
//  PathOperations.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import CoreGraphics

// MARK: - Boolean Operations

enum BooleanOperation {
    case union
    case subtract
    case intersect
    case exclude
}

class PathOperations {
    
    // MARK: - Boolean Operations
    
    static func performBoolean(_ op: BooleanOperation, on paths: [GlyphPath]) -> [GlyphPath] {
        guard paths.count >= 2 else { return paths }
        
        // Convert to CGPath for processing
        var cgPaths = paths.map { convertToCGPath($0) }
        
        // Perform operation (simplified - real implementation would use proper boolean ops)
        switch op {
        case .union:
            return unionPaths(paths)
        case .subtract:
            return subtractPaths(paths)
        case .intersect:
            return intersectPaths(paths)
        case .exclude:
            return excludePaths(paths)
        }
    }
    
    private static func unionPaths(_ paths: [GlyphPath]) -> [GlyphPath] {
        // Simplified: combine all paths
        let result = GlyphPath()
        for path in paths {
            result.points.append(contentsOf: path.points)
        }
        return [result]
    }
    
    private static func subtractPaths(_ paths: [GlyphPath]) -> [GlyphPath] {
        // Simplified: reverse second path and combine
        guard paths.count >= 2 else { return paths }
        let result = GlyphPath()
        result.points = paths[0].points
        
        for i in 1..<paths.count {
            var subtractPoints = paths[i].points.reversed()
            result.points.append(contentsOf: subtractPoints)
        }
        return [result]
    }
    
    private static func intersectPaths(_ paths: [GlyphPath]) -> [GlyphPath] {
        // Simplified placeholder
        return paths
    }
    
    private static func excludePaths(_ paths: [GlyphPath]) -> [GlyphPath] {
        // Simplified placeholder
        return paths
    }
    
    // MARK: - Transform Operations
    
    static func scale(path: GlyphPath, scaleX: Double, scaleY: Double, around center: CGPoint) {
        for point in path.points {
            // Translate to origin
            let dx = point.x - center.x
            let dy = point.y - center.y
            
            // Scale
            point.x = center.x + dx * scaleX
            point.y = center.y + dy * scaleY
            
            // Scale control handles
            point.controlInX *= scaleX
            point.controlInY *= scaleY
            point.controlOutX *= scaleX
            point.controlOutY *= scaleY
        }
    }
    
    static func rotate(path: GlyphPath, angle: Double, around center: CGPoint) {
        let radians = angle * .pi / 180.0
        let cos = Darwin.cos(radians)
        let sin = Darwin.sin(radians)
        
        for point in path.points {
            // Translate to origin
            let dx = point.x - center.x
            let dy = point.y - center.y
            
            // Rotate
            point.x = center.x + dx * cos - dy * sin
            point.y = center.y + dx * sin + dy * cos
            
            // Rotate control handles
            let inX = point.controlInX
            let inY = point.controlInY
            point.controlInX = inX * cos - inY * sin
            point.controlInY = inX * sin + inY * cos
            
            let outX = point.controlOutX
            let outY = point.controlOutY
            point.controlOutX = outX * cos - outY * sin
            point.controlOutY = outX * sin + outY * cos
        }
    }
    
    static func skew(path: GlyphPath, angleX: Double, angleY: Double, around center: CGPoint) {
        let tanX = tan(angleX * .pi / 180.0)
        let tanY = tan(angleY * .pi / 180.0)
        
        for point in path.points {
            let dx = point.x - center.x
            let dy = point.y - center.y
            
            point.x = center.x + dx + dy * tanX
            point.y = center.y + dy + dx * tanY
            
            // Skew control handles
            point.controlInX += point.controlInY * tanX
            point.controlInY += point.controlInX * tanY
            point.controlOutX += point.controlOutY * tanX
            point.controlOutY += point.controlOutX * tanY
        }
    }
    
    static func mirror(path: GlyphPath, horizontal: Bool, vertical: Bool, around center: CGPoint) {
        let scaleX = horizontal ? -1.0 : 1.0
        let scaleY = vertical ? -1.0 : 1.0
        scale(path: path, scaleX: scaleX, scaleY: scaleY, around: center)
    }
    
    // MARK: - Path Cleanup
    
    static func simplifyPath(_ path: GlyphPath, tolerance: Double = 5.0) {
        var simplified: [PathPoint] = []
        var i = 0
        
        while i < path.points.count {
            let current = path.points[i]
            simplified.append(current)
            
            // Skip points too close together
            var j = i + 1
            while j < path.points.count {
                let next = path.points[j]
                let distance = sqrt(pow(current.x - next.x, 2) + pow(current.y - next.y, 2))
                if distance > tolerance {
                    break
                }
                j += 1
            }
            i = j
        }
        
        path.points = simplified
    }
    
    static func removeOverlaps(_ paths: [GlyphPath]) -> [GlyphPath] {
        // Placeholder for overlap removal
        // Real implementation would use path intersection algorithms
        return paths
    }
    
    static func correctDirection(_ path: GlyphPath) {
        // Ensure counter-clockwise for outer paths, clockwise for inner
        let area = calculateArea(path)
        if area < 0 {
            path.points.reverse()
        }
    }
    
    private static func calculateArea(_ path: GlyphPath) -> Double {
        var area: Double = 0
        let points = path.points
        
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }
        
        return area / 2.0
    }
    
    // MARK: - Snapping
    
    static func snapToGrid(_ point: inout CGPoint, gridSize: Double) {
        point.x = round(point.x / gridSize) * gridSize
        point.y = round(point.y / gridSize) * gridSize
    }
    
    static func snapToGuides(_ point: inout CGPoint, guides: [Double], tolerance: Double = 10.0) {
        for guide in guides {
            if abs(point.y - guide) < tolerance {
                point.y = guide
                break
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private static func convertToCGPath(_ glyphPath: GlyphPath) -> CGPath {
        let path = CGMutablePath()
        guard !glyphPath.points.isEmpty else { return path }
        
        let firstPoint = glyphPath.points[0]
        path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        
        for i in 1..<glyphPath.points.count {
            let point = glyphPath.points[i]
            let prevPoint = glyphPath.points[i - 1]
            
            if point.type == .curve || prevPoint.type == .curve {
                let control1 = CGPoint(
                    x: prevPoint.x + prevPoint.controlOutX,
                    y: prevPoint.y + prevPoint.controlOutY
                )
                let control2 = CGPoint(
                    x: point.x + point.controlInX,
                    y: point.y + point.controlInY
                )
                path.addCurve(
                    to: CGPoint(x: point.x, y: point.y),
                    control1: control1,
                    control2: control2
                )
            } else {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
        }
        
        if glyphPath.isClosed {
            path.closeSubpath()
        }
        
        return path
    }
}
