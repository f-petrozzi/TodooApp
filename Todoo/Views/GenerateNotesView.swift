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
    @State private var showSuccess: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var showToast: Bool = false
    @ObservedObject var viewModel: NoteViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    TextEditor(text: $prompt)
                        .padding(.horizontal)
                        .frame(height: 130)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                                        
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
                    .padding(.horizontal)
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding(.top)
                
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: "Added successfully!")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: showToast)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("AI Note Generator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Notes Added", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
    }
    
    private func generateNotes() {
        guard !prompt.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        AIService.shared.generateNotes(from: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let result = result else {
                    errorMessage = "Failed to generate notes."
                    return
                }
                                
                if let json = AIService.shared.extractFirstJSONArray(from: result),
                   let notes = AIService.shared.parseNotes(from: json),
                   !notes.isEmpty {
                    
                    for note in notes {
                        viewModel.addNote(title: note.title, description: note.description, date: note.date)
                    }
                    showToast = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showToast = false
                        dismiss()
                    }
                } else {
                    errorMessage = "No notes found or parsing failed"
                    showErrorAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    struct ToastView: View {
        var message: String
        
        var body: some View {
            Text(message)
                .padding()
                .background(Color.green.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
