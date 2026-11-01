import SwiftUI

@main
struct TeamSpaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                .task {
                    appDelegate.pushTokenRegistrar.configure(
                        registerPushTokenUseCase: container.registerPushTokenUseCase
                    )
                }
                .onChange(of: session.currentUser != nil, initial: true) { _, isSignedIn in
                    appDelegate.pushTokenRegistrar.setSignedIn(isSignedIn)
                }
        }
    }
}
