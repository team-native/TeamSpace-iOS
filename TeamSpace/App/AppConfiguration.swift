import Foundation

/// Info.plist(← Config/*.xcconfig) 에서 읽는 실행 설정
struct AppConfiguration {
    let apiBaseURL: URL?
    let usesMockAPI: Bool

    static var current: AppConfiguration {
        let info = Bundle.main.infoDictionary ?? [:]
        let baseURLText = info["API_BASE_URL"] as? String ?? ""
        let mockFlag = (info["USE_MOCK_API"] as? String ?? "YES").uppercased()
        return AppConfiguration(
            apiBaseURL: URL(string: baseURLText),
            usesMockAPI: mockFlag == "YES" || baseURLText.isEmpty
        )
    }
}
