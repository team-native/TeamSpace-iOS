import Foundation

/// 소속 부서. 서버 값(rawValue)과 화면 표시 이름을 분리합니다.
enum Department: String, UnknownCaseDecodable, Hashable, CaseIterable {
    case leader = "Leader"
    case nativeOps = "NativeOps"
    case pmo = "PMO"
    case fa = "FA"
    case design = "Design"
    case dev = "Dev"
    case unknown = "UNKNOWN"

    static let unknownCase: Department = .unknown

    /// 계정 요청에서 고를 수 있는 부서
    static var selectable: [Department] {
        allCases.filter { $0 != .unknown }
    }

    var displayName: String {
        switch self {
        case .leader: return "Leader"
        case .nativeOps: return "NativeOps"
        case .pmo: return "PMO"
        case .fa: return "FA"
        case .design: return "NativeLab · Design"
        case .dev: return "NativeLab · Dev"
        case .unknown: return "기타"
        }
    }
}
