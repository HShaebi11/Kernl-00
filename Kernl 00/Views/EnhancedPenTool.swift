//
//  EnhancedPenTool.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct EnhancedPenTool: View {
    @ObservedObject var glyph: Glyph
    @State private var currentPath: GlyphPath?
    @State private var isDrawing = false
    @State private var lastPoint: CGPoint?
    @State private var previewPoint: CGPoint?
    @State private var controlHandle: CGPoint?
    @State private var isCreatingCurve = false
    @State private var curveStartPoint: CGPoint?
    @State private var curveControlPoint: CGPoint?
    
    var body: some View {
        ZStack {
            // Existing paths
            ForEach(glyph.paths) { path in
                GlyphPathView(path: path)
            }
            
            // Current path being drawn
            if let currentPath = currentPath {
                GlyphPathView(path: currentPath)
            }
            
            // Preview line for next point
            if let lastPoint = lastPoint, let previewPoint = previewPoint {
                Path { path in
                    path.move(to: lastPoint)
                    path.addLine(to: previewPoint)
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .foregroundStyle(Color.gray.opacity(0.5))
            }
            
            // Curve preview
            if isCreatingCurve, let startPoint = curveStartPoint, let controlPoint = curveControlPoint, let endPoint = previewPoint {
                Path { path in
                    path.move(to: startPoint)
                    path.addCurve(to: endPoint, control1: controlPoint, control2: controlPoint)
                }
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                .foregroundStyle(Color.blue.opacity(0.7))
            }
            
            // Control handle preview
            if let controlHandle = controlHandle, let lastPoint = lastPoint {
                Path { path in
                    path.move(to: lastPoint)
                    path.addLine(to: controlHandle)
                }
                .stroke(Color.orange, lineWidth: 1)
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .position(controlHandle)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(value)
                }
                .onEnded { value in
                    handleDragEnd(value)
                }
        )
    }
    
    // MARK: - Event Handlers
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let movement = hypot(value.translation.width, value.translation.height)
        if isCreatingCurve {
            // Complete the curve
            completeCurve(at: value.location)
        } else if movement <= 10 {
            // Treat as a tap: add a corner point or complete the curve
            handleTap(at: value.location)
        } else {
            // Start creating a curve from a drag
            startCurve(at: value.location)
        }
    }
    
    private func handleTap(at location: CGPoint) {
        if isCreatingCurve {
            // Complete the curve
            completeCurve(at: location)
        } else {
            // Add a corner point
            addCornerPoint(at: location)
        }
    }
    
    private func handleDrag(_ value: DragGesture.Value) {
        previewPoint = value.location
        
        if isCreatingCurve {
            // Update curve control point
            curveControlPoint = value.location
        } else if sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height) > 10 {
            // Start creating a curve
            startCurve(at: value.location)
        }
    }
    
    // MARK: - Drawing Methods
    
    private func addCornerPoint(at location: CGPoint) {
        if currentPath == nil {
            currentPath = GlyphPath()
        }
        
        let point = PathPoint(x: location.x, y: location.y, type: .corner)
        currentPath?.points.append(point)
        lastPoint = location
        
        // Auto-close path if clicking near the start
        if let currentPath = currentPath, currentPath.points.count > 2 {
            let firstPoint = currentPath.points[0]
            let distance = sqrt(pow(location.x - firstPoint.x, 2) + pow(location.y - firstPoint.y, 2))
            if distance < 20 {
                currentPath.isClosed = true
                finishPath()
            }
        }
    }
    
    private func startCurve(at location: CGPoint) {
        guard let lastPoint = lastPoint else { return }
        
        isCreatingCurve = true
        curveStartPoint = lastPoint
        curveControlPoint = location
        controlHandle = location
    }
    
    private func completeCurve(at location: CGPoint) {
        guard let currentPath = currentPath,
              let _ = curveStartPoint,
              let controlPoint = curveControlPoint else { return }
        
        // Add the curve point
        let point = PathPoint(x: location.x, y: location.y, type: .curve)
        point.controlInX = controlPoint.x - location.x
        point.controlInY = controlPoint.y - location.y
        point.controlOutX = 0
        point.controlOutY = 0
        currentPath.points.append(point)
        
        // Update the previous point's control out
        if let lastPoint = currentPath.points.last(where: { $0.id != point.id }) {
            lastPoint.controlOutX = controlPoint.x - lastPoint.x
            lastPoint.controlOutY = controlPoint.y - lastPoint.y
        }
        
        lastPoint = location
        isCreatingCurve = false
        curveStartPoint = nil
        curveControlPoint = nil
        controlHandle = nil
    }
    
    private func finishPath() {
        guard let currentPath = currentPath else { return }
        
        glyph.paths.append(currentPath)
        self.currentPath = nil
        lastPoint = nil
        previewPoint = nil
        isCreatingCurve = false
        curveStartPoint = nil
        curveControlPoint = nil
        controlHandle = nil
    }
    
    // MARK: - Public Methods
    
    func startNewPath() {
        finishPath()
    }
    
    func cancelCurrentPath() {
        currentPath = nil
        lastPoint = nil
        previewPoint = nil
        isCreatingCurve = false
        curveStartPoint = nil
        curveControlPoint = nil
        controlHandle = nil
    }
}

// MARK: - Pen Tool Controls

struct PenToolControls: View {
    @ObservedObject var glyph: Glyph
    @Binding var penTool: EnhancedPenTool
    @State private var showAdvancedOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pen Tool")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Basic controls
            HStack {
                Button("New Path") {
                    penTool.startNewPath()
                }
                .buttonStyle(.bordered)
                
                Button("Cancel") {
                    penTool.cancelCurrentPath()
                }
                .buttonStyle(.bordered)
                
                Button("Close Path") {
                    closeCurrentPath()
                }
                .buttonStyle(.bordered)
            }
            
            // Advanced options
            Button("Advanced Options") {
                showAdvancedOptions.toggle()
            }
            .buttonStyle(.borderless)
            
            if showAdvancedOptions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Path Operations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Button("Simplify") {
                            simplifyPaths()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Smooth") {
                            smoothPaths()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Button("Reverse") {
                            reversePaths()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Optimize") {
                            optimizePaths()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Path info
            VStack(alignment: .leading, spacing: 4) {
                Text("Path Info")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Paths: \(glyph.paths.count)")
                    .font(.caption)
                Text("Total Points: \(glyph.paths.reduce(0) { $0 + $1.points.count })")
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func closeCurrentPath() {
        // Find the current path being drawn and close it
        if let lastPath = glyph.paths.last {
            lastPath.isClosed = true
        }
    }
    
    private func simplifyPaths() {
        for path in glyph.paths {
            // Remove redundant points
            var simplifiedPoints: [PathPoint] = []
            var i = 0
            
            while i < path.points.count {
                let currentPoint = path.points[i]
                simplifiedPoints.append(currentPoint)
                
                // Skip points that are too close together
                var j = i + 1
                while j < path.points.count {
                    let nextPoint = path.points[j]
                    let distance = sqrt(pow(currentPoint.x - nextPoint.x, 2) + pow(currentPoint.y - nextPoint.y, 2))
                    if distance > 5 {
                        break
                    }
                    j += 1
                }
                i = j
            }
            
            path.points = simplifiedPoints
        }
    }
    
    private func smoothPaths() {
        for path in glyph.paths {
            for point in path.points {
                if point.type == .corner {
                    point.type = .curve
                    // Add small control handles for smoothing
                    point.controlInX = -10
                    point.controlInY = 0
                    point.controlOutX = 10
                    point.controlOutY = 0
                }
            }
        }
    }
    
    private func reversePaths() {
        for path in glyph.paths {
            path.points.reverse()
            // Swap control handles
            for point in path.points {
                let tempInX = point.controlInX
                let tempInY = point.controlInY
                point.controlInX = point.controlOutX
                point.controlInY = point.controlOutY
                point.controlOutX = tempInX
                point.controlOutY = tempInY
            }
        }
    }
    
    private func optimizePaths() {
        for path in glyph.paths {
            // Remove duplicate points
            var optimizedPoints: [PathPoint] = []
            var lastPoint: PathPoint?
            
            for point in path.points {
                if let last = lastPoint {
                    let distance = sqrt(pow(point.x - last.x, 2) + pow(point.y - last.y, 2))
                    if distance > 1 {
                        optimizedPoints.append(point)
                        lastPoint = point
                    }
                } else {
                    optimizedPoints.append(point)
                    lastPoint = point
                }
            }
            
            path.points = optimizedPoints
        }
    }
}

#Preview {
    PenToolControls(glyph: Glyph(character: "A"), penTool: .constant(EnhancedPenTool(glyph: Glyph(character: "A"))))
        .frame(width: 300, height: 400)
}
