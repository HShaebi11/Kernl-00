//
//  PathToolsView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct PathToolsView: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedPath: GlyphPath?
    @State private var selectedPoint: PathPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Path Tools")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Path selection
            if !glyph.paths.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paths")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(glyph.paths) { path in
                        HStack {
                            Button(action: {
                                selectedPath = path
                            }) {
                                HStack {
                                    Image(systemName: selectedPath?.id == path.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedPath?.id == path.id ? .blue : .secondary)
                                    Text("Path \(glyph.paths.firstIndex(where: { $0.id == path.id }) ?? 0 + 1)")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button(action: {
                                removePath(path)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Divider()
            
            // Path operations
            VStack(alignment: .leading, spacing: 8) {
                Text("Operations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Add Rectangle") {
                    addRectangle()
                }
                .buttonStyle(.bordered)
                
                Button("Add Circle") {
                    addCircle()
                }
                .buttonStyle(.bordered)
                
                Button("Add Point") {
                    addPoint()
                }
                .buttonStyle(.bordered)
                .disabled(selectedPath == nil)
                
                Button("Remove Point") {
                    removeSelectedPoint()
                }
                .buttonStyle(.bordered)
                .disabled(selectedPoint == nil)
            }
            
            Divider()
            
            // Point properties
            if let selectedPoint = selectedPoint {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Point Properties")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("X Position")
                            .font(.caption)
                        HStack {
                            TextField("X", value: Binding(
                                get: { selectedPoint.x },
                                set: { selectedPoint.x = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                            Text("units")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Position")
                            .font(.caption)
                        HStack {
                            TextField("Y", value: Binding(
                                get: { selectedPoint.y },
                                set: { selectedPoint.y = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                            Text("units")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Point Type")
                            .font(.caption)
                        Picker("Type", selection: Binding(
                            get: { selectedPoint.type },
                            set: { selectedPoint.type = $0 }
                        )) {
                            Text("Corner").tag(PointType.corner)
                            Text("Curve").tag(PointType.curve)
                            Text("Control").tag(PointType.control)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if selectedPoint.type == .curve {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Control In X")
                                .font(.caption)
                            TextField("Control In X", value: Binding(
                                get: { selectedPoint.controlInX },
                                set: { selectedPoint.controlInX = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Control In Y")
                                .font(.caption)
                            TextField("Control In Y", value: Binding(
                                get: { selectedPoint.controlInY },
                                set: { selectedPoint.controlInY = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Control Out X")
                                .font(.caption)
                            TextField("Control Out X", value: Binding(
                                get: { selectedPoint.controlOutX },
                                set: { selectedPoint.controlOutX = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Control Out Y")
                                .font(.caption)
                            TextField("Control Out Y", value: Binding(
                                get: { selectedPoint.controlOutY },
                                set: { selectedPoint.controlOutY = $0 }
                            ), format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            selectedPath = glyph.paths.first
        }
    }
    
    private func addRectangle() {
        let newPath = GlyphPath()
        newPath.addRectangle(x: 100, y: 100, width: 400, height: 600)
        glyph.paths.append(newPath)
        selectedPath = newPath
    }
    
    private func addCircle() {
        let newPath = GlyphPath()
        newPath.addCircle(centerX: 300, centerY: 400, radius: 200)
        glyph.paths.append(newPath)
        selectedPath = newPath
    }
    
    private func addPoint() {
        guard let path = selectedPath else { return }
        
        let newPoint = PathPoint(x: 300, y: 400, type: .corner)
        path.points.append(newPoint)
    }
    
    private func removeSelectedPoint() {
        guard let point = selectedPoint,
              let path = selectedPath else { return }
        
        path.points.removeAll { $0.id == point.id }
        selectedPoint = nil
    }
    
    private func removePath(_ path: GlyphPath) {
        glyph.paths.removeAll { $0.id == path.id }
        if selectedPath?.id == path.id {
            selectedPath = glyph.paths.first
        }
    }
}

#Preview {
    PathToolsView(glyph: Glyph(character: "A"))
        .frame(width: 300, height: 600)
}
