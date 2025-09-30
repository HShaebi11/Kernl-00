//
//  IllustratorPenTool.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//  Adobe Illustrator-style pen tool implementation
//

import SwiftUI

struct IllustratorPenTool: View {
    @ObservedObject var glyph: Glyph
    @State private var currentPath: GlyphPath?
    @State private var lastPoint: PathPoint?
    @State private var isCreatingPoint = false
    @State private var isDraggingHandle = false
    @State private var previewLocation: CGPoint?
    @State private var dragStartLocation: CGPoint?
    @State private var currentHandleOut: CGPoint?
    
    // Modifier keys
    @State private var isCommandKeyPressed = false
    @State private var isOptionKeyPressed = false
    @State private var isShiftKeyPressed = false
    @State private var isSpacebarPressed = false
    
    // Preview
    @State private var showPreviewCurve = false
    @State private var previewCurvePoints: [CGPoint] = []
    
    var body: some View {
        ZStack {
            // Existing paths (completed)
            ForEach(glyph.paths) { path in
                GlyphPathView(path: path)
            }
            
            // Current path being drawn
            if let currentPath = currentPath {
                Path { path in
                    buildPath(from: currentPath, into: &path)
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Show all points in current path
                ForEach(currentPath.points) { point in
                    PointHandleView(
                        point: point,
                        isLast: point.id == lastPoint?.id,
                        isOptionPressed: isOptionKeyPressed,
                        onHandleDrag: { handleType, delta in
                            updateHandle(point: point, handleType: handleType, delta: delta)
                        }
                    )
                }
            }
            
            // Preview line from last point to cursor
            if let lastPoint = lastPoint, let previewLocation = previewLocation {
                PreviewCurveView(
                    from: CGPoint(x: lastPoint.x, y: lastPoint.y),
                    controlOut: currentHandleOut,
                    to: previewLocation
                )
            }
            
            // Cursor indicator
            if let previewLocation = previewLocation, !isDraggingHandle {
                Circle()
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    .frame(width: 16, height: 16)
                    .position(previewLocation)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onHover { isHovering in
            if isHovering {
                NSCursor.crosshair.set()
            }
        }
        .focusable(true)
        .onKeyPress(.space) { press in
            isSpacebarPressed = true
            return .handled
        }
        .onKeyPress(.return) { press in
            finishPath()
            return .handled
        }
        .onKeyPress(.escape) { press in
            cancelPath()
            return .handled
        }
        .onMoveCommand { direction in
            // Arrow keys for precise point movement
        }
        .onAppear {
            setupModifierTracking()
        }
    }
    
    // MARK: - Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        previewLocation = value.location
        
        if !isCreatingPoint {
            // Starting a new point
            isCreatingPoint = true
            dragStartLocation = value.location
        }
        
        if isSpacebarPressed {
            // Spacebar held: reposition the point before committing
            dragStartLocation = value.location
        } else {
            // Normal drag: creating handles
            isDraggingHandle = true
            let dragDistance = hypot(
                value.location.x - (dragStartLocation?.x ?? 0),
                value.location.y - (dragStartLocation?.y ?? 0)
            )
            
            // Only create handles if dragged more than threshold
            if dragDistance > 3 {
                currentHandleOut = CGPoint(
                    x: value.location.x - (dragStartLocation?.x ?? 0),
                    y: value.location.y - (dragStartLocation?.y ?? 0)
                )
                
                // Constrain to 45° if Shift is pressed
                if isShiftKeyPressed, let handleOut = currentHandleOut {
                    currentHandleOut = constrainTo45Degrees(handleOut)
                }
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard let startLocation = dragStartLocation else { return }
        
        let dragDistance = hypot(
            value.location.x - startLocation.x,
            value.location.y - startLocation.y
        )
        
        if dragDistance <= 3 {
            // Click (no drag) → Corner point
            addCornerPoint(at: startLocation)
        } else {
            // Click + drag → Smooth point with handles
            addSmoothPoint(at: startLocation, handleOut: currentHandleOut)
        }
        
        // Reset state
        isCreatingPoint = false
        isDraggingHandle = false
        dragStartLocation = nil
        currentHandleOut = nil
    }
    
    // MARK: - Point Creation
    
    private func addCornerPoint(at location: CGPoint) {
        if currentPath == nil {
            currentPath = GlyphPath()
        }
        
        let point = PathPoint(x: location.x, y: location.y, type: .corner)
        point.handleConstraint = .broken
        currentPath?.points.append(point)
        lastPoint = point
        
        // Check for path closing
        if shouldClosePath(at: location) {
            finishPath(closed: true)
        }
    }
    
    private func addSmoothPoint(at location: CGPoint, handleOut: CGPoint?) {
        if currentPath == nil {
            currentPath = GlyphPath()
        }
        
        let point = PathPoint(x: location.x, y: location.y, type: .curve)
        
        if let handleOut = handleOut {
            // Set the outgoing handle
            point.controlOutX = handleOut.x
            point.controlOutY = handleOut.y
            
            // Mirror for incoming handle (symmetric by default)
            if !isOptionKeyPressed {
                point.controlInX = -handleOut.x
                point.controlInY = -handleOut.y
                point.handleConstraint = .symmetric
            } else {
                // Option key: broken handles
                point.handleConstraint = .broken
            }
        }
        
        currentPath?.points.append(point)
        lastPoint = point
        
        // Check for path closing
        if shouldClosePath(at: location) {
            finishPath(closed: true)
        }
    }
    
    // MARK: - Handle Editing
    
    private func updateHandle(point: PathPoint, handleType: HandleType, delta: CGPoint) {
        if handleType == .out {
            if isOptionKeyPressed {
                // Option: break handle symmetry
                point.handleConstraint = .broken
                point.controlOutX += delta.x
                point.controlOutY += delta.y
            } else {
                // Normal: use constraint mode
                point.updateOutHandle(dx: point.controlOutX + delta.x, dy: point.controlOutY + delta.y)
            }
        } else {
            if isOptionKeyPressed {
                point.handleConstraint = .broken
                point.controlInX += delta.x
                point.controlInY += delta.y
            } else {
                point.updateInHandle(dx: point.controlInX + delta.x, dy: point.controlInY + delta.y)
            }
        }
    }
    
    // MARK: - Path Management
    
    private func shouldClosePath(at location: CGPoint) -> Bool {
        guard let currentPath = currentPath,
              let firstPoint = currentPath.points.first,
              currentPath.points.count > 2 else {
            return false
        }
        
        let distance = hypot(location.x - firstPoint.x, location.y - firstPoint.y)
        return distance < 20  // Close threshold
    }
    
    private func finishPath(closed: Bool = false) {
        guard let currentPath = currentPath else { return }
        
        currentPath.isClosed = closed
        glyph.paths.append(currentPath)
        
        // Reset
        self.currentPath = nil
        lastPoint = nil
        previewLocation = nil
    }
    
    private func cancelPath() {
        currentPath = nil
        lastPoint = nil
        previewLocation = nil
        dragStartLocation = nil
        currentHandleOut = nil
    }
    
    // MARK: - Helper Functions
    
    private func buildPath(from glyphPath: GlyphPath, into path: inout Path) {
        guard let firstPoint = glyphPath.points.first else { return }
        path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        
        for i in 1..<glyphPath.points.count {
            let current = glyphPath.points[i]
            let previous = glyphPath.points[i - 1]
            
            if current.type == .curve || previous.type == .curve {
                let control1 = CGPoint(
                    x: previous.x + previous.controlOutX,
                    y: previous.y + previous.controlOutY
                )
                let control2 = CGPoint(
                    x: current.x + current.controlInX,
                    y: current.y + current.controlInY
                )
                path.addCurve(
                    to: CGPoint(x: current.x, y: current.y),
                    control1: control1,
                    control2: control2
                )
            } else {
                path.addLine(to: CGPoint(x: current.x, y: current.y))
            }
        }
        
        if glyphPath.isClosed, let firstPoint = glyphPath.points.first {
            path.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
        }
    }
    
    private func constrainTo45Degrees(_ point: CGPoint) -> CGPoint {
        let angle = atan2(point.y, point.x)
        let length = hypot(point.x, point.y)
        
        // Snap to nearest 45° angle
        let snapAngle = round(angle / (.pi / 4)) * (.pi / 4)
        
        return CGPoint(
            x: cos(snapAngle) * length,
            y: sin(snapAngle) * length
        )
    }
    
    private func setupModifierTracking() {
        // Monitor modifier keys
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            isCommandKeyPressed = event.modifierFlags.contains(.command)
            isOptionKeyPressed = event.modifierFlags.contains(.option)
            isShiftKeyPressed = event.modifierFlags.contains(.shift)
            return event
        }
    }
}

// MARK: - Preview Curve View

struct PreviewCurveView: View {
    let from: CGPoint
    let controlOut: CGPoint?
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            if let controlOut = controlOut {
                // Preview with curve
                let control1 = CGPoint(x: from.x + controlOut.x, y: from.y + controlOut.y)
                // Estimate second control point
                let control2 = CGPoint(
                    x: to.x - controlOut.x * 0.5,
                    y: to.y - controlOut.y * 0.5
                )
                path.addCurve(to: to, control1: control1, control2: control2)
            } else {
                // Preview with straight line
                path.addLine(to: to)
            }
        }
        .stroke(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
    }
}

// MARK: - Point with Handles View

struct PointHandleView: View {
    @ObservedObject var point: PathPoint
    let isLast: Bool
    let isOptionPressed: Bool
    let onHandleDrag: (HandleType, CGPoint) -> Void
    
    @State private var handleInDragStart: CGPoint?
    @State private var handleOutDragStart: CGPoint?
    
    var body: some View {
        ZStack {
            // The anchor point itself
            Circle()
                .fill(point.type == .corner ? Color.red : Color.green)
                .frame(width: isLast ? 12 : 8, height: isLast ? 12 : 8)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .position(x: point.x, y: point.y)
            
            // Control handles (only for curve/smooth points)
            if point.type == .curve || point.type == .auto {
                // In handle
                if point.controlInX != 0 || point.controlInY != 0 {
                    HandleLineView(
                        anchorX: point.x,
                        anchorY: point.y,
                        controlX: point.x + point.controlInX,
                        controlY: point.y + point.controlInY,
                        handleType: .in,
                        constraint: point.handleConstraint,
                        isOptionPressed: isOptionPressed,
                        onDrag: { delta in
                            onHandleDrag(.in, delta)
                        }
                    )
                }
                
                // Out handle
                if point.controlOutX != 0 || point.controlOutY != 0 {
                    HandleLineView(
                        anchorX: point.x,
                        anchorY: point.y,
                        controlX: point.x + point.controlOutX,
                        controlY: point.y + point.controlOutY,
                        handleType: .out,
                        constraint: point.handleConstraint,
                        isOptionPressed: isOptionPressed,
                        onDrag: { delta in
                            onHandleDrag(.out, delta)
                        }
                    )
                }
            }
            
            // Show "close path" indicator if hovering near first point
            if isLast, let firstPoint = currentPath?.points.first {
                let distance = hypot(point.x - firstPoint.x, point.y - firstPoint.y)
                if distance < 20 {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .position(x: firstPoint.x, y: firstPoint.y)
                }
            }
        }
    }
    
    private var currentPath: GlyphPath? {
        // Access to current path for close detection
        return nil
    }
}

// MARK: - Handle Line View

struct HandleLineView: View {
    let anchorX: Double
    let anchorY: Double
    let controlX: Double
    let controlY: Double
    let handleType: HandleType
    let constraint: HandleConstraint
    let isOptionPressed: Bool
    let onDrag: (CGPoint) -> Void
    
    @State private var dragOffset = CGPoint.zero
    
    var body: some View {
        ZStack {
            // Line from anchor to handle
            Path { path in
                path.move(to: CGPoint(x: anchorX, y: anchorY))
                path.addLine(to: CGPoint(x: controlX, y: controlY))
            }
            .stroke(
                constraint == .broken ? Color.orange : Color.blue,
                lineWidth: 1
            )
            
            // Handle control point
            Circle()
                .fill(isOptionPressed ? Color.orange : Color.blue)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .position(x: controlX, y: controlY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            onDrag(CGPoint(x: value.translation.width, y: value.translation.height))
                        }
                )
        }
    }
}

enum HandleType {
    case `in`
    case out
}

// MARK: - Keyboard Modifier Support

extension View {
    func onKeyPress(_ key: KeyEquivalent, action: @escaping (KeyPress) -> KeyPress.Result) -> some View {
        self.onKeyPress(phases: .down) { press in
            if press.key == key {
                return action(press)
            }
            return .ignored
        }
    }
}

#Preview {
    IllustratorPenTool(glyph: Glyph(character: "A"))
        .frame(width: 800, height: 600)
        .background(Color.white)
}
