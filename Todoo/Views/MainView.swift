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

    @State private var isSearching = false
    @FocusState private var searchFieldIsFocused: Bool

    @State private var showDeletePopup = false
    @State private var notesToDelete = [Note]()

    var body: some View {
        ZStack {
            NavigationView {
                contentList
                    .navigationTitle(isSearching ? "" : "Todoo")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack(spacing: 12) {
                                Button {
                                    showingCategoryPicker = true
                                } label: {
                                    Image(systemName: "line.horizontal.3.decrease.circle")
                                }
                                if isSearching {
                                    HStack(spacing: 4) {
                                        Image(systemName: "magnifyingglass")
                                        TextField("Search notes", text: $viewModel.searchText)
                                            .textFieldStyle(.plain)
                                            .focused($searchFieldIsFocused)
                                        Button("Cancel") {
                                            withAnimation {
                                                isSearching = false
                                                viewModel.searchText = ""
                                            }
                                        }
                                        .font(.subheadline)
                                    }
                                    .padding(.horizontal, 8)
                                    .frame(height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemBackground))
                                    )
                                    .onAppear { searchFieldIsFocused = true }
                                } else {
                                    Button {
                                        withAnimation { isSearching = true }
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                }
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
                            selectedCategories: $viewModel.selectedCategories,
                            categoryOrder:    $viewModel.categoryOrder,
                            sortOption:       $viewModel.currentSort
                        ) {
                            showingCategoryPicker = false
                            viewModel.fetchNotes()
                        }
                    }
            }
            if showDeletePopup {
                Color.black.opacity(0.3).ignoresSafeArea()
                DeleteNoteView(
                    notes: notesToDelete,
                    viewModel: viewModel
                ) {
                    showDeletePopup = false
                    viewModel.fetchNotes()
                }
                .frame(maxWidth: 350, maxHeight: 500)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                .shadow(radius: 20)
                .padding()
            }
        }
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
        .onAppear {
            viewModel.fetchNotes()
            checkPendingDeletions()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )
        ) { _ in
            viewModel.fetchNotes()
            checkPendingDeletions()
        }
    }

    private var contentList: some View {
        List {
            if viewModel.searchText.isEmpty {
                ForEach(
                    viewModel.categoryOrder
                        .filter { viewModel.selectedCategories.contains($0) },
                    id: \.self
                ) { category in
                    sectionView(for: category)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden, edges: .all)
                }
            } else {
                let parentMatches = viewModel.searchResults.filter { $0.parentId == nil }
                ForEach(parentMatches) { parent in
                    NoteRow(
                        note: parent,
                        children: [],
                        expandedParents: $expandedParents,
                        viewModel: viewModel,
                        showHelp: { showHelpOverlay = true },
                        isParent: true,
                        onAddChild: { currentParentId = parent.id }
                    )
                    .listRowInsets(.init(top: 2, leading: 16, bottom: 2, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden, edges: .all)
                }
                let subMatches = viewModel.searchResults.filter { $0.parentId != nil }
                let parentIDs = Array(Set(subMatches.compactMap { $0.parentId }))
                ForEach(parentIDs, id: \.self) { pid in
                    if let parent = viewModel.allNotes.first(where: { $0.id == pid }) {
                        Text(parent.title)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                        ForEach(subMatches.filter { $0.parentId == pid }) { child in
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
                            .listRowInsets(.init(top: 2, leading: 32, bottom: 2, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden, edges: .all)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden, edges: .all)
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.clear)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .animation(.default, value: viewModel.searchText)
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
                .listRowInsets(.init(top: 2, leading: 16, bottom: 2, trailing: 16))
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
                        .listRowInsets(.init(top: 2, leading: 32, bottom: 2, trailing: 16))
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
                        .listRowInsets(.init(top: 2, leading: 32, bottom: 2, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden, edges: .all)
                    }
                }
            }
        }
    }

    private func checkPendingDeletions() {
        let now = Date()
        let due = viewModel.allNotes.filter {
            $0.isMarkedForDeletion &&
            ($0.deletionScheduledAt ?? Date.distantFuture) <= now
        }
        if !due.isEmpty {
            notesToDelete = due
            showDeletePopup = true
        }
    }
}
