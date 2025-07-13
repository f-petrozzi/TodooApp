//
//  SearchResultRowView.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/13/25.
//
import SwiftUI

struct SearchResultRowView: View {
    let parent: Note
    let result: Note
    @Binding var expandedParents: Set<Int32>
    @ObservedObject var viewModel: NoteViewModel
    let onAddChild: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.vPadding) {
            Text(parent.title)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 2)

            NoteRow(
                note: result,
                children: [],
                expandedParents: $expandedParents,
                viewModel: viewModel,
                showHelp: { },
                isParent: false,
                onAddChild: onAddChild
            )
        }
    }
}
