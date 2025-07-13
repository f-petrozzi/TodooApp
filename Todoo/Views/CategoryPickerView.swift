//
//  CategoryPickerView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/13/25.
//
import SwiftUI

struct CategoryPickerView: View {
  @Binding var selectedCategories: Set<FilterCategory>
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
