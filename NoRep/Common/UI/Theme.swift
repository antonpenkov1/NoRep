import SwiftUI

enum Theme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let card = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let cardBorder = Color.white.opacity(0.06)

    /// Judge's "no rep" red — the brand accent.
    static let accent = Color(red: 1.0, green: 0.28, blue: 0.21)

    static let work = Color(red: 0.24, green: 0.86, blue: 0.44)
    static let rest = Color(red: 0.27, green: 0.60, blue: 1.0)
    static let prepare = Color(red: 1.0, green: 0.78, blue: 0.22)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)

    static func color(for kind: SegmentKind) -> Color {
        switch kind {
        case .prepare: return prepare
        case .work: return work
        case .rest: return rest
        }
    }
}

extension Font {
    /// Big timer digits.
    static func timerDigits(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }

    static var sectionLabel: Font {
        .system(.footnote, design: .rounded).weight(.semibold)
    }
}
