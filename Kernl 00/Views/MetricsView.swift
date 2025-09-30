//
//  MetricsView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct MetricsView: View {
    @ObservedObject var glyph: Glyph
    @ObservedObject var fontMetrics: FontMetrics
    @State private var showAdvancedMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Baseline
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Text("Baseline")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.leading, 4)
                }
            
            // Ascender line
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Text("Ascender")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                }
                .offset(y: -fontMetrics.ascender)
            
            // Cap height line
            Rectangle()
                .fill(Color.orange.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Text("Cap Height")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.leading, 4)
                }
                .offset(y: -fontMetrics.capHeight)
            
            // X height line
            Rectangle()
                .fill(Color.purple.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Text("X Height")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.leading, 4)
                }
                .offset(y: -fontMetrics.xHeight)
            
            // Descender line
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Text("Descender")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
                .offset(y: -fontMetrics.descender)
            
            // Glyph bounds
            Rectangle()
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                .frame(width: glyph.width, height: fontMetrics.ascender - fontMetrics.descender)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Width: \(Int(glyph.width))")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("LSB: \(Int(glyph.leftSideBearing))")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("RSB: \(Int(glyph.rightSideBearing))")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    .padding(4)
                }
                .offset(y: -fontMetrics.ascender)
        }
        .frame(width: 800, height: 600)
    }
}

struct AdvancedMetricsView: View {
    @ObservedObject var fontMetrics: FontMetrics
    @State private var editingMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Font Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(editingMetrics ? "Done" : "Edit") {
                    editingMetrics.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if editingMetrics {
                VStack(alignment: .leading, spacing: 12) {
                    MetricField(
                        title: "Units per Em",
                        value: Binding(
                            get: { fontMetrics.unitsPerEm },
                            set: { fontMetrics.unitsPerEm = $0 }
                        )
                    )
                    
                    MetricField(
                        title: "Ascender",
                        value: Binding(
                            get: { fontMetrics.ascender },
                            set: { fontMetrics.ascender = $0 }
                        )
                    )
                    
                    MetricField(
                        title: "Descender",
                        value: Binding(
                            get: { fontMetrics.descender },
                            set: { fontMetrics.descender = $0 }
                        )
                    )
                    
                    MetricField(
                        title: "Cap Height",
                        value: Binding(
                            get: { fontMetrics.capHeight },
                            set: { fontMetrics.capHeight = $0 }
                        )
                    )
                    
                    MetricField(
                        title: "X Height",
                        value: Binding(
                            get: { fontMetrics.xHeight },
                            set: { fontMetrics.xHeight = $0 }
                        )
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    MetricDisplay(title: "Units per Em", value: "\(Int(fontMetrics.unitsPerEm))")
                    MetricDisplay(title: "Ascender", value: "\(Int(fontMetrics.ascender))")
                    MetricDisplay(title: "Descender", value: "\(Int(fontMetrics.descender))")
                    MetricDisplay(title: "Cap Height", value: "\(Int(fontMetrics.capHeight))")
                    MetricDisplay(title: "X Height", value: "\(Int(fontMetrics.xHeight))")
                    MetricDisplay(title: "Baseline", value: "\(Int(fontMetrics.baseline))")
                }
            }
        }
        .padding()
    }
}

struct MetricField: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                TextField(title, value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                Text("units")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MetricDisplay: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AdvancedMetricsView(fontMetrics: FontMetrics())
        .frame(width: 300, height: 400)
}
