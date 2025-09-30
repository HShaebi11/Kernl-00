//
//  AdvancedVectorEditor.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct AdvancedVectorEditor: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedTool: VectorTool = .select
    @State private var selectedPaths: Set<UUID> = []
    @State private var selectedPoints: Set<UUID> = []
    @State private var isDragging = false
    @State private var dragStart = CGPoint.zero
    @State private var dragCurrent = CGPoint.zero
    @State private var showGrid = true
    @State private var showGuides = true
    @State private var snapToGrid = true
    @State private var zoom: Double = 1.0
    @State private var panOffset = CGSize.zero
    @State private var isPanning = false
    @State private var clipboard: [GlyphPath] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Advanced Toolbar
            AdvancedToolbar(
                selectedTool: $selectedTool,
                showGrid: $showGrid,
                showGuides: $showGuides,
                snapToGrid: $snapToGrid,
                zoom: $zoom,
                onZoomIn: { zoom = min(10.0, zoom * 1.2) },
                onZoomOut: { zoom = max(0.1, zoom / 1.2) },
                onZoomFit: { zoom = 1.0; panOffset = .zero },
                onCopy: copySelected,
                onPaste: pasteFromClipboard,
                onDelete: deleteSelected,
                onUndo: undo,
                onRedo: redo
            )
            
            Divider()
            
            // Main Editor Area
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.white)
                        .onTapGesture { location in
                            handleCanvasTap(at: location)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleCanvasDrag(value, in: geometry)
                                }
                                .onEnded { _ in
                                    handleCanvasDragEnd()
                                }
                        )
                    
                    // Grid
                    if showGrid {
                        AdvancedGridView(
                            gridSize: 20,
                            zoom: zoom,
                            panOffset: panOffset
                        )
                    }
                    
                    // Guides
                    if showGuides {
                        GuideLinesView(
                            glyph: glyph,
                            zoom: zoom,
                            panOffset: panOffset
                        )
                    }
                    
                    // Paths
                    ForEach(glyph.paths) { path in
                        AdvancedPathView(
                            path: path,
                            isSelected: selectedPaths.contains(path.id),
                            selectedPoints: selectedPoints,
                            tool: selectedTool,
                            zoom: zoom,
                            panOffset: panOffset,
                            snapToGrid: snapToGrid,
                            onPathSelect: { selectPath(path) },
                            onPointSelect: { selectPoint($0) },
                            onPointMove: { movePoint($0, to: $1) },
                            onPointAdd: { addPointToPath(path, at: $0) },
                            onPointDelete: { deletePoint($0) }
                        )
                    }
                    
                    // Enhanced Pen Tool
                    if selectedTool == .pen {
                        EnhancedPenTool(glyph: glyph)
                    }
                    
                    // Selection Rectangle
                    if isDragging && selectedTool == .select {
                        SelectionRectangle(
                            start: dragStart,
                            current: dragCurrent,
                            zoom: zoom,
                            panOffset: panOffset
                        )
                    }
                    
                    // Pen Tool Preview
                    if selectedTool == .pen {
                        PenToolPreview(
                            currentPoint: dragCurrent,
                            zoom: zoom,
                            panOffset: panOffset
                        )
                    }
                }
                .scaleEffect(zoom)
                .offset(panOffset)
                .clipped()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoom = max(0.1, min(10.0, zoom * value))
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isPanning {
                                isPanning = true
                            }
                            panOffset = CGSize(
                                width: panOffset.width + value.translation.width,
                                height: panOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            isPanning = false
                        }
                )
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleCanvasTap(at location: CGPoint) {
        let canvasPoint = convertToCanvasPoint(location)
        
        switch selectedTool {
        case .select:
            // Deselect all if clicking empty space
            if !isPointAtLocation(canvasPoint) {
                selectedPoints.removeAll()
                selectedPaths.removeAll()
            }
        case .pen:
            addPointAtLocation(canvasPoint)
        case .delete:
            deletePointAtLocation(canvasPoint)
        default:
            break
        }
    }
    
    private func handleCanvasDrag(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let canvasPoint = convertToCanvasPoint(value.location)
        
        if !isDragging {
            isDragging = true
            dragStart = canvasPoint
        }
        dragCurrent = canvasPoint
        
        switch selectedTool {
        case .select:
            // Selection rectangle
            break
        case .pen:
            // Pen tool preview
            break
        case .move:
            // Move selected points
            if !selectedPoints.isEmpty {
                let delta = CGPoint(
                    x: canvasPoint.x - dragStart.x,
                    y: canvasPoint.y - dragStart.y
                )
                moveSelectedPoints(by: delta)
                dragStart = canvasPoint
            }
        default:
            break
        }
    }
    
    private func handleCanvasDragEnd() {
        isDragging = false
        
        if selectedTool == .select {
            // Select points within rectangle
            selectPointsInRectangle(from: dragStart, to: dragCurrent)
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToCanvasPoint(_ screenPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: (screenPoint.x - panOffset.width) / zoom,
            y: (screenPoint.y - panOffset.height) / zoom
        )
    }
    
    private func isPointAtLocation(_ location: CGPoint) -> Bool {
        for path in glyph.paths {
            for point in path.points {
                let pointLocation = CGPoint(x: point.x, y: point.y)
                let distance = sqrt(pow(location.x - pointLocation.x, 2) + pow(location.y - pointLocation.y, 2))
                if distance < 10 {
                    return true
                }
            }
        }
        return false
    }
    
    private func selectPath(_ path: GlyphPath) {
        selectedPaths.insert(path.id)
    }
    
    private func selectPoint(_ point: PathPoint) {
        selectedPoints.insert(point.id)
    }
    
    private func movePoint(_ point: PathPoint, to location: CGPoint) {
        point.x = snapToGrid ? round(location.x / 20) * 20 : location.x
        point.y = snapToGrid ? round(location.y / 20) * 20 : location.y
    }
    
    private func addPointToPath(_ path: GlyphPath, at location: CGPoint) {
        let newPoint = PathPoint(x: location.x, y: location.y, type: .corner)
        path.points.append(newPoint)
    }
    
    private func deletePoint(_ point: PathPoint) {
        for path in glyph.paths {
            path.points.removeAll { $0.id == point.id }
        }
        selectedPoints.remove(point.id)
    }
    
    private func addPointAtLocation(_ location: CGPoint) {
        if let selectedPath = glyph.paths.first(where: { selectedPaths.contains($0.id) }) {
            addPointToPath(selectedPath, at: location)
        } else if let firstPath = glyph.paths.first {
            addPointToPath(firstPath, at: location)
        }
    }
    
    private func deletePointAtLocation(_ location: CGPoint) {
        for path in glyph.paths {
            for point in path.points {
                let pointLocation = CGPoint(x: point.x, y: point.y)
                let distance = sqrt(pow(location.x - pointLocation.x, 2) + pow(location.y - pointLocation.y, 2))
                if distance < 10 {
                    deletePoint(point)
                    return
                }
            }
        }
    }
    
    private func selectPointsInRectangle(from start: CGPoint, to end: CGPoint) {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        
        for path in glyph.paths {
            for point in path.points {
                if point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY {
                    selectedPoints.insert(point.id)
                }
            }
        }
    }
    
    private func moveSelectedPoints(by delta: CGPoint) {
        for path in glyph.paths {
            for point in path.points {
                if selectedPoints.contains(point.id) {
                    point.x += delta.x
                    point.y += delta.y
                }
            }
        }
    }
    
    // MARK: - Clipboard Operations
    
    private func copySelected() {
        clipboard = glyph.paths.filter { selectedPaths.contains($0.id) }
    }
    
    private func pasteFromClipboard() {
        for path in clipboard {
            let newPath = GlyphPath()
            newPath.points = path.points.map { point in
                let newPoint = PathPoint(x: point.x + 20, y: point.y + 20, type: point.type)
                newPoint.controlInX = point.controlInX
                newPoint.controlInY = point.controlInY
                newPoint.controlOutX = point.controlOutX
                newPoint.controlOutY = point.controlOutY
                return newPoint
            }
            glyph.paths.append(newPath)
            selectedPaths.insert(newPath.id)
        }
    }
    
    private func deleteSelected() {
        glyph.paths.removeAll { selectedPaths.contains($0.id) }
        selectedPaths.removeAll()
        selectedPoints.removeAll()
    }
    
    // MARK: - Undo/Redo (Placeholder)
    
    private func undo() {
        // TODO: Implement undo functionality
    }
    
    private func redo() {
        // TODO: Implement redo functionality
    }
}

// MARK: - Vector Tools

enum VectorTool: String, CaseIterable {
    case select = "Select"
    case pen = "Pen"
    case move = "Move"
    case delete = "Delete"
    case rectangle = "Rectangle"
    case circle = "Circle"
    case path = "Path"
    case importExport = "Import/Export"
}

#Preview {
    AdvancedVectorEditor(glyph: Glyph(character: "A"))
        .frame(width: 800, height: 600)
}
