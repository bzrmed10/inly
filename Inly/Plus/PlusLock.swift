import SwiftUI

/// Blurs a piece of UI that is part of Inly+ and puts an unlock button on top of it.
private struct PlusLockModifier: ViewModifier {
    let locked: Bool
    let reason: PaywallReason
    var label: String = L10n.t("Unlock with Inly+")

    func body(content: Content) -> some View {
        if locked {
            content
                .blur(radius: 8)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .overlay {
                    Button { Store.shared.paywall = reason } label: {
                        Label(label, systemImage: "lock.fill")
                            .font(Theme.font(15, .heavy))
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 18).padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
        } else {
            content
        }
    }
}

extension View {
    /// Shows the content blurred with an "Unlock with Inly+" button when `locked`.
    func plusLocked(_ locked: Bool, reason: PaywallReason, label: String = L10n.t("Unlock with Inly+")) -> some View {
        modifier(PlusLockModifier(locked: locked, reason: reason, label: label))
    }
}

/// Days of history shown without Inly+.
enum FreeLimits {
    static let historyDays = 14
    static let photos = 2

    /// The first day that is still free to look at.
    static func firstFreeDay(now: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -(historyDays - 1), to: calendar.startOfDay(for: now)) ?? now
    }
}
