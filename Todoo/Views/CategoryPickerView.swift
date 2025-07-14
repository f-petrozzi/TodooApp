//
//  CategoryPickerView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/13/25.
//
import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategories: Set<FilterCategory>
    @Binding var categoryOrder: [FilterCategory]
    @Binding var sortOption: DatabaseManager.SortOption
    let onDone: () -> Void

    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filter Categories")) {
                    ForEach(categoryOrder, id: \.self) { category in
                        HStack {
                            Text(category.displayName)
                            Spacer()
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    }
                    .onMove(perform: moveCategory)
                }

                Section(header: Text("Sort by")) {
                    Picker("", selection: $sortOption) {
                        Text("Alarm").tag(DatabaseManager.SortOption.alarm)
                        Text("Created").tag(DatabaseManager.SortOption.created)
                        Text("Title").tag(DatabaseManager.SortOption.title)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
            .environment(\.editMode, $editMode)
            .onLongPressGesture {
                withAnimation {
                    editMode = .active
                }
            }
        }
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        categoryOrder.move(fromOffsets: source, toOffset: destination)
    }
}
