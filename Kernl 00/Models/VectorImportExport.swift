//
//  VectorImportExport.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import Foundation
import SwiftUI

// MARK: - Vector Format Support

enum VectorFormat: String, CaseIterable, Codable {
    case svg = "SVG"
    case pdf = "PDF"
    case eps = "EPS"
    case ai = "AI"
    case clipboard = "Clipboard"
}

// MARK: - Vector Data Structure

struct VectorData: Codable {
    let format: VectorFormat
    let data: Data
    let metadata: VectorMetadata
}

struct VectorMetadata: Codable {
    let width: Double
    let height: Double
    let units: String
    let created: Date
    let version: String
}

// MARK: - SVG Parser

class SVGParser {
    static func parse(_ svgString: String) -> [GlyphPath] {
        var paths: [GlyphPath] = []
        
        // Simple SVG path parser - looks for <path d="..."> elements
        let pathRegex = #"<path[^>]*d="([^"]*)"[^>]*>"#
        let matches = svgString.matches(of: pathRegex)
        
        for match in matches {
            if match.output.count > 1 {
                let pathData = String(match.output[1].substring ?? "")
                if let glyphPath = parsePathData(pathData) {
                    paths.append(glyphPath)
                }
            }
        }
        
        return paths
    }
    
    private static func parsePathData(_ pathData: String) -> GlyphPath? {
        let glyphPath = GlyphPath()
        let commands = pathData.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero
        var i = 0
        
        while i < commands.count {
            let command = commands[i]
            let commandType = command.first?.uppercased() ?? ""
            
            switch commandType {
            case "M": // Move to
                if i + 2 < commands.count,
                   let x = Double(commands[i + 1]),
                   let y = Double(commands[i + 2]) {
                    currentPoint = CGPoint(x: x, y: y)
                    startPoint = currentPoint
                    i += 3
                } else {
                    i += 1
                }
                
            case "L": // Line to
                if i + 2 < commands.count,
                   let x = Double(commands[i + 1]),
                   let y = Double(commands[i + 2]) {
                    let point = PathPoint(x: x, y: y, type: .corner)
                    glyphPath.points.append(point)
                    currentPoint = CGPoint(x: x, y: y)
                    i += 3
                } else {
                    i += 1
                }
                
            case "C": // Cubic Bezier curve
                if i + 6 < commands.count,
                   let x1 = Double(commands[i + 1]),
                   let y1 = Double(commands[i + 2]),
                   let x2 = Double(commands[i + 3]),
                   let y2 = Double(commands[i + 4]),
                   let x = Double(commands[i + 5]),
                   let y = Double(commands[i + 6]) {
                    
                    let point = PathPoint(x: x, y: y, type: .curve)
                    point.controlInX = x2 - x
                    point.controlInY = y2 - y
                    point.controlOutX = x1 - currentPoint.x
                    point.controlOutY = y1 - currentPoint.y
                    glyphPath.points.append(point)
                    currentPoint = CGPoint(x: x, y: y)
                    i += 7
                } else {
                    i += 1
                }
                
            case "Z": // Close path
                glyphPath.isClosed = true
                i += 1
                
            default:
                i += 1
            }
        }
        
        return glyphPath.points.isEmpty ? nil : glyphPath
    }
}

// MARK: - Vector Exporter

class VectorExporter {
    static func exportToSVG(_ paths: [GlyphPath]) -> String {
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
        """
        
        for path in paths {
            svg += "\n  <path d=\""
            svg += generatePathData(path)
            svg += "\" fill=\"black\" stroke=\"none\"/>"
        }
        
        svg += "\n</svg>"
        return svg
    }
    
    private static func generatePathData(_ path: GlyphPath) -> String {
        guard !path.points.isEmpty else { return "" }
        
        var pathData = ""
        let firstPoint = path.points[0]
        pathData += "M \(firstPoint.x) \(firstPoint.y) "
        
        for i in 1..<path.points.count {
            let currentPoint = path.points[i]
            let previousPoint = path.points[i - 1]
            
            if currentPoint.type == .curve {
                let control1X = previousPoint.x + previousPoint.controlOutX
                let control1Y = previousPoint.y + previousPoint.controlOutY
                let control2X = currentPoint.x + currentPoint.controlInX
                let control2Y = currentPoint.y + currentPoint.controlInY
                
                pathData += "C \(control1X) \(control1Y) \(control2X) \(control2Y) \(currentPoint.x) \(currentPoint.y) "
            } else {
                pathData += "L \(currentPoint.x) \(currentPoint.y) "
            }
        }
        
        if path.isClosed {
            pathData += "Z"
        }
        
        return pathData
    }
}

// MARK: - Clipboard Manager

class ClipboardManager {
    static func copyPaths(_ paths: [GlyphPath]) {
        let svgData = VectorExporter.exportToSVG(paths)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(svgData, forType: .string)
    }
    
    static func pastePaths() -> [GlyphPath] {
        let pasteboard = NSPasteboard.general
        
        if let svgString = pasteboard.string(forType: .string) {
            return SVGParser.parse(svgString)
        }
        
        return []
    }
    
    static func hasVectorData() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)?.contains("<svg") == true ||
               pasteboard.string(forType: .string)?.contains("path") == true
    }
}

// MARK: - String Extensions

extension String {
    func matches(of regex: String) -> [Regex<AnyRegexOutput>.Match] {
        do {
            let regex = try Regex(regex)
            return Array(self.matches(of: regex))
        } catch {
            return []
        }
    }
}
