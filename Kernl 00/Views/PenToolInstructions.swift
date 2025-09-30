//
//  PenToolInstructions.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct PenToolInstructions: View {
    @Binding var showInstructions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pen Tool Guide")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showInstructions = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Usage
                    InstructionSection(
                        icon: "hand.tap",
                        title: "Creating Points",
                        items: [
                            "Click once → Corner point (sharp angle)",
                            "Click + drag → Smooth point with curve handles",
                            "Drag direction/length controls the curve"
                        ]
                    )
                    
                    // Modifiers
                    InstructionSection(
                        icon: "command",
                        title: "Modifier Keys",
                        items: [
                            "⌥ Option + drag → Break handle symmetry (independent handles)",
                            "⇧ Shift → Constrain handles to 45° angles",
                            "Space + drag → Reposition point before placing",
                            "⌘ Cmd (future) → Quick switch to Direct Select"
                        ]
                    )
                    
                    // Path Control
                    InstructionSection(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Path Control",
                        items: [
                            "Click near first point → Close path automatically",
                            "Return/Enter → Finish path (leave open)",
                            "Escape → Cancel current path"
                        ]
                    )
                    
                    // Point Types
                    InstructionSection(
                        icon: "circle.grid.cross",
                        title: "Point Types",
                        items: [
                            "🔴 Red = Corner (sharp)",
                            "🟢 Green = Smooth (curve)",
                            "🟠 Orange = Control (off-path)",
                            "🟣 Purple = Auto (automatic smooth)"
                        ]
                    )
                    
                    // Handle Colors
                    InstructionSection(
                        icon: "paintbrush.pointed",
                        title: "Handle Colors",
                        items: [
                            "Blue handles = Symmetric/Asymmetric constraint",
                            "Orange handles = Broken (independent)",
                            "Option key toggles between modes"
                        ]
                    )
                    
                    // Tips
                    InstructionSection(
                        icon: "lightbulb",
                        title: "Pro Tips",
                        items: [
                            "Use fewer points for smoother curves",
                            "Place points at curve extremes (top/bottom/sides)",
                            "Adjust handles after placing for fine control",
                            "Switch to Edit mode to modify existing points"
                        ]
                    )
                }
            }
            
            Button("Got it!") {
                showInstructions = false
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

struct InstructionSection: View {
    let icon: String
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(item)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 38)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    PenToolInstructions(showInstructions: .constant(true))
}
