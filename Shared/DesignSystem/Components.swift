import SwiftUI

/// A progress ring with a soft glow orb behind it that takes the state color.
struct GlowRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 16
    var glow: Bool = true

    @State private var breathe = false

    var body: some View {
        ZStack {
            if glow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.45), color.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 170
                        )
                    )
                    .scaleEffect(breathe ? 1.08 : 0.94)
                    .blur(radius: 24)
                    .padding(-40)
                    .allowsHitTesting(false)
            }
            Circle()
                .stroke(Theme.raised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.8), value: progress)
        }
        .animation(.smooth(duration: 0.6), value: color)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

/// Full-width pill button used for the main action.
struct PillButtonStyle: ButtonStyle {
    var color: Color
    var foreground: Color = Color(hex: 0x0B0B0F)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(19, .heavy))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(color, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Small rounded chip (e.g. out reason).
struct ChipStyle: ButtonStyle {
    var selected: Bool
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(14, .semibold))
            .foregroundStyle(selected ? Color(hex: 0x0B0B0F) : Theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selected ? color : Theme.raised, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Dark surface card.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}
