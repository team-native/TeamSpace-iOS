import Foundation

/// 로그아웃 — 토큰과 응답 캐시를 지웁니다.
/// TODO: 로그아웃 API · 푸시 토큰 삭제는 API 명세서에 추가되면 연결
struct LogoutUseCase {
    private let tokenStorage: TokenStorage

    init(tokenStorage: TokenStorage) {
        self.tokenStorage = tokenStorage
    }

    func execute() throws {
        URLCache.shared.removeAllCachedResponses()
        try tokenStorage.clear()
    }
}
