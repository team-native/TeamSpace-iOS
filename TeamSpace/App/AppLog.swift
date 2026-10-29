import Foundation
import os

/// print 대신 os.Logger 를 사용
enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "TeamSpace"

    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let push = Logger(subsystem: subsystem, category: "Push")

    /// 에러를 무시하지 않고 개발자용 정보로 남깁니다. (사용자 메시지는 화면에서 따로 보여줌)
    static func record(_ error: Error, context: String, logger: Logger = ui) {
        let debugInfo = (error as? AppError)?.debugInfo ?? String(describing: error)
        logger.error("[\(context, privacy: .public)] \(debugInfo, privacy: .private)")
    }
}
