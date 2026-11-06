import SwiftData
import SwiftUI
import UIKit

/// Compare the progress photos of two trays, side by side or with a reveal slider.
struct CompareSheet: View {
    @Query(sort: \Tray.number) private var allTrays: [Tray]
    @Environment(\.dismiss) private var dismiss

    @State private var leftNumber: Int?
    @State private var rightNumber: Int?
    @State private var slider = true
    @State private var split: CGFloat = 0.5

    private var withPhotos: [Tray] { allTrays.filter { $0.photoData != nil } }
    private func tray(_ n: Int?) -> Tray? { withPhotos.first { $0.number == n } }
    private func image(_ t: Tray?) -> UIImage? { t?.photoData.flatMap(UIImage.init(data:)) }

    var body: some View {
        let left = tray(leftNumber ?? withPhotos.first?.number)
        let right = tray(rightNumber ?? withPhotos.last?.number)

        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Compare").font(Theme.font(28, .heavy))
                Spacer()
                Button("Done") { dismiss() }.font(Theme.font(16, .heavy))
            }

            if withPhotos.count < 2 {
                Text("Add a photo to at least two trays to compare them.")
                    .font(Theme.font(15, .semibold)).foregroundStyle(Theme.muted)
            } else {
                HStack(spacing: 10) {
                    trayMenu("Before", selection: Binding(get: { left?.number ?? 0 }, set: { leftNumber = $0 }))
                    trayMenu("After", selection: Binding(get: { right?.number ?? 0 }, set: { rightNumber = $0 }))
                }

                Picker("Style", selection: $slider) {
                    Text("Slider").tag(true)
                    Text("Stacked").tag(false)
                }
                .pickerStyle(.segmented)

                if slider { sliderView(left, right) } else { sideBySide(left, right) }

                if let l = left, let r = right {
                    let days = Calendar.current.dateComponents([.day], from: l.startDate, to: r.startDate).day ?? 0
                    Text("Tray \(l.number) to tray \(r.number) · \(abs(days)) days apart")
                        .font(Theme.font(14, .bold)).foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x1C1C22))
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
    }

    private func trayMenu(_ title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.font(12, .bold)).foregroundStyle(Theme.muted)
            Picker(title, selection: selection) {
                ForEach(withPhotos, id: \.number) { Text("Tray \($0.number)").tag($0.number) }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .background(Theme.raised, in: Capsule())
        }
    }

    private func photo(_ t: Tray?) -> some View {
        Group {
            if let ui = image(t) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Theme.raised
            }
        }
        // A filled photo is bigger than its frame; without this it would catch taps meant for the buttons above it.
        .allowsHitTesting(false)
    }

    private func sideBySide(_ l: Tray?, _ r: Tray?) -> some View {
        VStack(spacing: 14) {
            ForEach(Array([l, r].enumerated()), id: \.offset) { _, t in
                VStack(alignment: .leading, spacing: 6) {
                    Text(t.map { "Tray \($0.number) · \($0.startDate.formatted(.dateTime.month(.abbreviated).day()))" } ?? "")
                        .font(Theme.font(14, .heavy))
                    photo(t)
                        .frame(maxWidth: .infinity).frame(height: 260)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    private func sliderView(_ l: Tray?, _ r: Tray?) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                photo(r).frame(width: width, height: 360).clipped()
                photo(l).frame(width: width, height: 360).clipped()
                    .mask(alignment: .leading) { Rectangle().frame(width: width * split) }
                Rectangle().fill(.white).frame(width: 3, height: 360).offset(x: width * split - 1.5)
                Circle().fill(.white).frame(width: 38, height: 38)
                    .overlay(Image(systemName: "arrow.left.and.right").font(.footnote.weight(.heavy)).foregroundStyle(Theme.night))
                    .offset(x: width * split - 19)
                VStack {
                    HStack {
                        label("Tray \(l?.number ?? 0)")
                        Spacer()
                        label("Tray \(r?.number ?? 0)")
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                split = min(1, max(0, v.location.x / max(1, width)))
            })
            .accessibilityElement()
            .accessibilityLabel("Before and after slider")
            .accessibilityValue("\(Int(split * 100)) percent")
            .accessibilityAdjustableAction { dir in
                switch dir {
                case .increment: split = min(1, split + 0.1)
                case .decrement: split = max(0, split - 0.1)
                @unknown default: break
                }
            }
        }
        .frame(height: 360)
    }

    private func label(_ text: String) -> some View {
        Text(text).font(Theme.font(12, .heavy))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.black.opacity(0.55), in: Capsule())
    }
}
