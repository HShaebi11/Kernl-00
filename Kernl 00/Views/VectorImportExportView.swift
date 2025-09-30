//
//  VectorImportExportView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct VectorImportExportView: View {
    @ObservedObject var glyph: Glyph
    @State private var selectedFormat: VectorFormat = .svg
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    @State private var importText = ""
    @State private var exportText = ""
    @State private var showClipboardOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vector Import/Export")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Import Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Import")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Import from Clipboard") {
                        importFromClipboard()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Import from Text") {
                        showImportDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                
                if ClipboardManager.hasVectorData() {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Vector data available in clipboard")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Divider()
            
            // Export Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Export")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Copy to Clipboard") {
                        copyToClipboard()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export as Text") {
                        showExportDialog = true
                    }
                    .buttonStyle(.bordered)
                }
                
                // Format selection
                Picker("Format", selection: $selectedFormat) {
                    ForEach(VectorFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            // Path Operations
            VStack(alignment: .leading, spacing: 8) {
                Text("Path Operations")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Button("Simplify") {
                        simplifyPaths()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Smooth") {
                        smoothPaths()
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Button("Reverse") {
                        reversePaths()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Optimize") {
                        optimizePaths()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Divider()
            
            // Path Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Path Info")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Paths: \(glyph.paths.count)")
                    .font(.caption)
                Text("Total Points: \(glyph.paths.reduce(0) { $0 + $1.points.count })")
                    .font(.caption)
                Text("Closed Paths: \(glyph.paths.filter { $0.isClosed }.count)")
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImportDialog) {
            ImportDialogView(
                isPresented: $showImportDialog,
                importText: $importText,
                onImport: { importFromText() }
            )
        }
        .sheet(isPresented: $showExportDialog) {
            ExportDialogView(
                isPresented: $showExportDialog,
                exportText: $exportText,
                onExport: { exportAsText() }
            )
        }
        .onAppear {
            updateExportText()
        }
        .onChange(of: glyph.paths.count) { _ in
            updateExportText()
        }
    }
    
    // MARK: - Import Methods
    
    private func importFromClipboard() {
        let importedPaths = ClipboardManager.pastePaths()
        for path in importedPaths {
            glyph.paths.append(path)
        }
    }
    
    private func importFromText() {
        let importedPaths = SVGParser.parse(importText)
        for path in importedPaths {
            glyph.paths.append(path)
        }
        importText = ""
    }
    
    // MARK: - Export Methods
    
    private func copyToClipboard() {
        ClipboardManager.copyPaths(glyph.paths)
    }
    
    private func exportAsText() {
        // The export text is already updated in updateExportText()
        // This method can be used for additional export logic
    }
    
    private func updateExportText() {
        switch selectedFormat {
        case .svg:
            exportText = VectorExporter.exportToSVG(glyph.paths)
        case .pdf, .eps, .ai:
            exportText = "Export to \(selectedFormat.rawValue) not yet implemented"
        case .clipboard:
            exportText = "Use 'Copy to Clipboard' button"
        }
    }
    
    // MARK: - Path Operations
    
    private func simplifyPaths() {
        for path in glyph.paths {
            var simplifiedPoints: [PathPoint] = []
            var i = 0
            
            while i < path.points.count {
                let currentPoint = path.points[i]
                simplifiedPoints.append(currentPoint)
                
                var j = i + 1
                while j < path.points.count {
                    let nextPoint = path.points[j]
                    let distance = sqrt(pow(currentPoint.x - nextPoint.x, 2) + pow(currentPoint.y - nextPoint.y, 2))
                    if distance > 5 {
                        break
                    }
                    j += 1
                }
                i = j
            }
            
            path.points = simplifiedPoints
        }
    }
    
    private func smoothPaths() {
        for path in glyph.paths {
            for point in path.points {
                if point.type == .corner {
                    point.type = .curve
                    point.controlInX = -10
                    point.controlInY = 0
                    point.controlOutX = 10
                    point.controlOutY = 0
                }
            }
        }
    }
    
    private func reversePaths() {
        for path in glyph.paths {
            path.points.reverse()
            for point in path.points {
                let tempInX = point.controlInX
                let tempInY = point.controlInY
                point.controlInX = point.controlOutX
                point.controlInY = point.controlOutY
                point.controlOutX = tempInX
                point.controlOutY = tempInY
            }
        }
    }
    
    private func optimizePaths() {
        for path in glyph.paths {
            var optimizedPoints: [PathPoint] = []
            var lastPoint: PathPoint?
            
            for point in path.points {
                if let last = lastPoint {
                    let distance = sqrt(pow(point.x - last.x, 2) + pow(point.y - last.y, 2))
                    if distance > 1 {
                        optimizedPoints.append(point)
                        lastPoint = point
                    }
                } else {
                    optimizedPoints.append(point)
                    lastPoint = point
                }
            }
            
            path.points = optimizedPoints
        }
    }
}

// MARK: - Import Dialog

struct ImportDialogView: View {
    @Binding var isPresented: Bool
    @Binding var importText: String
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Vector Data")
                .font(.headline)
            
            Text("Paste SVG path data or other vector format:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $importText)
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Import") {
                    onImport()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// MARK: - Export Dialog

struct ExportDialogView: View {
    @Binding var isPresented: Bool
    @Binding var exportText: String
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Vector Data")
                .font(.headline)
            
            Text("Copy the generated vector data:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $exportText)
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Copy") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(exportText, forType: .string)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview {
    VectorImportExportView(glyph: Glyph(character: "A"))
        .frame(width: 300, height: 500)
}
