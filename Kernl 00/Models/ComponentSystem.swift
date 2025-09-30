//
//  ComponentSystem.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Component Model

class GlyphComponent: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var baseGlyph: Character?  // Reference to source glyph
    @Published var paths: [GlyphPath]     // The actual paths (can be from baseGlyph or custom)
    @Published var transform: ComponentTransform = ComponentTransform()
    @Published var isReference: Bool = true  // True if linked to baseGlyph, false if decomposed
    
    init(name: String, paths: [GlyphPath] = [], baseGlyph: Character? = nil) {
        self.name = name
        self.paths = paths
        self.baseGlyph = baseGlyph
    }
    
    // Get effective paths (from base glyph if reference, or own paths if decomposed)
    func getEffectivePaths(from fontDocument: FontDocument) -> [GlyphPath] {
        if isReference, let baseChar = baseGlyph,
           let baseGlyph = fontDocument.glyphs.first(where: { $0.character == baseChar }) {
            return baseGlyph.paths
        }
        return paths
    }
    
    // Decompose the component (break link to base glyph)
    func decompose(from fontDocument: FontDocument) {
        if isReference, let baseChar = baseGlyph,
           let baseGlyph = fontDocument.glyphs.first(where: { $0.character == baseChar }) {
            // Copy paths from base glyph
            self.paths = baseGlyph.paths.map { path in
                let newPath = GlyphPath()
                newPath.isClosed = path.isClosed
                newPath.points = path.points.map { point in
                    let newPoint = PathPoint(x: point.x, y: point.y, type: point.type)
                    newPoint.controlInX = point.controlInX
                    newPoint.controlInY = point.controlInY
                    newPoint.controlOutX = point.controlOutX
                    newPoint.controlOutY = point.controlOutY
                    newPoint.handleConstraint = point.handleConstraint
                    return newPoint
                }
                return newPath
            }
            isReference = false
        }
    }
}

// MARK: - Component Transform

class ComponentTransform: ObservableObject {
    @Published var offsetX: Double = 0
    @Published var offsetY: Double = 0
    @Published var scaleX: Double = 1.0
    @Published var scaleY: Double = 1.0
    @Published var rotation: Double = 0.0  // in degrees
    @Published var flipX: Bool = false
    @Published var flipY: Bool = false
    
    func apply(to point: CGPoint) -> CGPoint {
        var result = point
        
        // Scale
        result.x *= scaleX * (flipX ? -1 : 1)
        result.y *= scaleY * (flipY ? -1 : 1)
        
        // Rotate
        if rotation != 0 {
            let radians = rotation * .pi / 180.0
            let cos = Darwin.cos(radians)
            let sin = Darwin.sin(radians)
            let x = result.x * cos - result.y * sin
            let y = result.x * sin + result.y * cos
            result = CGPoint(x: x, y: y)
        }
        
        // Translate
        result.x += offsetX
        result.y += offsetY
        
        return result
    }
    
    func copy() -> ComponentTransform {
        let transform = ComponentTransform()
        transform.offsetX = offsetX
        transform.offsetY = offsetY
        transform.scaleX = scaleX
        transform.scaleY = scaleY
        transform.rotation = rotation
        transform.flipX = flipX
        transform.flipY = flipY
        return transform
    }
}

// MARK: - Component Library

class ComponentLibrary: ObservableObject {
    @Published var components: [GlyphComponent] = []
    
    // Common diacritics and marks
    func addStandardComponents() {
        // Add common components (these would be pre-defined or user-created)
        let acute = GlyphComponent(name: "acute", paths: [])
        let grave = GlyphComponent(name: "grave", paths: [])
        let circumflex = GlyphComponent(name: "circumflex", paths: [])
        let tilde = GlyphComponent(name: "tilde", paths: [])
        let dieresis = GlyphComponent(name: "dieresis", paths: [])
        
        components.append(contentsOf: [acute, grave, circumflex, tilde, dieresis])
    }
    
    func createComponentFromGlyph(_ glyph: Glyph, name: String) -> GlyphComponent {
        let component = GlyphComponent(
            name: name,
            paths: glyph.paths,
            baseGlyph: glyph.character
        )
        components.append(component)
        return component
    }
    
    func createComponentFromSelection(paths: [GlyphPath], name: String) -> GlyphComponent {
        let component = GlyphComponent(name: name, paths: paths)
        components.append(component)
        return component
    }
}

// MARK: - Glyph Extensions for Components

extension Glyph {
    var components: [GlyphComponent] {
        get {
            // This would be stored as a property on Glyph in a real implementation
            // For now, we'll use a simple approach
            return []
        }
        set {
            // Store components
        }
    }
    
    func addComponent(_ component: GlyphComponent, at position: CGPoint) {
        let newComponent = GlyphComponent(
            name: component.name,
            paths: component.paths,
            baseGlyph: component.baseGlyph
        )
        newComponent.transform.offsetX = position.x
        newComponent.transform.offsetY = position.y
        newComponent.isReference = component.isReference
        
        // Add transformed paths to the glyph
        for path in newComponent.paths {
            let transformedPath = GlyphPath()
            transformedPath.isClosed = path.isClosed
            
            for point in path.points {
                let originalPoint = CGPoint(x: point.x, y: point.y)
                let transformedPoint = newComponent.transform.apply(to: originalPoint)
                
                let newPoint = PathPoint(x: transformedPoint.x, y: transformedPoint.y, type: point.type)
                newPoint.controlInX = point.controlInX * newComponent.transform.scaleX
                newPoint.controlInY = point.controlInY * newComponent.transform.scaleY
                newPoint.controlOutX = point.controlOutX * newComponent.transform.scaleX
                newPoint.controlOutY = point.controlOutY * newComponent.transform.scaleY
                newPoint.handleConstraint = point.handleConstraint
                
                transformedPath.points.append(newPoint)
            }
            
            paths.append(transformedPath)
        }
    }
}
