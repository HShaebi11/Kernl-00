//
//  InspectorView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct InspectorView: View {
    @ObservedObject var fontDocument: FontDocument
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Inspector")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Font Properties
                    FontPropertiesSection(fontDocument: fontDocument)
                    
                    Divider()
                    
                    // Glyph Properties
                    if let selectedGlyph = fontDocument.selectedGlyph {
                        GlyphPropertiesSection(glyph: selectedGlyph)
                        
                        Divider()
                        
                        // Path Tools
                        PathToolsView(glyph: selectedGlyph)
                        
                        Divider()
                        
                        // Vector Import/Export
                        VectorImportExportView(glyph: selectedGlyph)
                        
                        Divider()
                        
                        // Transform Tools
                        TransformToolsView(glyph: selectedGlyph)
                    } else {
                        Text("No glyph selected")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    
                    Divider()
                    
                    // Advanced Metrics
                    AdvancedMetricsView(fontMetrics: fontDocument.fontMetrics)
                    
                    Divider()
                    
                    // Kerning
                    KerningView(fontDocument: fontDocument)
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FontPropertiesSection: View {
    @ObservedObject var fontDocument: FontDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Font Properties")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Font Name", text: $fontDocument.fontName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Glyphs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(fontDocument.glyphs.count)")
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
    }
}

struct GlyphPropertiesSection: View {
    @ObservedObject var glyph: Glyph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glyph Properties")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Character")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(glyph.character))
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Width")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("Width", value: $glyph.width, format: .number)
                        .textFieldStyle(.roundedBorder)
                    Text("units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Left Side Bearing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("LSB", value: $glyph.leftSideBearing, format: .number)
                        .textFieldStyle(.roundedBorder)
                    Text("units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Right Side Bearing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("RSB", value: $glyph.rightSideBearing, format: .number)
                        .textFieldStyle(.roundedBorder)
                    Text("units")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Width")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(glyph.totalWidth)) units")
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Paths")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(glyph.paths.count) path\(glyph.paths.count == 1 ? "" : "s")")
                    .font(.body)
            }
        }
    }
}

struct MetricsSection: View {
    @ObservedObject var fontDocument: FontDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Font Metrics")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Units per Em")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fontDocument.fontMetrics.unitsPerEm))")
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ascender")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fontDocument.fontMetrics.ascender))")
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Descender")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fontDocument.fontMetrics.descender))")
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cap Height")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fontDocument.fontMetrics.capHeight))")
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("X Height")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(fontDocument.fontMetrics.xHeight))")
                    .font(.body)
            }
        }
    }
}

#Preview {
    InspectorView(fontDocument: FontDocument())
        .frame(width: 300, height: 600)
}
