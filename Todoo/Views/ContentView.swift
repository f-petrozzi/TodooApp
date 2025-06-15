//
//  ContentView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // UI will go here
        }
    }
}

#Preview {
    ContentView()
        .onAppear {
            let note = Note(id: 0, title: "Test", description: "Hello", date: Date(), isCompleted: false)
            DatabaseManager.shared.insertNote(note)
            
            let notes = DatabaseManager.shared.getAllNotes()
            print(notes)
        }
}


