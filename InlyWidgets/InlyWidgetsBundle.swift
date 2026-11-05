import SwiftUI
import WidgetKit

@main
struct InlyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        InlyLiveActivity()
        WearWidget()
        WearControl()
    }
}
