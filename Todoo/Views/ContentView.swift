//
//  ContentView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/11/25.
//
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var viewModel: NoteViewModel

  var body: some View {
    MainView(viewModel: viewModel)
  }
}

#Preview {
  ContentView()
    .environmentObject(NoteViewModel())
}
