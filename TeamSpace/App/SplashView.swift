import SwiftUI

/// 앱을 켤 때 보이는 로고 스플래시.
/// 시스템 실행 화면(UILaunchScreen: launch-logo)과 같은 자리 · 같은 크기의 로고 타일에서 이어져,
/// 이름과 로딩 바가 나타났다가 자동 로그인 확인이 끝나면 사라져요. (웹 스플래시와 같은 모양)
struct SplashView: View {
    static let tileSize: CGFloat = 84

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var barPhase = false

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            Image("launch-logo")
                .resizable()
                .frame(width: Self.tileSize, height: Self.tileSize)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 15, y: 10)
                .overlay(alignment: .top) {
                    VStack(spacing: 14) {
                        Text(BrandLogo.brandName)
                            .font(.system(size: 20, weight: .bold))
                            .tracking(-0.8)
                            .foregroundStyle(Color.tsInk)
                        loadingBar
                    }
                    .fixedSize()
                    .offset(y: Self.tileSize + 14)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 6)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(BrandLogo.brandName) 불러오는 중")
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.05)) { appeared = true }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: false)) { barPhase = true }
        }
    }

    private var loadingBar: some View {
        Capsule()
            .fill(Color.tsLine)
            .frame(width: 64, height: 3)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 1, green: 0.79, blue: 0.24))
                    .frame(width: 26, height: 3)
                    .offset(x: reduceMotion ? 0 : (barPhase ? 64 : -26))
            }
            .clipShape(Capsule())
    }
}

#Preview {
    SplashView()
}

#Preview("Dark") {
    SplashView().preferredColorScheme(.dark)
}
