import SwiftUI

/// Spectra color palette
public struct SpectraColors {
    // Primary brand colors
    public static let accent = Color.accentColor
    public static let primary = Color.primary
    public static let secondary = Color.secondary
    
    // Status colors
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red
    public static let info = Color.blue
    
    // Stream health colors
    public static let healthOK = Color.green
    public static let healthFlaky = Color.orange
    public static let healthDead = Color.red
    public static let healthUnknown = Color.gray
    
    // Background colors
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let tertiaryBackground = Color(nsColor: .textBackgroundColor)
    
    // Player colors
    public static let playerBackground = Color.black
    public static let playerOverlay = Color.black.opacity(0.7)
    public static let playerControls = Color.white
}

#if os(macOS)
import AppKit
extension Color {
    init(nsColor: NSColor) {
        self.init(nsColor)
    }
}
#else
import UIKit
extension SpectraColors {
    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
}
#endif

/// Spectra typography
public struct SpectraTypography {
    public static let largeTitle = Font.largeTitle
    public static let title = Font.title
    public static let title2 = Font.title2
    public static let title3 = Font.title3
    public static let headline = Font.headline
    public static let body = Font.body
    public static let callout = Font.callout
    public static let subheadline = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption = Font.caption
    public static let caption2 = Font.caption2
    
    // Custom monospaced for technical info
    public static let mono = Font.system(.body, design: .monospaced)
    public static let monoSmall = Font.system(.caption, design: .monospaced)
}

/// Spectra spacing constants
public struct SpectraSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

/// Spectra corner radius
public struct SpectraRadius {
    public static let sm: CGFloat = 4
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 12
    public static let xl: CGFloat = 16
    public static let full: CGFloat = 9999
}
