import SwiftUI

/// AppRoute → 실제 화면
struct AppRouteView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .comingSoon(let title):
            ComingSoonView(title: title, showsBackButton: true)
        }
    }
}
