import SwiftUI

/// Placeholder root view. Replaced by the real Today screen in M1.4.
struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 11 / 255, green: 11 / 255, blue: 15 / 255)
                .ignoresSafeArea()
            Text("Inly")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView()
}
