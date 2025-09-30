//
//  GlyphEditorView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct GlyphEditorView: View {
    @ObservedObject var fontDocument: FontDocument
    @State private var zoom: Double = 1.0
    @State private var showGrid: Bool = true
    @State private var showMetrics: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor controls
            HStack {
                // Zoom controls
                HStack(spacing: 4) {
                    Button("-") {
                        zoom = max(0.1, zoom - 0.1)
                    }
                    .buttonStyle(.borderless)
                    
                    Text("\(Int(zoom * 100))%")
                        .frame(width: 50)
                        .font(.caption)
                    
                    Button("+") {
                        zoom = min(5.0, zoom + 0.1)
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                // View options
                HStack(spacing: 8) {
                    Toggle("Grid", isOn: $showGrid)
                        .toggleStyle(.button)
                        .buttonStyle(.borderless)
                    
                    Toggle("Metrics", isOn: $showMetrics)
                        .toggleStyle(.button)
                        .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Canvas
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        // Background
                        Rectangle()
                            .fill(Color.white)
                            .frame(
                                width: max(geometry.size.width, 800),
                                height: max(geometry.size.height, 600)
                            )
                        
                        // Grid
                        if showGrid {
                            GridView()
                                .opacity(0.3)
                        }
                        
                        // Glyph canvas
                        if let selectedGlyph = fontDocument.selectedGlyph {
                            GlyphCanvasView(
                                glyph: selectedGlyph,
                                fontDocument: fontDocument,
                                zoom: zoom,
                                showMetrics: showMetrics
                            )
                        } else {
                            // No glyph selected
                            VStack {
                                Image(systemName: "textformat")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Select a glyph to edit")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
    }
}

struct GridView: View {
    let gridSize: CGFloat = 20
    
    var body: some View {
        Canvas { context, size in
            // Draw grid lines
            context.stroke(
                Path { path in
                    // Vertical lines
                    for x in stride(from: 0, through: size.width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, through: size.height, by: gridSize) {
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

struct GlyphCanvasView: View {
    @ObservedObject var glyph: Glyph
    @ObservedObject var fontDocument: FontDocument
    let zoom: Double
    let showMetrics: Bool
    @State private var drawingMode: DrawingMode = .vector
    @State private var drawnPoints: [CGPoint] = []
    @State private var isDrawing = false
    @State private var drawingTool: DrawingTool = .pen
    @State private var smoothness: Double = 0.5
    
    var body: some View {
        ZStack {
            // Metrics lines
            if showMetrics {
                GlyphMetricsView(glyph: glyph, fontMetrics: fontDocument.fontMetrics)
            }
            
            // Main drawing/editing area
            ZStack {
                // Freehand drawing overlay
                if drawingMode == .freehand {
                    Canvas { context, size in
                        if drawnPoints.count > 1 {
                            var path = Path()
                            path.move(to: drawnPoints[0])
                            for point in drawnPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                            context.stroke(path, with: .color(.blue), lineWidth: 2)
                        }
                    }
                    .contentShape(Rectangle())
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
                                convertFreehandToPath()
                                isDrawing = false
                            }
                    )
                }
                
            // Vector editing mode
            if drawingMode == .vector {
                if drawingTool == .pen {
                    IllustratorPenTool(glyph: glyph)
                } else {
                    AdvancedVectorEditor(glyph: glyph)
                }
            }
                
                // Preview mode - show all paths
                if drawingMode == .preview {
                    ForEach(glyph.paths) { path in
                        GlyphPathView(path: path)
                    }
                }
            }
        }
        .scaleEffect(zoom)
        .frame(width: 800, height: 600)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                // Mode selector
                Picker("", selection: $drawingMode) {
                    Label("Vector", systemImage: "pencil.tip").tag(DrawingMode.vector)
                    Label("Draw", systemImage: "scribble").tag(DrawingMode.freehand)
                    Label("Preview", systemImage: "eye").tag(DrawingMode.preview)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                // Tool selector (only in vector mode)
                if drawingMode == .vector {
                    Picker("", selection: $drawingTool) {
                        Label("Pen", systemImage: "pencil.tip.crop.circle").tag(DrawingTool.pen)
                        Label("Edit", systemImage: "hand.point.up.left").tag(DrawingTool.edit)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                
                // Freehand controls
                if drawingMode == .freehand && drawnPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smoothness")
                            .font(.caption2)
                        Slider(value: $smoothness, in: 0...1)
                            .frame(width: 120)
                    }
                }
            }
            .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            if drawingMode == .freehand && !drawnPoints.isEmpty {
                Button("Convert to Path") {
                    convertFreehandToPath()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
    
    // MARK: - Path Conversion
    
    private func convertFreehandToPath() {
        guard drawnPoints.count > 2 else {
            drawnPoints = []
            return
        }
        
        // Simplify using Ramer-Douglas-Peucker
        let simplified = simplifyPath(drawnPoints, tolerance: 5.0)
        
        // Create glyph path with smooth curves
        let glyphPath = GlyphPath()
        for (index, point) in simplified.enumerated() {
            let pathPoint = PathPoint(x: point.x, y: point.y, type: .curve)
            
            // Add smooth handles based on surrounding points
            if index > 0 && index < simplified.count - 1 {
                let prev = simplified[index - 1]
                let next = simplified[index + 1]
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
        
        glyph.paths.append(glyphPath)
        drawnPoints = []
    }
    
    private func simplifyPath(_ points: [CGPoint], tolerance: Double) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
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
        
        if maxDistance > tolerance {
            let left = simplifyPath(Array(points[0...maxIndex]), tolerance: tolerance)
            let right = simplifyPath(Array(points[maxIndex..<points.count]), tolerance: tolerance)
            return left.dropLast() + right
        } else {
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

enum DrawingMode {
    case vector
    case freehand
    case preview
}

enum DrawingTool {
    case pen
    case edit
}

struct GlyphMetricsView: View {
    @ObservedObject var glyph: Glyph
    @ObservedObject var fontMetrics: FontMetrics
    
    var body: some View {
        MetricsView(glyph: glyph, fontMetrics: fontMetrics)
    }
}

struct GlyphPathView: View {
    @ObservedObject var path: GlyphPath
    
    var body: some View {
        Path { path in
            guard !self.path.points.isEmpty else { return }
            
            let firstPoint = self.path.points[0]
            path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
            
            for i in 1..<self.path.points.count {
                let point = self.path.points[i]
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            
            if self.path.isClosed {
                path.closeSubpath()
            }
        }
        .stroke(Color.black, lineWidth: 2)
        .fill(Color.black.opacity(0.1))
    }
}

#Preview {
    GlyphEditorView(fontDocument: FontDocument())
        .frame(width: 600, height: 400)
}
