//
//  TransformToolsView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct TransformToolsView: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedPaths: Set<UUID> = []
    @State private var scaleX: Double = 1.0
    @State private var scaleY: Double = 1.0
    @State private var rotationAngle: Double = 0.0
    @State private var skewX: Double = 0.0
    @State private var skewY: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transform Tools")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Path Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Paths")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(glyph.paths) { path in
                    Toggle("Path \(glyph.paths.firstIndex(where: { $0.id == path.id })! + 1)", 
                           isOn: Binding(
                            get: { selectedPaths.contains(path.id) },
                            set: { isOn in
                                if isOn {
                                    selectedPaths.insert(path.id)
                                } else {
                                    selectedPaths.remove(path.id)
                                }
                            }
                           ))
                    .toggleStyle(.checkbox)
                }
            }
            
            Divider()
            
            // Scale
            VStack(alignment: .leading, spacing: 8) {
                Text("Scale")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("X:")
                    Slider(value: $scaleX, in: 0.1...3.0)
                    Text("\(String(format: "%.2f", scaleX))")
                        .frame(width: 50)
                }
                
                HStack {
                    Text("Y:")
                    Slider(value: $scaleY, in: 0.1...3.0)
                    Text("\(String(format: "%.2f", scaleY))")
                        .frame(width: 50)
                }
                
                Button("Apply Scale") {
                    applyScale()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Rotate
            VStack(alignment: .leading, spacing: 8) {
                Text("Rotate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Angle:")
                    Slider(value: $rotationAngle, in: -180...180)
                    Text("\(String(format: "%.0f", rotationAngle))°")
                        .frame(width: 50)
                }
                
                Button("Apply Rotation") {
                    applyRotation()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Skew
            VStack(alignment: .leading, spacing: 8) {
                Text("Skew")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("X:")
                    Slider(value: $skewX, in: -45...45)
                    Text("\(String(format: "%.0f", skewX))°")
                        .frame(width: 50)
                }
                
                HStack {
                    Text("Y:")
                    Slider(value: $skewY, in: -45...45)
                    Text("\(String(format: "%.0f", skewY))°")
                        .frame(width: 50)
                }
                
                Button("Apply Skew") {
                    applySkew()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Mirror
            VStack(alignment: .leading, spacing: 8) {
                Text("Mirror")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Horizontal") {
                        applyMirror(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Vertical") {
                        applyMirror(horizontal: false, vertical: true)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Divider()
            
            // Boolean Operations
            VStack(alignment: .leading, spacing: 8) {
                Text("Boolean Operations")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Union") {
                        performBoolean(.union)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Subtract") {
                        performBoolean(.subtract)
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Button("Intersect") {
                        performBoolean(.intersect)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Exclude") {
                        performBoolean(.exclude)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getCenter() -> CGPoint {
        let paths = getSelectedPaths()
        guard !paths.isEmpty else { return CGPoint(x: 400, y: 400) }
        
        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity
        
        for path in paths {
            for point in path.points {
                minX = min(minX, point.x)
                maxX = max(maxX, point.x)
                minY = min(minY, point.y)
                maxY = max(maxY, point.y)
            }
        }
        
        return CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
    }
    
    private func getSelectedPaths() -> [GlyphPath] {
        glyph.paths.filter { selectedPaths.contains($0.id) }
    }
    
    private func applyScale() {
        let center = getCenter()
        for path in getSelectedPaths() {
            PathOperations.scale(path: path, scaleX: scaleX, scaleY: scaleY, around: center)
        }
        scaleX = 1.0
        scaleY = 1.0
    }
    
    private func applyRotation() {
        let center = getCenter()
        for path in getSelectedPaths() {
            PathOperations.rotate(path: path, angle: rotationAngle, around: center)
        }
        rotationAngle = 0.0
    }
    
    private func applySkew() {
        let center = getCenter()
        for path in getSelectedPaths() {
            PathOperations.skew(path: path, angleX: skewX, angleY: skewY, around: center)
        }
        skewX = 0.0
        skewY = 0.0
    }
    
    private func applyMirror(horizontal: Bool, vertical: Bool) {
        let center = getCenter()
        for path in getSelectedPaths() {
            PathOperations.mirror(path: path, horizontal: horizontal, vertical: vertical, around: center)
        }
    }
    
    private func performBoolean(_ operation: BooleanOperation) {
        let paths = getSelectedPaths()
        guard paths.count >= 2 else { return }
        
        let result = PathOperations.performBoolean(operation, on: paths)
        
        // Remove old paths
        glyph.paths.removeAll { selectedPaths.contains($0.id) }
        
        // Add result
        glyph.paths.append(contentsOf: result)
        selectedPaths.removeAll()
    }
}

#Preview {
    TransformToolsView(glyph: Glyph(character: "A"))
        .frame(width: 300, height: 600)
}
