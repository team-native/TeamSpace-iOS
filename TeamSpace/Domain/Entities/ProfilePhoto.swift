import Foundation

/// 서버가 주는 프로필 사진 주소 — 보통 `/people/member-02/photo?v=…` 처럼 서버 기준 상대 경로예요.
/// 빈 값이면 사진이 없는 거라 만들지 않아요.
struct ProfilePhoto: Equatable, Hashable, Sendable {
    let path: String

    init?(_ raw: String?) {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        path = trimmed
    }

    /// 상대 경로는 서버 주소에 붙이고, `https://…` · `data:image/…` 는 그대로 써요.
    func url(relativeTo baseURL: URL?) -> URL? {
        if path.hasPrefix("/") {
            guard let baseURL, var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
            let parts = path.split(separator: "?", maxSplits: 1).map(String.init)
            let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
            components.path = basePath + parts[0]
            components.percentEncodedQuery = parts.count > 1 ? parts[1] : nil
            return components.url
        }
        return URL(string: path)
    }
}
