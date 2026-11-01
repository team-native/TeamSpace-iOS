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
            RootView(container: container, session: session, entryRouter: appDelegate.notificationEntryRouter)
                // COMMON-08 큰 글자: 접근성 크기 2단계까지 키우고, 그보다 크면 레이아웃이 깨지지 않게 멈춰요.
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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
