//
//  MainView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25
//
import SwiftUI
import AppIntents

extension Int32: @retroactive Identifiable {
  public var id: Int32 { self }
}

struct MainView: View {
  @StateObject var viewModel: NoteViewModel

  @State private var showingAddNote = false
  @State private var showingGenerate = false
  @State private var showingCategoryPicker = false
  @State private var currentParentId: Int32? = nil
  @State private var expandedParents = Set<Int32>()
  @State private var showHelpOverlay = false

  var body: some View {
    NavigationView {
      contentList
        .navigationTitle("Todoo")
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarLeading) {
            Button { showingCategoryPicker = true } label: {
              Image(systemName: "line.horizontal.3.decrease.circle")
            }
          }
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { showingGenerate = true } label: {
              Image(systemName: "sparkles").iconButtonStyle()
            }
            Button { showingAddNote = true } label: {
              Image(systemName: "plus").iconButtonStyle()
            }
          }
        }
        .accentColor(Theme.accent)
        .sheet(isPresented: $showingCategoryPicker) {
          CategoryPickerView(
            selectedCategories: $viewModel.selectedCategories
          ) {
            showingCategoryPicker = false
            viewModel.fetchNotes()
          }
        }
    }
    .onAppear { viewModel.fetchNotes() }
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIApplication.didBecomeActiveNotification
      )
    ) { _ in viewModel.fetchNotes() }
    .sheet(isPresented: $showingAddNote) {
      AddNoteView(viewModel: viewModel, parentId: nil)
        .popupStyle()
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
    .sheet(isPresented: $showingGenerate) {
      GenerateNotesView(viewModel: viewModel)
        .popupStyle()
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
    .sheet(item: $currentParentId) { parent in
      AddNoteView(viewModel: viewModel, parentId: parent)
        .popupStyle()
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
    .sheet(isPresented: $showHelpOverlay) {
      HelpOverlayView()
    }
  }

  private var contentList: some View {
    let categories = FilterCategory.allCases
      .filter { viewModel.selectedCategories.contains($0) }
      .sorted { $0.displayName < $1.displayName }

    return List {
      ForEach(categories, id: \.self) { category in
        sectionView(for: category)
          .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden, edges: .all)
      }
    }
    .listStyle(.plain)
    .listRowSeparator(.hidden, edges: .all)
    .listSectionSeparator(.hidden)
    .listRowBackground(Color.clear)
    .scrollContentBackground(.hidden)
    .background(Theme.background)
    .animation(.default, value: viewModel.sectionedNotes)
  }

  @ViewBuilder
  private func sectionView(for category: FilterCategory) -> some View {
    Section(
      header:
        Text(category.displayName)
          .padding(.leading, 16)
    ) {
      let notesForCategory = viewModel.sectionedNotes[category] ?? []
      let parents = notesForCategory.filter { $0.parentId == nil }

      ForEach(parents) { parent in
        let children = viewModel.allNotes.filter { $0.parentId == parent.id }

        NoteRow(
          note: parent,
          children: children,
          expandedParents: $expandedParents,
          viewModel: viewModel,
          showHelp: { showHelpOverlay = true },
          isParent: true,
          onAddChild: { currentParentId = parent.id }
        )
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden, edges: .all)

        if expandedParents.contains(parent.id) {
          ForEach(children) { child in
            HStack {
              Spacer().frame(width: 16)
              NoteRow(
                note: child,
                children: [],
                expandedParents: $expandedParents,
                viewModel: viewModel,
                showHelp: { showHelpOverlay = true },
                isParent: false,
                onAddChild: { }
              )
            }
            .listRowInsets(EdgeInsets(top: 2, leading: 32, bottom: 2, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden, edges: .all)
          }

          if !children.isEmpty {
            HStack {
              Button {
                currentParentId = parent.id
              } label: {
                Image(systemName: "plus.circle")
                  .font(.title3)
                  .foregroundColor(.secondary)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 2, leading: 32, bottom: 2, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden, edges: .all)
          }
        }
      }
    }
  }
}

struct HelpOverlayView: View {
  var body: some View {
    VStack(spacing: 16) {
      Text("Help").font(.headline)
      Text("Here you can show tips and instructions.")
        .multilineTextAlignment(.center)
      Button("Dismiss") { }
    }
    .padding()
  }
}
