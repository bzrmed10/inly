import SwiftUI

/// Looping animation driver: flips `phase` every couple of seconds, or just settles when Reduce Motion is on.
private struct Loop: ViewModifier {
    @Binding var phase: Bool
    var animate: Bool
    var every: Double = 1.9

    func body(content: Content) -> some View {
        content.task {
            guard animate else { phase = true; return }
            while !Task.isCancelled {
                withAnimation(.smooth(duration: 0.9)) { phase.toggle() }
                try? await Task.sleep(for: .seconds(every))
            }
        }
    }
}

private extension View {
    func loop(_ phase: Binding<Bool>, animate: Bool, every: Double = 1.9) -> some View {
        modifier(Loop(phase: phase, animate: animate, every: every))
    }
}

/// Welcome: the logo ring draws itself around the wordmark.
struct WelcomeVisual: View {
    var animate: Bool
    @State private var filled = false

    var body: some View {
        ZStack {
            Circle().stroke(Theme.raised, lineWidth: 14)
            Circle()
                .trim(from: 0, to: filled ? 0.78 : 0.04)
                .stroke(Theme.inColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(L10n.t("inly")).font(Theme.font(50, .heavy))
        }
        .frame(width: 200, height: 200)
        .loop($filled, animate: animate, every: 2.2)
        .accessibilityHidden(true)
    }
}

/// Dynamic Island: the island grows to show the timer and the Put back in button pulses.
struct IslandVisual: View {
    var animate: Bool
    @State private var open = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Capsule().fill(Theme.night)
                Capsule().stroke(Theme.raised, lineWidth: 1)
                HStack {
                    Circle().stroke(Theme.outColor, lineWidth: 4).frame(width: 22, height: 22)
                    if open {
                        Spacer(minLength: 0)
                        Text(L10n.t("1:01")).font(Theme.timerFont(20)).foregroundStyle(Theme.outColor)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(width: open ? 250 : 110, height: 46)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("OUT")).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(Theme.outColor)
                Text(L10n.t("1:01")).font(Theme.timerFont(30)).foregroundStyle(Theme.outColor)
                Text(L10n.t("Put back in"))
                    .font(Theme.font(15, .heavy)).foregroundStyle(Theme.night)
                    .frame(maxWidth: .infinity).frame(height: 38)
                    .background(Theme.outColor, in: Capsule())
                    .scaleEffect(open ? 1.04 : 1)
            }
            .padding(16)
            .frame(width: 250)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .loop($open, animate: animate)
        .accessibilityHidden(true)
    }
}

/// Widgets: a small widget whose ring fills and a medium widget with a Take out button.
struct WidgetsVisual: View {
    var animate: Bool
    @State private var filled = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Theme.hairline, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: filled ? 0.8 : 0.1)
                        .stroke(Theme.inColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .padding(22)
                .frame(width: 110, height: 110)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("WORN")).font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(Theme.inColor)
                    Text(L10n.t("11h 36m")).font(Theme.font(22, .heavy))
                    Text(L10n.t("1h 35m left")).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
                }
                .padding(16)
                .frame(width: 126, height: 110, alignment: .leading)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("Today")).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted)
                    Text(L10n.t("11h 36m")).font(Theme.font(22, .heavy))
                }
                Spacer()
                Text(L10n.t("Take out")).font(Theme.font(15, .heavy)).foregroundStyle(Theme.night)
                    .padding(.horizontal, 18).frame(height: 38)
                    .background(Theme.inColor, in: Capsule())
                    .scaleEffect(filled ? 1.06 : 1)
            }
            .padding(16)
            .frame(width: 250)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .loop($filled, animate: animate)
        .accessibilityHidden(true)
    }
}

/// Name: a live greeting that follows what you type.
struct GreetingVisual: View {
    var name: String

    var body: some View {
        VStack(spacing: 6) {
            Text(Greeting.phrase(for: .now) + ",")
                .font(Theme.font(22, .semibold)).foregroundStyle(Theme.muted)
            Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? L10n.t("friend") : name)
                .font(Theme.font(44, .heavy))
                .lineLimit(1).minimumScaleFactor(0.5)
                .contentTransition(.interpolate)
                .animation(.smooth, value: name)
        }
        .frame(height: 120)
        .accessibilityHidden(true)
    }
}

/// Goal: the big hours number pulses gently.
struct GoalVisual: View {
    var hours: Int
    var animate: Bool
    @State private var big = false

    var body: some View {
        Text("\(hours)" + L10n.t("unit.h"))
            .font(Theme.font(76, .heavy)).foregroundStyle(Theme.inColor)
            .contentTransition(.numericText())
            .animation(.snappy, value: hours)
            .scaleEffect(big ? 1.05 : 1)
            .loop($big, animate: animate, every: 1.6)
            .frame(height: 120)
            .accessibilityHidden(true)
    }
}

/// Reminders: a notification card that slides in with its Put back in button.
struct ReminderVisual: View {
    var animate: Bool
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.inColor).frame(width: 28, height: 28)
                    .overlay(Text(L10n.t("i")).font(Theme.font(16, .heavy)).foregroundStyle(Theme.night))
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.t("Still out?")).font(Theme.font(15, .heavy))
                    Text(L10n.t("Your aligners have been out for 45 minutes."))
                        .font(Theme.font(12, .medium)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text(L10n.t("Put back in")).font(Theme.font(13, .heavy)).foregroundStyle(Theme.night)
                .padding(.horizontal, 14).frame(height: 30)
                .background(Theme.outColor, in: Capsule())
        }
        .padding(14)
        .frame(width: 310, alignment: .leading)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .offset(y: shown ? 0 : -14)
        .opacity(shown ? 1 : 0.35)
        .loop($shown, animate: animate, every: 2.1)
        .frame(height: 110)
        .accessibilityHidden(true)
    }
}

/// All set: the ring pops.
struct DoneVisual: View {
    var animate: Bool
    @State private var pop = false

    var body: some View {
        ZStack {
            Circle().stroke(Theme.raised, lineWidth: 16)
            Circle().trim(from: 0, to: 0.82)
                .stroke(Theme.inColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(L10n.t("Day 1")).font(Theme.font(28, .heavy))
        }
        .frame(width: 170, height: 170)
        .scaleEffect(pop ? 1.05 : 0.97)
        .loop($pop, animate: animate, every: 1.5)
        .accessibilityHidden(true)
    }
}
