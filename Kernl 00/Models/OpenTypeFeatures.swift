//
//  OpenTypeFeatures.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import Combine

// MARK: - OpenType Feature Model

class OpenTypeFeature: ObservableObject, Identifiable {
    let id = UUID()
    @Published var tag: String  // 4-character tag (e.g., "liga", "kern", "smcp")
    @Published var name: String
    @Published var enabled: Bool = true
    @Published var rules: [FeatureRule] = []
    
    init(tag: String, name: String) {
        self.tag = tag
        self.name = name
    }
}

// MARK: - Feature Rule

class FeatureRule: ObservableObject, Identifiable {
    let id = UUID()
    @Published var type: RuleType
    @Published var source: String  // Glyph or sequence
    @Published var target: String  // Replacement glyph or sequence
    @Published var context: String = ""  // Contextual conditions
    
    init(type: RuleType, source: String, target: String) {
        self.type = type
        self.source = source
        self.target = target
    }
    
    // Convert to OpenType feature code
    func toFeatureCode() -> String {
        switch type {
        case .substitution:
            if context.isEmpty {
                return "sub \(source) by \(target);"
            } else {
                return "sub \(context) \(source)' by \(target);"
            }
        case .ligature:
            return "sub \(source) by \(target);"
        case .positioning:
            return "pos \(source) <\(target)>;"
        case .contextual:
            return "sub \(context) \(source)' by \(target);"
        }
    }
}

enum RuleType: String, CaseIterable {
    case substitution = "Substitution"
    case ligature = "Ligature"
    case positioning = "Positioning"
    case contextual = "Contextual"
}

// MARK: - Feature Classes

class FeatureClass: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var glyphs: Set<Character> = []
    
    init(name: String) {
        self.name = name
    }
    
    func toFeatureCode() -> String {
        let glyphList = glyphs.map { String($0) }.joined(separator: " ")
        return "@\(name) = [\(glyphList)];"
    }
}

// MARK: - Common Features

extension OpenTypeFeature {
    
    static func standardLigatures() -> OpenTypeFeature {
        let feature = OpenTypeFeature(tag: "liga", name: "Standard Ligatures")
        feature.rules = [
            FeatureRule(type: .ligature, source: "f f", target: "ff"),
            FeatureRule(type: .ligature, source: "f i", target: "fi"),
            FeatureRule(type: .ligature, source: "f l", target: "fl"),
            FeatureRule(type: .ligature, source: "f f i", target: "ffi"),
            FeatureRule(type: .ligature, source: "f f l", target: "ffl")
        ]
        return feature
    }
    
    static func smallCaps() -> OpenTypeFeature {
        let feature = OpenTypeFeature(tag: "smcp", name: "Small Capitals")
        // Rules would map lowercase to small caps variants
        return feature
    }
    
    static func oldStyleFigures() -> OpenTypeFeature {
        let feature = OpenTypeFeature(tag: "onum", name: "Old Style Figures")
        feature.rules = [
            FeatureRule(type: .substitution, source: "zero", target: "zero.oldstyle"),
            FeatureRule(type: .substitution, source: "one", target: "one.oldstyle"),
            FeatureRule(type: .substitution, source: "two", target: "two.oldstyle"),
            FeatureRule(type: .substitution, source: "three", target: "three.oldstyle"),
            FeatureRule(type: .substitution, source: "four", target: "four.oldstyle"),
            FeatureRule(type: .substitution, source: "five", target: "five.oldstyle"),
            FeatureRule(type: .substitution, source: "six", target: "six.oldstyle"),
            FeatureRule(type: .substitution, source: "seven", target: "seven.oldstyle"),
            FeatureRule(type: .substitution, source: "eight", target: "eight.oldstyle"),
            FeatureRule(type: .substitution, source: "nine", target: "nine.oldstyle")
        ]
        return feature
    }
    
    static func fractions() -> OpenTypeFeature {
        let feature = OpenTypeFeature(tag: "frac", name: "Fractions")
        feature.rules = [
            FeatureRule(type: .substitution, source: "1 slash 2", target: "onehalf"),
            FeatureRule(type: .substitution, source: "1 slash 4", target: "onequarter"),
            FeatureRule(type: .substitution, source: "3 slash 4", target: "threequarters")
        ]
        return feature
    }
}

// MARK: - Feature Manager

class FeatureManager: ObservableObject {
    @Published var features: [OpenTypeFeature] = []
    @Published var classes: [FeatureClass] = []
    
    init() {
        loadStandardFeatures()
    }
    
    func loadStandardFeatures() {
        features = [
            .standardLigatures(),
            .smallCaps(),
            .oldStyleFigures(),
            .fractions()
        ]
    }
    
    func addClass(_ featureClass: FeatureClass) {
        classes.append(featureClass)
    }
    
    func generateFeatureFile() -> String {
        var code = "# OpenType Feature File\n# Generated by Kernl Font Editor\n\n"
        
        // Add classes
        for featureClass in classes {
            code += featureClass.toFeatureCode() + "\n"
        }
        code += "\n"
        
        // Add features
        for feature in features where feature.enabled {
            code += "feature \(feature.tag) {\n"
            for rule in feature.rules {
                code += "    \(rule.toFeatureCode())\n"
            }
            code += "} \(feature.tag);\n\n"
        }
        
        return code
    }
}
