//
//  Theme.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/20/25.
//
import SwiftUI

struct Theme {
    static let accent            = Color(.systemBlue)
    static let background        = Color(.systemBackground)
    static let cardBackground    = Color(.secondarySystemBackground)
    static let cornerRadius: CGFloat   = 2

    static let headlineFont      = Font.headline
    static let subheadlineFont   = Font.subheadline
    static let bodyFont          = Font.body

    static let hPadding: CGFloat = 2
    static let vPadding: CGFloat = 2

    static let textFieldHPadding: CGFloat = 8
    static let textFieldVPadding: CGFloat = 2
}

extension View {
  func cardStyle() -> some View {
    self
      .padding(.horizontal, Theme.hPadding)
      .padding(.vertical, Theme.vPadding)
      .cornerRadius(Theme.cornerRadius)
  }

  func textFieldStyle() -> some View {
    self
      .padding(.horizontal, Theme.textFieldHPadding)
      .padding(.vertical, Theme.textFieldVPadding)
      .cornerRadius(Theme.cornerRadius)
  }

  func primaryButtonStyle() -> some View {
    self
      .font(Theme.bodyFont.weight(.semibold))
      .padding(.vertical, Theme.vPadding)
      .padding(.horizontal, Theme.hPadding)
      .frame(maxWidth: .infinity)
      .background(Theme.accent)
      .foregroundColor(.white)
      .cornerRadius(Theme.cornerRadius)
  }

  func iconButtonStyle(size: CGFloat = 20) -> some View {
    self
      .font(.system(size: size))
      .foregroundColor(Theme.accent)
  }
}
