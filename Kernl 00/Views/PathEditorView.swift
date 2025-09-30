//
//  PathEditorView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct PathEditorView: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedPath: GlyphPath?
    @State private var selectedPoint: PathPoint?
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    @State private var showControlPoints = true
    
    var body: some View {
        ZStack {
            // Background grid and metrics
            if let selectedPath = selectedPath {
                // Path editing canvas
                PathEditingCanvas(
                    path: selectedPath,
                    selectedPoint: $selectedPoint,
                    isDragging: $isDragging,
                    dragOffset: $dragOffset,
                    showControlPoints: showControlPoints
                )
            } else {
                // No path selected
                VStack {
                    Image(systemName: "path")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a path to edit")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            selectedPath = glyph.paths.first
        }
    }
}

struct PathEditingCanvas: View {
    @ObservedObject var path: GlyphPath
    @Binding var selectedPoint: PathPoint?
    @Binding var isDragging: Bool
    @Binding var dragOffset: CGSize
    let showControlPoints: Bool
    
    var body: some View {
        ZStack {
            // Path outline
            Path { path in
                buildPath(from: self.path, into: &path)
            }
            .stroke(Color.black, lineWidth: 2)
            .fill(Color.black.opacity(0.1))
            
            // Control points and handles
            if showControlPoints {
                ForEach(path.points) { point in
                    PointView(
                        point: point,
                        isSelected: selectedPoint?.id == point.id,
                        onTap: {
                            selectedPoint = point
                        },
                        onDrag: { offset in
                            if !isDragging {
                                isDragging = true
                                dragOffset = .zero
                            }
                            dragOffset = offset
                            point.x += offset.width
                            point.y -= offset.height // Invert Y for font coordinates
                        },
                        onDragEnd: {
                            isDragging = false
                            dragOffset = .zero
                        }
                    )
                    
                    // Control handles for curve points
                    if point.type == .curve && showControlPoints {
                        ControlHandleView(
                            point: point,
                            isInHandle: true,
                            onDrag: { offset in
                                point.controlInX += offset.width
                                point.controlInY -= offset.height
                            }
                        )
                        
                        ControlHandleView(
                            point: point,
                            isInHandle: false,
                            onDrag: { offset in
                                point.controlOutX += offset.width
                                point.controlOutY -= offset.height
                            }
                        )
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .background(Color.white)
        .onTapGesture { location in
            // Deselect point when tapping empty space
            selectedPoint = nil
        }
    }
    
    private func buildPath(from glyphPath: GlyphPath, into path: inout Path) {
        guard !glyphPath.points.isEmpty else { return }
        
        let firstPoint = glyphPath.points[0]
        path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        
        for i in 1..<glyphPath.points.count {
            let currentPoint = glyphPath.points[i]
            let previousPoint = glyphPath.points[i - 1]
            
            if currentPoint.type == .curve && previousPoint.type == .curve {
                // Bezier curve
                let controlPoint1 = CGPoint(
                    x: previousPoint.x + previousPoint.controlOutX,
                    y: previousPoint.y + previousPoint.controlOutY
                )
                let controlPoint2 = CGPoint(
                    x: currentPoint.x + currentPoint.controlInX,
                    y: currentPoint.y + currentPoint.controlInY
                )
                path.addCurve(
                    to: CGPoint(x: currentPoint.x, y: currentPoint.y),
                    control1: controlPoint1,
                    control2: controlPoint2
                )
            } else {
                // Straight line
                path.addLine(to: CGPoint(x: currentPoint.x, y: currentPoint.y))
            }
        }
        
        if glyphPath.isClosed {
            path.closeSubpath()
        }
    }
}

struct PointView: View {
    @ObservedObject var point: PathPoint
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGSize) -> Void
    let onDragEnd: () -> Void
    
    var body: some View {
        Circle()
            .fill(pointColor)
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 12, height: 12)
            .position(x: point.x, y: point.y)
            .onTapGesture {
                onTap()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDrag(value.translation)
                    }
                    .onEnded { _ in
                        onDragEnd()
                    }
            )
    }
    
    private var pointColor: Color {
        if isSelected {
            return .blue
        } else {
            switch point.type {
            case .corner:
                return .red
            case .curve:
                return .green
            case .control:
                return .orange
            case .auto:
                return .purple
            }
        }
    }
}

struct ControlHandleView: View {
    @ObservedObject var point: PathPoint
    let isInHandle: Bool
    let onDrag: (CGSize) -> Void
    
    var body: some View {
        let handleX = isInHandle ? 
            point.x + point.controlInX : 
            point.x + point.controlOutX
        let handleY = isInHandle ? 
            point.y + point.controlInY : 
            point.y + point.controlOutY
        
        Circle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 8, height: 8)
            .position(x: handleX, y: handleY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDrag(value.translation)
                    }
            )
    }
}

#Preview {
    PathEditorView(glyph: Glyph(character: "A"))
        .frame(width: 800, height: 600)
}
