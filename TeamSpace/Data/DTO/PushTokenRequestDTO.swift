import Foundation

/// POST /notifications/push-token 요청 바디
struct PushTokenRequestDTO: Codable {
    let token: String
    /// 명세서: "IOS" | "ANDROID"
    let deviceType: String

    init(token: String, deviceType: String = "IOS") {
        self.token = token
        self.deviceType = deviceType
    }
}
