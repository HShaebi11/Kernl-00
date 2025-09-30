//
//  ComponentLibraryView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI

struct ComponentLibraryView: View {
    @ObservedObject var glyph: Glyph
    @ObservedObject var fontDocument: FontDocument
    @StateObject private var library = ComponentLibrary()
    @State private var selectedComponent: GlyphComponent?
    @State private var showCreateDialog = false
    @State private var newComponentName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Component Library")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Component List
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(library.components) { component in
                        ComponentCell(component: component)
                            .onTapGesture {
                                selectedComponent = component
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedComponent?.id == component.id ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
            .frame(height: 200)
            
            // Actions
            HStack {
                Button("Add to Glyph") {
                    if let component = selectedComponent {
                        glyph.addComponent(component, at: CGPoint(x: 400, y: 400))
                    }
                }
                .disabled(selectedComponent == nil)
                .buttonStyle(.bordered)
                
                Button("Create from Selection") {
                    showCreateDialog = true
                }
                .buttonStyle(.bordered)
                
                Button("Create from Glyph") {
                    createFromGlyph()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Component Details
            if let component = selectedComponent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Component: \(component.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let baseGlyph = component.baseGlyph {
                        Text("Base: \(String(baseGlyph))")
                            .font(.caption)
                    }
                    
                    Toggle("Reference", isOn: Binding(
                        get: { component.isReference },
                        set: { _ in }
                    ))
                    .disabled(true)
                    
                    Button(component.isReference ? "Decompose" : "Decomposed") {
                        component.decompose(from: fontDocument)
                    }
                    .disabled(!component.isReference)
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showCreateDialog) {
            CreateComponentDialog(
                componentName: $newComponentName,
                onCreate: {
                    createComponentFromSelection()
                    showCreateDialog = false
                },
                onCancel: {
                    showCreateDialog = false
                }
            )
        }
        .onAppear {
            library.addStandardComponents()
        }
    }
    
    private func createFromGlyph() {
        if let selectedGlyph = fontDocument.selectedGlyph {
            let component = library.createComponentFromGlyph(
                selectedGlyph,
                name: String(selectedGlyph.character)
            )
            selectedComponent = component
        }
    }
    
    private func createComponentFromSelection() {
        // This would create from selected paths in the editor
        // For now, create from all paths
        let component = library.createComponentFromSelection(
            paths: glyph.paths,
            name: newComponentName
        )
        selectedComponent = component
        newComponentName = ""
    }
}

struct ComponentCell: View {
    @ObservedObject var component: GlyphComponent
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                
                // Preview of component (simplified)
                Text(component.name.prefix(2))
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            Text(component.name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

struct CreateComponentDialog: View {
    @Binding var componentName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Component")
                .font(.headline)
            
            TextField("Component Name", text: $componentName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(componentName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

#Preview {
    ComponentLibraryView(
        glyph: Glyph(character: "A"),
        fontDocument: FontDocument()
    )
    .frame(width: 400, height: 500)
}
