import SwiftUI
import WidgetKit

@main
struct InlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PlaceholderWidget()
    }
}

/// Placeholder widget so the extension builds. Real widgets arrive in Milestone 3.
struct PlaceholderWidget: Widget {
    let kind = "PlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { _ in
            Text("Inly")
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .containerBackground(for: .widget) {
                    Color(red: 11 / 255, green: 11 / 255, blue: 15 / 255)
                }
        }
        .configurationDisplayName("Inly")
        .description("Aligner wear time.")
        .supportedFamilies([.systemSmall])
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}
