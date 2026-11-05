import AppIntents
import SwiftUI
import WidgetKit

/// Control Center toggle: on = aligners out.
struct WearControl: ControlWidget {
    static let kind = "com.bzrmed.inly.control"

    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }
        func currentValue() async throws -> Bool {
            await SessionService.shared.isOut()
        }
    }

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: Provider()) { isOut in
            ControlWidgetToggle("Aligners out", isOn: isOut, action: SetOutIntent()) { isOn in
                Label(isOn ? "Out" : "In", systemImage: isOn ? "timer" : "checkmark.circle.fill")
            }
        }
        .displayName("Aligners")
        .description("Take your aligners out or put them back in.")
    }
}
