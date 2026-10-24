import SwiftUI

@main
struct TeamSpaceApp: App {
    private let container = DIContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
