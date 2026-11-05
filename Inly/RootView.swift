import SwiftUI

/// System TabView: on iOS 26 this gets the Liquid Glass tab bar for free.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "circle.dashed") { TodayView() }
            Tab("Trays", systemImage: "square.stack.3d.up.fill") { TraysView() }
            Tab("History", systemImage: "chart.bar.fill") { PlaceholderTab(title: "History") }
        }
        .tint(Theme.inColor)
        .preferredColorScheme(.dark)
    }
}

private struct PlaceholderTab: View {
    let title: String
    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: "hourglass", description: Text("Coming in the next milestone."))
                .background(Theme.night.ignoresSafeArea())
                .navigationTitle(title)
        }
    }
}
