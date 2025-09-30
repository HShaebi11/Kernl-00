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
        // Start with empty glyph - no placeholder paths
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
    @Published var handleConstraint: HandleConstraint = .symmetric
    @Published var controlInX: Double = 0
    @Published var controlInY: Double = 0
    @Published var controlOutX: Double = 0
    @Published var controlOutY: Double = 0
    @Published var isSelected: Bool = false

    init(x: Double, y: Double, type: PointType) {
        self.x = x
        self.y = y
        self.type = type
    }
    
    // Apply handle constraints when moving handles
    func updateInHandle(dx: Double, dy: Double) {
        controlInX = dx
        controlInY = dy
        
        switch handleConstraint {
        case .symmetric:
            // Mirror to out handle with same length
            controlOutX = -dx
            controlOutY = -dy
        case .asymmetric:
            // Mirror direction but keep out handle length
            let outLength = sqrt(controlOutX * controlOutX + controlOutY * controlOutY)
            let inLength = sqrt(dx * dx + dy * dy)
            if inLength > 0 {
                let scale = outLength / inLength
                controlOutX = -dx * scale
                controlOutY = -dy * scale
            }
        case .broken:
            // Independent - do nothing
            break
        }
    }
    
    func updateOutHandle(dx: Double, dy: Double) {
        controlOutX = dx
        controlOutY = dy
        
        switch handleConstraint {
        case .symmetric:
            // Mirror to in handle with same length
            controlInX = -dx
            controlInY = -dy
        case .asymmetric:
            // Mirror direction but keep in handle length
            let inLength = sqrt(controlInX * controlInX + controlInY * controlInY)
            let outLength = sqrt(dx * dx + dy * dy)
            if outLength > 0 {
                let scale = inLength / outLength
                controlInX = -dx * scale
                controlInY = -dy * scale
            }
        case .broken:
            // Independent - do nothing
            break
        }
    }
}

enum PointType: String, CaseIterable, Identifiable {
    case corner      // Sharp corner, no curve
    case curve       // Smooth curve
    case control     // Control point (not on path)
    case auto        // Automatically smooth
    var id: String { self.rawValue }
}

// Handle constraint modes
enum HandleConstraint: String, CaseIterable, Identifiable {
    case symmetric   // Both handles same length, opposite direction
    case asymmetric  // Opposite direction, different lengths
    case broken      // Independent handles
    var id: String { self.rawValue }
}

// MARK: - Font Metrics
class FontMetrics: ObservableObject {
    @Published var unitsPerEm: Double = 1000
    @Published var ascender: Double = 800
    @Published var descender: Double = -200
    @Published var capHeight: Double = 700
    @Published var xHeight: Double = 500
    @Published var baseline: Double = 0
}

// MARK: - Kerning Pair
class KerningPair: ObservableObject, Identifiable {
    let id = UUID()
    @Published var leftGlyph: Character
    @Published var rightGlyph: Character
    @Published var kerningValue: Double
    
    init(left: Character, right: Character, value: Double) {
        self.leftGlyph = left
        self.rightGlyph = right
        self.kerningValue = value
    }
}
