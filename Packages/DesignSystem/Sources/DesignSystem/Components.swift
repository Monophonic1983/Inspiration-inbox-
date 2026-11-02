import SwiftUI

/// Subtle shimmer for cards still being processed. Never a spinner. Honors Reduce Motion by staying static.
public struct Shimmer: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public func body(content: Content) -> some View {
        content.overlay {
            if active && !reduceMotion {
                GeometryReader { geo in
                    LinearGradient(colors: [.clear, .white.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width * 1.6)
                        .blendMode(.plusLighter)
                }
                .mask(content)
                .allowsHitTesting(false)
                .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) { phase = 1 } }
            }
        }
    }
}

public extension View {
    func shimmer(_ active: Bool) -> some View { modifier(Shimmer(active: active)) }
    /// Card chrome used instead of separator-lined lists.
    func dsCard() -> some View {
        padding(DS.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.card, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}

/// The single orb: breathes at rest, swells with voice level.
public struct Orb: View {
    public var level: Float
    public var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(level: Float, isActive: Bool) { self.level = level; self.isActive = isActive }

    public var body: some View {
        let swell = 1 + CGFloat(level) * 0.35
        PhaseAnimator([false, true]) { breathing in
            Circle()
                .fill(RadialGradient(colors: [DS.Color.accent.opacity(0.95), DS.Color.accent.opacity(0.35)],
                                     center: .center, startRadius: 4, endRadius: 120))
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                .scaleEffect((reduceMotion ? 1 : (breathing ? 1.04 : 0.97)) * (isActive ? swell : 1))
                .shadow(color: DS.Color.accent.opacity(0.35), radius: 24 * swell)
        } animation: { _ in DS.Motion.orbBreath }
        .animation(DS.Motion.snappy, value: level)
        .accessibilityHidden(true)
    }
}
