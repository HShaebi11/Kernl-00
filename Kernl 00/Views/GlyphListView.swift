//
//  GlyphListView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct GlyphListView: View {
    @ObservedObject var fontDocument: FontDocument
    @State private var searchText = ""
    
    var filteredGlyphs: [Glyph] {
        if searchText.isEmpty {
            return fontDocument.glyphs
        } else {
            return fontDocument.glyphs.filter { glyph in
                String(glyph.character).localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Glyphs")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // Add new glyph action
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search glyphs...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            Divider()
            
            // Glyph list
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 4)
                ], spacing: 4) {
                    ForEach(filteredGlyphs) { glyph in
                        GlyphThumbnailView(
                            glyph: glyph,
                            isSelected: fontDocument.selectedGlyph?.id == glyph.id
                        ) {
                            fontDocument.selectGlyph(glyph)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct GlyphThumbnailView: View {
    @ObservedObject var glyph: Glyph
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Glyph preview
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                    
                    // Simple glyph representation
                    Text(String(glyph.character))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 50, height: 50)
                
                // Character label
                Text(String(glyph.character))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GlyphListView(fontDocument: FontDocument())
        .frame(width: 250, height: 600)
}
