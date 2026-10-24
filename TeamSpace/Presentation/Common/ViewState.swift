import Foundation

/// 로딩 / 빈 화면 / 오류 / 권한 없음 상태를 하나의 enum 으로 관리합니다.
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(Error)
    case forbidden

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

extension Error {
    /// 사용자에게 보여줄 메시지 (디버그 정보는 AppLog 로)
    var userMessage: String {
        (self as? AppError)?.userMessage ?? AppError.unknown("").userMessage
    }
}
