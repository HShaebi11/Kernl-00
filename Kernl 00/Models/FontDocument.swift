//
//  FontDocument.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Font Document Model
class FontDocument: ObservableObject {
    @Published var fontName: String = "Untitled Font"
    @Published var glyphs: [Glyph] = []
    @Published var selectedGlyph: Glyph?
    @Published var fontMetrics: FontMetrics = FontMetrics()
    @Published var kerningPairs: [KerningPair] = []
    
    init() {
        // Initialize with basic Latin characters
        createBasicGlyphs()
    }
    
    private func createBasicGlyphs() {
        let basicCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        for character in basicCharacters {
            let glyph = Glyph(character: character)
            glyphs.append(glyph)
        }
        selectedGlyph = glyphs.first
    }
    
    func addGlyph(character: Character) {
        let glyph = Glyph(character: character)
        glyphs.append(glyph)
    }
    
    func removeGlyph(_ glyph: Glyph) {
        glyphs.removeAll { $0.id == glyph.id }
        if selectedGlyph?.id == glyph.id {
            selectedGlyph = glyphs.first
        }
    }
    
    func selectGlyph(_ glyph: Glyph) {
        selectedGlyph = glyph
    }
}

// MARK: - Glyph Model
class Glyph: ObservableObject, Identifiable {
    let id = UUID()
    let character: Character
    @Published var paths: [GlyphPath] = []
    @Published var width: Double = 600 // Font units
    @Published var leftSideBearing: Double = 0
    @Published var rightSideBearing: Double = 0
    
    init(character: Character) {
        self.character = character
        // Create a simple placeholder path for demonstration
        createPlaceholderPath()
    }
    
    private func createPlaceholderPath() {
        // Create a simple rectangular path as placeholder
        let path = GlyphPath()
        path.addRectangle(x: 50, y: 50, width: 500, height: 700)
        paths.append(path)
    }
    
    var totalWidth: Double {
        return leftSideBearing + width + rightSideBearing
    }
}

// MARK: - Glyph Path Model
class GlyphPath: ObservableObject, Identifiable {
    let id = UUID()
    @Published var points: [PathPoint] = []
    @Published var isClosed: Bool = true
    
    init() {}
    
    func addPoint(_ point: PathPoint) {
        points.append(point)
    }
    
    func addRectangle(x: Double, y: Double, width: Double, height: Double) {
        points.removeAll()
        
        // Create rectangle with corner points
        points.append(PathPoint(x: x, y: y, type: .corner))
        points.append(PathPoint(x: x + width, y: y, type: .corner))
        points.append(PathPoint(x: x + width, y: y + height, type: .corner))
        points.append(PathPoint(x: x, y: y + height, type: .corner))
    }
    
    func addCircle(centerX: Double, centerY: Double, radius: Double) {
        points.removeAll()
        
        // Create circle with bezier control points
        let controlOffset = radius * 0.552 // Magic number for circular bezier curves
        
        points.append(PathPoint(x: centerX + radius, y: centerY, type: .curve))
        points.append(PathPoint(x: centerX + radius, y: centerY + controlOffset, type: .control))
        points.append(PathPoint(x: centerX + controlOffset, y: centerY + radius, type: .control))
        points.append(PathPoint(x: centerX, y: centerY + radius, type: .curve))
        points.append(PathPoint(x: centerX - controlOffset, y: centerY + radius, type: .control))
        points.append(PathPoint(x: centerX - radius, y: centerY + controlOffset, type: .control))
        points.append(PathPoint(x: centerX - radius, y: centerY, type: .curve))
        points.append(PathPoint(x: centerX - radius, y: centerY - controlOffset, type: .control))
        points.append(PathPoint(x: centerX - controlOffset, y: centerY - radius, type: .control))
        points.append(PathPoint(x: centerX, y: centerY - radius, type: .curve))
        points.append(PathPoint(x: centerX + controlOffset, y: centerY - radius, type: .control))
        points.append(PathPoint(x: centerX + radius, y: centerY - controlOffset, type: .control))
    }
}

// MARK: - Path Point Model
class PathPoint: ObservableObject, Identifiable {
    let id = UUID()
    @Published var x: Double
    @Published var y: Double
    @Published var type: PointType
    @Published var controlInX: Double = 0
    @Published var controlInY: Double = 0
    @Published var controlOutX: Double = 0
    @Published var controlOutY: Double = 0
    
    init(x: Double, y: Double, type: PointType) {
        self.x = x
        self.y = y
        self.type = type
    }
}

// MARK: - Point Type
enum PointType {
    case corner    // Sharp corner
    case curve     // Smooth curve
    case control   // Control point for bezier curves
}

// MARK: - Font Metrics
struct FontMetrics {
    var unitsPerEm: Double = 1000
    var ascender: Double = 800
    var descender: Double = -200
    var capHeight: Double = 700
    var xHeight: Double = 500
    var baseline: Double = 0
}

// MARK: - Kerning Pair
struct KerningPair: Identifiable {
    let id = UUID()
    let leftGlyph: Character
    let rightGlyph: Character
    var kerningValue: Double
    
    init(left: Character, right: Character, value: Double) {
        self.leftGlyph = left
        self.rightGlyph = right
        self.kerningValue = value
    }
}
