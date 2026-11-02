import SwiftUI

/// Design tokens: monochrome plus one accent. Spec: PRD "UX and interaction spec".
public enum DS {
    public enum Color {
        public static let accent = SwiftUI.Color.orange
        public static let background = SwiftUI.Color(.systemBackground)
        public static let card = SwiftUI.Color(.secondarySystemBackground)
        public static let primaryText = SwiftUI.Color.primary
        public static let secondaryText = SwiftUI.Color.secondary
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 40
        /// Minimum touch target (PRD quality bar).
        public static let minTarget: CGFloat = 44
    }

    public enum Radius {
        public static let card: CGFloat = 20
    }

    public enum Font {
        public static let largeTitle = SwiftUI.Font.system(.largeTitle, design: .default, weight: .semibold)
        public static let title = SwiftUI.Font.system(.title2, design: .default, weight: .semibold)
        public static let body = SwiftUI.Font.system(.body)
        public static let caption = SwiftUI.Font.system(.caption)
    }

    /// Spring presets only; no linear timing anywhere.
    public enum Motion {
        public static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.8)
        public static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.85)
        public static let orbBreath = Animation.spring(response: 2.0, dampingFraction: 1.0)
    }
}
