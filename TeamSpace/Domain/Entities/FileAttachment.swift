import Foundation

/// 결재 · 공지 첨부 파일 — 서버 `{id, url: "/uploads/{id}", filename, size, contentType}`
struct FileAttachment: Equatable, Identifiable, Sendable {
    let name: String
    /// 예) 1.2MB
    let sizeText: String
    /// 업로드 id — 없으면 내려받을 수 없어요.
    var fileId: String? = nil

    var id: String { fileId ?? name }
    var canDownload: Bool { fileId?.isEmpty == false }

    /// 서버 첨부 한 개 → 앱 첨부 (`url` 만 있으면 "/uploads/9" 에서 id 를 꺼내요)
    static func uploadId(id: String?, url: String?) -> String? {
        if let id, !id.isEmpty { return id }
        guard let url, let range = url.range(of: "/uploads/") else { return nil }
        let rest = url[range.upperBound...].split(separator: "?").first.map(String.init) ?? ""
        return rest.isEmpty ? nil : rest
    }

    static func sizeText(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
