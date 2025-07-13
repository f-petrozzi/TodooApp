//
//  CategoryPickerView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/13/25.
//
import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategories: Set<FilterCategory>
    @Binding var sortOption: DatabaseManager.SortOption
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Filter Categories")
                .font(.headline)

            ForEach(FilterCategory.allCases) { category in
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

            Divider()

            Text("Sort by")
                .font(.headline)

            Picker("", selection: $sortOption) {
                Text("Alarm").tag(DatabaseManager.SortOption.alarm)
                Text("Created").tag(DatabaseManager.SortOption.created)
                Text("Title").tag(DatabaseManager.SortOption.title)
            }
            .pickerStyle(SegmentedPickerStyle())

            Divider()

            Button("Done") {
                onDone()
            }
            .padding(.top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 4)
        )
        .padding()
    }
}
