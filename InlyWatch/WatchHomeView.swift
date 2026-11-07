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
        let progress = p.isOut ? outFraction(p) : max(0.001, p.wornFraction)
        return ZStack {
            // The screen edge is the progress ring (the timer text ticks by itself; the ring is as of the last redraw).
            ScreenEdgeRing(progress: progress, color: color)
                .ignoresSafeArea()

            VStack(spacing: 2) {
                Text(p.isOut ? "OUT" : "WORN")
                    .font(Theme.font(12, .heavy)).tracking(1.5).foregroundStyle(color)
                Group {
                    if p.isOut {
                        Text(timerInterval: p.outStart...p.outStart.addingTimeInterval(86_400), countsDown: false)
                            .monospacedDigit()
                    } else {
                        Text(TimeFormat.hoursMinutes(p.wornSeconds))
                    }
                }
                .font(Theme.font(38, .heavy)).minimumScaleFactor(0.5).lineLimit(1)

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
                .padding(.top, 8)
            }
            .padding(.horizontal, 14)
        }
    }

    private func outFraction(_ p: WatchPayload) -> Double {
        let total = p.budgetEnd.timeIntervalSince(p.outStart)
        guard total > 0 else { return 1 }
        return min(1, max(0.001, Date.now.timeIntervalSince(p.outStart) / total))
    }
}


/// A progress ring that follows the rounded edge of the watch screen, starting at the top centre.
struct ScreenEdgeRing: View {
    var progress: Double
    var color: Color
    private let lineWidth: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size).insetBy(dx: lineWidth / 2 + 1, dy: lineWidth / 2 + 1)
            let radius = min(rect.width, rect.height) * 0.24
            ZStack {
                EdgePath(rect: rect, radius: radius).stroke(Theme.raised, lineWidth: lineWidth)
                EdgePath(rect: rect, radius: radius)
                    .trim(from: 0, to: min(1, max(0.001, progress)))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }
}

private struct EdgePath: Shape {
    let rect: CGRect
    let radius: CGFloat

    func path(in _: CGRect) -> Path {
        var p = Path()
        let r = radius
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return p
    }
}
