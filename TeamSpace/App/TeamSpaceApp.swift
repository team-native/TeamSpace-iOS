import SwiftUI

@main
struct TeamSpaceApp: App {
    private let container: DIContainer
    @State private var session: AppSession

    init() {
        let container = DIContainer.make()
        self.container = container
        _session = State(initialValue: container.makeAppSession())
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container, session: session)
        }
    }
}
