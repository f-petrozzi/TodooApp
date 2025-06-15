//
//  AITest.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//

import SwiftUI

struct AITestView: View {
    @State private var result: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                Text(result.isEmpty ? "Result will appear here" : result)
                    .padding()
            }

            Button("Test AI Prompt") {
                isLoading = true
                AIService.shared.generateNotes(from: "I need a list for a morning routine") { response in
                    DispatchQueue.main.async {
                        result = response ?? "No response"
                        isLoading = false
                    }
                }
            }
        }
        .padding()
    }
}
