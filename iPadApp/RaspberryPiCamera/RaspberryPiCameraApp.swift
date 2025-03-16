// App entry point

import SwiftUI

@main
struct RaspberryPiCameraApp: App {
    // Create a shared instance of StreamManager that
    // can be used throughout the app

    @StateObject private var streamManager = StreamManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(streamManager)
        }
    }
}