//
//  ToolbarView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct ToolbarView: View {
    @ObservedObject var fontDocument: FontDocument
    @State private var selectedTool: EditorTool = .select
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool selection
            HStack(spacing: 8) {
                ToolButton(
                    tool: .select,
                    icon: "cursorarrow",
                    isSelected: selectedTool == .select
                ) {
                    selectedTool = .select
                }
                
                ToolButton(
                    tool: .pen,
                    icon: "pencil",
                    isSelected: selectedTool == .pen
                ) {
                    selectedTool = .pen
                }
                
                ToolButton(
                    tool: .rectangle,
                    icon: "rectangle",
                    isSelected: selectedTool == .rectangle
                ) {
                    selectedTool = .rectangle
                }
                
                ToolButton(
                    tool: .circle,
                    icon: "circle",
                    isSelected: selectedTool == .circle
                ) {
                    selectedTool = .circle
                }
            }
            
            Divider()
                .frame(height: 20)
            
            // Font info
            HStack(spacing: 12) {
                Text("Font:")
                    .foregroundColor(.secondary)
                Text(fontDocument.fontName)
                    .fontWeight(.medium)
                
                Text("Glyphs:")
                    .foregroundColor(.secondary)
                Text("\(fontDocument.glyphs.count)")
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button("Export") {
                    // Export font action
                }
                .buttonStyle(.bordered)
                
                Button("Import") {
                    // Import font action
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ToolButton: View {
    let tool: EditorTool
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tool.rawValue.capitalized)
    }
}

enum EditorTool: String, CaseIterable {
    case select = "Select"
    case pen = "Pen"
    case rectangle = "Rectangle"
    case circle = "Circle"
}

#Preview {
    ToolbarView(fontDocument: FontDocument())
        .frame(height: 44)
}
