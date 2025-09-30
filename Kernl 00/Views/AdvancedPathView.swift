//
//  AdvancedPathView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct AdvancedPathView: View {
    @ObservedObject var path: GlyphPath
    let isSelected: Bool
    let selectedPoints: Set<UUID>
    let tool: VectorTool
    let zoom: Double
    let panOffset: CGSize
    let snapToGrid: Bool
    let onPathSelect: () -> Void
    let onPointSelect: (PathPoint) -> Void
    let onPointMove: (PathPoint, CGPoint) -> Void
    let onPointAdd: (CGPoint) -> Void
    let onPointDelete: (PathPoint) -> Void
    
    @State private var draggedPoint: PathPoint?
    @State private var dragStart = CGPoint.zero
    
    var body: some View {
        ZStack {
            // Path outline
            Path { path in
                buildPath(from: self.path, into: &path)
            }
            .stroke(
                isSelected ? Color.blue : Color.black,
                lineWidth: isSelected ? 3 : 2
            )
            .fill(Color.black.opacity(0.1))
            .onTapGesture {
                onPathSelect()
            }
            
            // Points and handles
            ForEach(path.points) { point in
                AdvancedPointView(
                    point: point,
                    isSelected: selectedPoints.contains(point.id),
                    tool: tool,
                    zoom: zoom,
                    onTap: {
                        onPointSelect(point)
                    },
                    onDrag: { location in
                        if draggedPoint == nil {
                            draggedPoint = point
                            dragStart = CGPoint(x: point.x, y: point.y)
                        }
                        onPointMove(point, location)
                    },
                    onDragEnd: {
                        draggedPoint = nil
                    }
                )
                
                // Control handles for curve points
                if point.type == .curve && tool == .select {
                    AdvancedControlHandleView(
                        point: point,
                        isInHandle: true,
                        zoom: zoom,
                        onDrag: { location in
                            point.controlInX = location.x - point.x
                            point.controlInY = location.y - point.y
                        }
                    )
                    
                    AdvancedControlHandleView(
                        point: point,
                        isInHandle: false,
                        zoom: zoom,
                        onDrag: { location in
                            point.controlOutX = location.x - point.x
                            point.controlOutY = location.y - point.y
                        }
                    )
                }
            }
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

struct AdvancedPointView: View {
    @ObservedObject var point: PathPoint
    let isSelected: Bool
    let tool: VectorTool
    let zoom: Double
    let onTap: () -> Void
    let onDrag: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    var body: some View {
        Circle()
            .fill(pointColor)
            .stroke(Color.white, lineWidth: 2)
            .frame(width: pointSize, height: pointSize)
            .position(x: point.x, y: point.y)
            .onTapGesture {
                onTap()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let location = CGPoint(x: value.location.x, y: value.location.y)
                        onDrag(location)
                    }
                    .onEnded { _ in
                        onDragEnd()
                    }
            )
    }
    
    private var pointSize: CGFloat {
        let baseSize: CGFloat = 8
        return max(baseSize, baseSize * zoom)
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

struct AdvancedControlHandleView: View {
    @ObservedObject var point: PathPoint
    let isInHandle: Bool
    let zoom: Double
    let onDrag: (CGPoint) -> Void
    
    var body: some View {
        let handleX = isInHandle ? 
            point.x + point.controlInX : 
            point.x + point.controlOutX
        let handleY = isInHandle ? 
            point.y + point.controlInY : 
            point.y + point.controlOutY
        
        Circle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: handleSize, height: handleSize)
            .position(x: handleX, y: handleY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let location = CGPoint(x: value.location.x, y: value.location.y)
                        onDrag(location)
                    }
            )
    }
    
    private var handleSize: CGFloat {
        let baseSize: CGFloat = 6
        return max(baseSize, baseSize * zoom)
    }
}

#Preview {
    AdvancedPathView(
        path: GlyphPath(),
        isSelected: false,
        selectedPoints: [],
        tool: .select,
        zoom: 1.0,
        panOffset: .zero,
        snapToGrid: true,
        onPathSelect: {},
        onPointSelect: { _ in },
        onPointMove: { _, _ in },
        onPointAdd: { _ in },
        onPointDelete: { _ in }
    )
    .frame(width: 400, height: 300)
}
