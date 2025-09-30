//
//  SmoothingToolsView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct SmoothingToolsView: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedPaths: Set<UUID> = []
    @State private var smoothingMethod: SmoothingMethod = .autoSmooth
    @State private var chaikinIterations: Double = 2
    @State private var catmullTension: Double = 0.5
    @State private var gaussianRadius: Double = 2
    @State private var gaussianSigma: Double = 1.0
    @State private var cornerAngleThreshold: Double = 30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Path Smoothing")
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
            
            // Smoothing Method
            VStack(alignment: .leading, spacing: 8) {
                Text("Smoothing Method")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Method", selection: $smoothingMethod) {
                    Text("Auto Smooth").tag(SmoothingMethod.autoSmooth)
                    Text("Chaikin").tag(SmoothingMethod.chaikin)
                    Text("Catmull-Rom").tag(SmoothingMethod.catmullRom)
                    Text("Gaussian").tag(SmoothingMethod.gaussian)
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            // Method-specific parameters
            Group {
                switch smoothingMethod {
                case .autoSmooth:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Automatically adds smooth handles based on surrounding points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Corner Detection Threshold")
                            .font(.caption)
                        HStack {
                            Slider(value: $cornerAngleThreshold, in: 0...90)
                            Text("\(Int(cornerAngleThreshold))°")
                                .frame(width: 40)
                        }
                    }
                    
                case .chaikin:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chaikin's corner-cutting algorithm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Iterations: \(Int(chaikinIterations))")
                            .font(.caption)
                        Slider(value: $chaikinIterations, in: 1...5, step: 1)
                    }
                    
                case .catmullRom:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Catmull-Rom spline interpolation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Tension: \(String(format: "%.2f", catmullTension))")
                            .font(.caption)
                        Slider(value: $catmullTension, in: 0...1)
                    }
                    
                case .gaussian:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gaussian blur smoothing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Radius: \(Int(gaussianRadius))")
                            .font(.caption)
                        Slider(value: $gaussianRadius, in: 1...10, step: 1)
                        
                        Text("Sigma: \(String(format: "%.2f", gaussianSigma))")
                            .font(.caption)
                        Slider(value: $gaussianSigma, in: 0.5...3.0)
                    }
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Apply Smoothing") {
                    applySmoothing()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPaths.isEmpty)
                
                Button("Detect Corners") {
                    detectCorners()
                }
                .buttonStyle(.bordered)
                .disabled(selectedPaths.isEmpty)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func applySmoothing() {
        for path in glyph.paths where selectedPaths.contains(path.id) {
            let smoothed: GlyphPath
            
            switch smoothingMethod {
            case .autoSmooth:
                smoothed = PathSmoothing.autoSmooth(path: path)
            case .chaikin:
                smoothed = PathSmoothing.chaikinSmooth(path: path, iterations: Int(chaikinIterations))
            case .catmullRom:
                smoothed = PathSmoothing.catmullRomSmooth(path: path, tension: catmullTension)
            case .gaussian:
                smoothed = PathSmoothing.gaussianSmooth(path: path, radius: Int(gaussianRadius), sigma: gaussianSigma)
            }
            
            // Replace path points
            path.points = smoothed.points
        }
    }
    
    private func detectCorners() {
        for path in glyph.paths where selectedPaths.contains(path.id) {
            let corners = PathSmoothing.detectCorners(path: path, angleThreshold: cornerAngleThreshold)
            
            // Mark detected corners
            for (index, point) in path.points.enumerated() {
                if corners.contains(index) {
                    point.type = .corner
                    point.controlInX = 0
                    point.controlInY = 0
                    point.controlOutX = 0
                    point.controlOutY = 0
                } else {
                    point.type = .curve
                }
            }
        }
    }
}

enum SmoothingMethod {
    case autoSmooth
    case chaikin
    case catmullRom
    case gaussian
}

#Preview {
    SmoothingToolsView(glyph: Glyph(character: "A"))
        .frame(width: 350, height: 600)
}
