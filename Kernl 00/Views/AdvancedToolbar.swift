//
//  AdvancedToolbar.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct AdvancedToolbar: View {
    @Binding var selectedTool: VectorTool
    @Binding var showGrid: Bool
    @Binding var showGuides: Bool
    @Binding var snapToGrid: Bool
    @Binding var zoom: Double
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onZoomFit: () -> Void
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onDelete: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool Selection
            HStack(spacing: 8) {
                ForEach(VectorTool.allCases, id: \.self) { tool in
                    AdvancedToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool
                    ) {
                        selectedTool = tool
                    }
                }
            }
            
            Divider()
                .frame(height: 20)
            
            // View Controls
            HStack(spacing: 8) {
                Toggle("Grid", isOn: $showGrid)
                    .toggleStyle(.button)
                    .buttonStyle(.borderless)
                
                Toggle("Guides", isOn: $showGuides)
                    .toggleStyle(.button)
                    .buttonStyle(.borderless)
                
                Toggle("Snap", isOn: $snapToGrid)
                    .toggleStyle(.button)
                    .buttonStyle(.borderless)
            }
            
            Divider()
                .frame(height: 20)
            
            // Zoom Controls
            HStack(spacing: 4) {
                Button(action: onZoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Text("\(Int(zoom * 100))%")
                    .frame(width: 50)
                    .font(.caption)
                
                Button(action: onZoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Button("Fit") {
                    onZoomFit()
                }
                .buttonStyle(.borderless)
            }
            
            Spacer()
            
            // Edit Operations
            HStack(spacing: 8) {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                
                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .buttonStyle(.borderless)
                
                Divider()
                    .frame(height: 20)
                
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                
                Button(action: onPaste) {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct AdvancedToolButton: View {
    let tool: VectorTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: toolIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tool.rawValue)
    }
    
    private var toolIcon: String {
        switch tool {
        case .select:
            return "cursorarrow"
        case .pen:
            return "pencil"
        case .move:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .delete:
            return "trash"
        case .rectangle:
            return "rectangle"
        case .circle:
            return "circle"
        case .path:
            return "path"
        case .importExport:
            return "square.and.arrow.up.on.square"
        }
    }
}

#Preview {
    AdvancedToolbar(
        selectedTool: .constant(.select),
        showGrid: .constant(true),
        showGuides: .constant(true),
        snapToGrid: .constant(true),
        zoom: .constant(1.0),
        onZoomIn: {},
        onZoomOut: {},
        onZoomFit: {},
        onCopy: {},
        onPaste: {},
        onDelete: {},
        onUndo: {},
        onRedo: {}
    )
    .frame(height: 44)
}
