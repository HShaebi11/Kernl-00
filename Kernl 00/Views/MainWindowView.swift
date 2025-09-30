//
//  MainWindowView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct MainWindowView: View {
    @StateObject private var fontDocument = FontDocument()
    
    var body: some View {
        NavigationSplitView {
            // Left sidebar - Glyph list
            GlyphListView(fontDocument: fontDocument)
                .frame(minWidth: 200, maxWidth: 300)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(fontDocument: fontDocument)
                    .frame(height: 44)
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Main editor area
                HStack(spacing: 0) {
                    // Glyph editor (center)
                    GlyphEditorView(fontDocument: fontDocument)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    // Right sidebar - Inspector
                    InspectorView(fontDocument: fontDocument)
                        .frame(minWidth: 250, maxWidth: 350)
                }
            }
        }
        .navigationTitle(fontDocument.fontName)
        .frame(minWidth: 1000, minHeight: 700)
    }
}

#Preview {
    MainWindowView()
}
