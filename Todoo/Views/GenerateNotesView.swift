//
//  GenerateNotesView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//
import SwiftUI

struct GenerateNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NoteViewModel

    @State private var prompt = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showToast = false

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.vPadding) {
                ZStack(alignment: .topLeading) {
                  TextEditor(text: $prompt)
                    .frame(height: 80)

                  if prompt.isEmpty {
                    Text("Enter prompt")
                      .font(Theme.bodyFont)
                      .foregroundColor(.secondary)
                      .padding(.horizontal, 4)
                      .padding(.vertical, 8)
                  }
                }

                Button(action: generateNotes) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: Theme.accent)
                            )
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Generate")
                            .font(Theme.bodyFont)
                            .frame(maxWidth: .infinity)
                    }
                }
                .primaryButtonStyle()

                Spacer()
            }
            .padding(.horizontal, Theme.hPadding)
            .navigationTitle("AI Notes")
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
        .safeAreaInset(edge: .top) {
            if showToast {
                ToastView(message: "Added successfully!")
                    .padding(.horizontal, Theme.hPadding)
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
                    showErrorAlert = true
                    return
                }

                if let json = AIService.shared.extractFirstJSONArray(from: result),
                   let notes = AIService.shared.parseNotes(from: json),
                   !notes.isEmpty {

                    for note in notes {
                        viewModel.addNote(
                            title: note.title,
                            description: note.description,
                            date: note.date,
                            parentId: nil
                        )
                    }

                    showToast = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showToast = false
                        dismiss()
                    }
                } else {
                    errorMessage = "No notes found or parsing failed."
                    showErrorAlert = true
                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.error)
                }
            }
        }
    }

    private struct ToastView: View {
        var message: String

        var body: some View {
            Text(message)
                .font(Theme.bodyFont)
                .padding(.vertical, Theme.vPadding)
                .padding(.horizontal, Theme.hPadding)
                .background(Color.green.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(Theme.cornerRadius)
        }
    }
}
