//
//  OpenTypeEditorView.swift
//  Kernl 00
//
//  Created by Hamza Shaebi on 30/09/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct OpenTypeEditorView: View {
    @StateObject private var featureManager = FeatureManager()
    @State private var selectedFeature: OpenTypeFeature?
    @State private var showAddFeature = false
    @State private var showFeatureCode = false
    @State private var generatedCode = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OpenType Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Feature List
            ScrollView {
                ForEach(featureManager.features) { feature in
                    FeatureRow(feature: feature)
                        .onTapGesture {
                            selectedFeature = feature
                        }
                        .padding(.vertical, 4)
                }
            }
            .frame(height: 200)
            
            // Actions
            HStack {
                Button("Add Feature") {
                    showAddFeature = true
                }
                .buttonStyle(.bordered)
                
                Button("Generate Code") {
                    generatedCode = featureManager.generateFeatureFile()
                    showFeatureCode = true
                }
                .buttonStyle(.bordered)
                
                Button("Export .fea") {
                    exportFeatureFile()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Feature Details
            if let feature = selectedFeature {
                FeatureDetailView(feature: feature, featureManager: featureManager)
            } else {
                Text("Select a feature to edit")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showAddFeature) {
            AddFeatureDialog(featureManager: featureManager, isPresented: $showAddFeature)
        }
        .sheet(isPresented: $showFeatureCode) {
            FeatureCodeView(code: generatedCode, isPresented: $showFeatureCode)
        }
    }
    
    private func exportFeatureFile() {
        let code = featureManager.generateFeatureFile()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "features.fea"
        panel.allowedContentTypes = [.plainText]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? code.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

struct FeatureRow: View {
    @ObservedObject var feature: OpenTypeFeature
    
    var body: some View {
        HStack {
            Toggle(isOn: $feature.enabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(feature.tag)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.checkbox)
            
            Spacer()
            
            Text("\(feature.rules.count) rules")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FeatureDetailView: View {
    @ObservedObject var feature: OpenTypeFeature
    @ObservedObject var featureManager: FeatureManager
    @State private var showAddRule = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature: \(feature.name) (\(feature.tag))")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Rules
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Rules")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showAddRule = true }) {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
                
                ForEach(feature.rules) { rule in
                    RuleRow(rule: rule, onDelete: {
                        feature.rules.removeAll { $0.id == rule.id }
                    })
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showAddRule) {
            AddRuleDialog(feature: feature, isPresented: $showAddRule)
        }
    }
}

struct RuleRow: View {
    @ObservedObject var rule: FeatureRule
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(rule.source) → \(rule.target)")
                    .font(.caption)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(4)
    }
}

struct AddFeatureDialog: View {
    @ObservedObject var featureManager: FeatureManager
    @Binding var isPresented: Bool
    @State private var tag = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add OpenType Feature")
                .font(.headline)
            
            TextField("Tag (4 chars)", text: $tag)
                .textFieldStyle(.roundedBorder)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add") {
                    let feature = OpenTypeFeature(tag: tag, name: name)
                    featureManager.features.append(feature)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(tag.count != 4 || name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

struct AddRuleDialog: View {
    @ObservedObject var feature: OpenTypeFeature
    @Binding var isPresented: Bool
    @State private var ruleType: RuleType = .substitution
    @State private var source = ""
    @State private var target = ""
    @State private var context = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Rule")
                .font(.headline)
            
            Picker("Type", selection: $ruleType) {
                ForEach(RuleType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            TextField("Source", text: $source)
                .textFieldStyle(.roundedBorder)
            
            TextField("Target", text: $target)
                .textFieldStyle(.roundedBorder)
            
            if ruleType == .contextual {
                TextField("Context", text: $context)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add") {
                    let rule = FeatureRule(type: ruleType, source: source, target: target)
                    rule.context = context
                    feature.rules.append(rule)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(source.isEmpty || target.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct FeatureCodeView: View {
    let code: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("OpenType Feature Code")
                .font(.headline)
            
            ScrollView {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    OpenTypeEditorView()
        .frame(width: 400, height: 600)
}
