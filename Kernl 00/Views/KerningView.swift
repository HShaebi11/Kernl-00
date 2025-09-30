//
//  KerningView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct KerningView: View {
    @ObservedObject var fontDocument: FontDocument
    @State private var selectedPair: KerningPair?
    @State private var leftGlyph: Character = "A"
    @State private var rightGlyph: Character = "V"
    @State private var kerningValue: Double = 0
    @State private var showAddPair = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Kerning Pairs")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Pair") {
                    showAddPair.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            // Add new pair section
            if showAddPair {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Kerning Pair")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Left Glyph")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Left", text: Binding(
                                get: { String(leftGlyph) },
                                set: { leftGlyph = $0.first ?? "A" }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Right Glyph")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Right", text: Binding(
                                get: { String(rightGlyph) },
                                set: { rightGlyph = $0.first ?? "V" }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kerning")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                TextField("Value", value: $kerningValue, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Text("units")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Add") {
                            addKerningPair()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Kerning pairs list
            if fontDocument.kerningPairs.isEmpty {
                VStack {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No kerning pairs")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add kerning pairs to adjust spacing between specific character combinations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(fontDocument.kerningPairs) { pair in
                            KerningPairRow(
                                pair: pair,
                                isSelected: selectedPair?.id == pair.id,
                                onSelect: {
                                    selectedPair = pair
                                },
                                onDelete: {
                                    deleteKerningPair(pair)
                                },
                                onValueChange: { newValue in
                                    updateKerningPair(pair, value: newValue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }
    
    private func addKerningPair() {
        let newPair = KerningPair(left: leftGlyph, right: rightGlyph, value: kerningValue)
        fontDocument.kerningPairs.append(newPair)
        showAddPair = false
        leftGlyph = "A"
        rightGlyph = "V"
        kerningValue = 0
    }
    
    private func deleteKerningPair(_ pair: KerningPair) {
        fontDocument.kerningPairs.removeAll { $0.id == pair.id }
        if selectedPair?.id == pair.id {
            selectedPair = nil
        }
    }
    
    private func updateKerningPair(_ pair: KerningPair, value: Double) {
        if let index = fontDocument.kerningPairs.firstIndex(where: { $0.id == pair.id }) {
            fontDocument.kerningPairs[index].kerningValue = value
        }
    }
}

struct KerningPairRow: View {
    @ObservedObject var pair: KerningPair
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onValueChange: (Double) -> Void
    
    var body: some View {
        HStack {
            // Glyph pair display
            HStack(spacing: 4) {
                Text(String(pair.leftGlyph))
                    .font(.title2)
                    .fontWeight(.medium)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Text("+")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(pair.rightGlyph))
                    .font(.title2)
                    .fontWeight(.medium)
                    .frame(width: 30, height: 30)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Kerning value
            HStack(spacing: 8) {
                Text("Kerning:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Value", value: Binding(
                    get: { pair.kerningValue },
                    set: { onValueChange($0) }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                
                Text("units")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    KerningView(fontDocument: FontDocument())
        .frame(width: 400, height: 500)
}
