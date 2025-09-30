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
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
            // Metrics lines
            if showMetrics {
                GlyphMetricsView(glyph: glyph, fontMetrics: fontDocument.fontMetrics)
            }
            
            if isEditing {
                // Interactive path editor
                PathEditorView(glyph: glyph)
            } else {
                // Static glyph paths
                ForEach(glyph.paths) { path in
                    GlyphPathView(path: path)
                }
            }
        }
        .scaleEffect(zoom)
        .frame(width: 800, height: 600)
        .overlay(alignment: .topTrailing) {
            Button(isEditing ? "Preview" : "Edit") {
                isEditing.toggle()
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
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
