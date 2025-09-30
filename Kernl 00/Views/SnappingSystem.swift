//
//  SnappingSystem.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct SnappingSystem {
    var enabled: Bool = true
    var snapToGrid: Bool = true
    var snapToGuides: Bool = true
    var snapToPoints: Bool = true
    var tolerance: Double = 10.0
    var gridSize: Double = 50.0
    
    // Guide lines
    var horizontalGuides: [Double] = []
    var verticalGuides: [Double] = []
    
    // Snap a point to nearest target
    func snap(_ point: CGPoint, in glyph: Glyph, fontMetrics: FontMetrics) -> CGPoint {
        guard enabled else { return point }
        
        var snapped = point
        
        // Snap to grid
        if snapToGrid {
            snapped.x = round(snapped.x / gridSize) * gridSize
            snapped.y = round(snapped.y / gridSize) * gridSize
        }
        
        // Snap to font metrics
        if snapToGuides {
            let metrics = [
                fontMetrics.baseline,
                fontMetrics.xHeight,
                fontMetrics.capHeight,
                fontMetrics.ascender,
                fontMetrics.descender
            ]
            
            for metric in metrics {
                if abs(snapped.y - metric) < tolerance {
                    snapped.y = metric
                    break
                }
            }
            
            // Snap to custom guides
            for guide in horizontalGuides {
                if abs(snapped.y - guide) < tolerance {
                    snapped.y = guide
                    break
                }
            }
            
            for guide in verticalGuides {
                if abs(snapped.x - guide) < tolerance {
                    snapped.x = guide
                    break
                }
            }
        }
        
        // Snap to other points
        if snapToPoints {
            for path in glyph.paths {
                for otherPoint in path.points {
                    let distance = sqrt(
                        pow(snapped.x - otherPoint.x, 2) +
                        pow(snapped.y - otherPoint.y, 2)
                    )
                    
                    if distance < tolerance {
                        snapped.x = otherPoint.x
                        snapped.y = otherPoint.y
                        break
                    }
                }
            }
        }
        
        return snapped
    }
    
    // Visual feedback for snap targets
    func getSnapIndicators(for point: CGPoint, in glyph: Glyph, fontMetrics: FontMetrics) -> [SnapIndicator] {
        var indicators: [SnapIndicator] = []
        
        // Grid snap indicators
        if snapToGrid {
            let gridX = round(point.x / gridSize) * gridSize
            let gridY = round(point.y / gridSize) * gridSize
            
            if abs(point.x - gridX) < tolerance {
                indicators.append(SnapIndicator(type: .vertical, position: gridX))
            }
            if abs(point.y - gridY) < tolerance {
                indicators.append(SnapIndicator(type: .horizontal, position: gridY))
            }
        }
        
        // Metrics snap indicators
        if snapToGuides {
            let metrics = [
                ("baseline", fontMetrics.baseline),
                ("x-height", fontMetrics.xHeight),
                ("cap-height", fontMetrics.capHeight),
                ("ascender", fontMetrics.ascender),
                ("descender", fontMetrics.descender)
            ]
            
            for (name, value) in metrics {
                if abs(point.y - value) < tolerance {
                    indicators.append(SnapIndicator(
                        type: .horizontal,
                        position: value,
                        label: name
                    ))
                }
            }
        }
        
        return indicators
    }
}

struct SnapIndicator: Identifiable {
    let id = UUID()
    let type: SnapType
    let position: Double
    var label: String?
}

enum SnapType {
    case horizontal
    case vertical
    case point
}

struct SnapIndicatorView: View {
    let indicator: SnapIndicator
    let canvasSize: CGSize
    
    var body: some View {
        ZStack {
            switch indicator.type {
            case .horizontal:
                Path { path in
                    path.move(to: CGPoint(x: 0, y: indicator.position))
                    path.addLine(to: CGPoint(x: canvasSize.width, y: indicator.position))
                }
                .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                
            case .vertical:
                Path { path in
                    path.move(to: CGPoint(x: indicator.position, y: 0))
                    path.addLine(to: CGPoint(x: indicator.position, y: canvasSize.height))
                }
                .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                
            case .point:
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .position(x: indicator.position, y: indicator.position)
            }
            
            if let label = indicator.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .position(
                        x: indicator.type == .horizontal ? 50 : indicator.position,
                        y: indicator.type == .horizontal ? indicator.position : 20
                    )
            }
        }
    }
}
