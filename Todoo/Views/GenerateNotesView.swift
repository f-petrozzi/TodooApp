//
//  GenerateNotesView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//

import SwiftUI

struct GenerateNotesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var prompt: String = ""
    @State private var responseText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @ObservedObject var viewModel: NoteViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $prompt)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    .frame(height: 150)
                    .padding(.horizontal)
                
                Button(action: generateNotes) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Generate")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .buttonStyle(.borderedProminent)
                
                ScrollView {
                    Text(responseText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("AI Note Generator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateNotes() {
        guard !prompt.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        responseText = ""
        errorMessage = nil
        
        AIService.shared.generateNotes(from: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let result = result else {
                    errorMessage = "Failed to generate notes."
                    return
                }
                
                responseText = result //show response
                
                if let json = AIService.shared.extractFirstJSONArray(from: result),
                    let notes = AIService.shared.parseNotes(from: json) {
                    for note in notes {
                        viewModel.addNote(title: note.title, description: note.description, date: note.date)
                    }
                    dismiss()
                } else {
                    errorMessage = "Failed to parse notes."
                }
            }
        }
    }
}
