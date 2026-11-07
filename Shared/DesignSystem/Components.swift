import SwiftUI

/// A progress ring with a soft glow orb behind it that takes the state color.
struct GlowRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 16
    var glow: Bool = true

    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            guard !reduceMotion else { return }
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
    var height: CGFloat = 60

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(19, .heavy))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
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


/// A labelled value with round minus / plus buttons (matches the design's tray-days stepper).
struct StepperRow: View {
    let title: String
    let valueText: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
                Text(valueText).font(Theme.font(20, .heavy).monospacedDigit())
                    .contentTransition(.numericText())
            }
            Spacer()
            HStack(spacing: 8) {
                roundButton("minus", label: L10n.t("One less")) { value = max(range.lowerBound, value - step) }
                    .disabled(value <= range.lowerBound)
                roundButton("plus", label: L10n.t("One more")) { value = min(range.upperBound, value + step) }
                    .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.snappy, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }

    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: 0x33333D), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}


/// Glass banner with an Undo button (top of the screen, as in the design).
struct ToastBanner: View {
    let title: String
    var subtitle: String?
    var color: Color = Theme.trayColor
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color(hex: 0x062014))
                .frame(width: 36, height: 36)
                .background(color, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.font(15, .heavy))
                if let subtitle {
                    Text(subtitle).font(Theme.font(12, .bold)).foregroundStyle(Color(hex: 0xC9C9D2))
                }
            }
            Spacer(minLength: 8)
            Button(action: onUndo) {
                Text(L10n.t("Undo"))
                    .font(Theme.font(14, .heavy))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 14).padding(.trailing, 10).padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }
}
