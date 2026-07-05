import SwiftUI

@main
struct DevHubApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .onDisappear {
                    ProcessManager.shared.stopAll()
                }
        }
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
    }
}
