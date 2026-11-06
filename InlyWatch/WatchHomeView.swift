import SwiftUI

struct WatchHomeView: View {
    let model: WatchModel

    var body: some View {
        Group {
            if let p = model.payload {
                content(p)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.and.arrow.forward").font(.title2).foregroundStyle(Theme.inColor)
                    Text("Open Inly on your iPhone once to connect.")
                        .font(Theme.font(14, .semibold)).multilineTextAlignment(.center).foregroundStyle(Theme.muted)
                }
                .padding()
            }
        }
        .containerBackground(Theme.night.gradient, for: .navigation)
    }

    private func content(_ p: WatchPayload) -> some View {
        let color = p.isOut ? Theme.outColor : Theme.inColor
        let range = p.outStart...max(p.budgetEnd, p.outStart.addingTimeInterval(1))
        return VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Theme.raised, lineWidth: 9)
                if p.isOut {
                    // The timer text ticks by itself; the ring is the budget used when this screen was drawn.
                    Circle()
                        .trim(from: 0, to: outFraction(p))
                        .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                } else {
                    Circle()
                        .trim(from: 0, to: max(0.001, p.wornFraction))
                        .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 0) {
                    Text(p.isOut ? "OUT" : "WORN")
                        .font(Theme.font(11, .heavy)).tracking(1).foregroundStyle(color)
                    if p.isOut {
                        Text(timerInterval: p.outStart...p.outStart.addingTimeInterval(86_400), countsDown: false)
                            .font(Theme.font(24, .heavy)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                    } else {
                        Text(TimeFormat.hoursMinutes(p.wornSeconds))
                            .font(Theme.font(24, .heavy)).minimumScaleFactor(0.6).lineLimit(1)
                    }
                }
                .padding(.horizontal, 14)
            }
            .frame(maxWidth: 120, maxHeight: 120)

            Group {
                if p.isOut {
                    HStack(spacing: 4) {
                        Text(timerInterval: range, countsDown: true).monospacedDigit()
                        Text("left")
                    }
                } else {
                    Text("\(TimeFormat.hoursMinutes(p.leftSeconds)) left today")
                }
            }
            .font(Theme.font(13, .heavy)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)

            Button { model.toggle() } label: {
                Text(p.isOut ? "Put back in" : "Take out")
                    .font(Theme.font(16, .heavy)).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .foregroundStyle(Theme.night)
        }
    }

    private func outFraction(_ p: WatchPayload) -> Double {
        let total = p.budgetEnd.timeIntervalSince(p.outStart)
        guard total > 0 else { return 1 }
        return min(1, max(0.001, Date.now.timeIntervalSince(p.outStart) / total))
    }
}
