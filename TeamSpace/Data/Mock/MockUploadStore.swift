import Foundation

/// 업로드 파일 Mock — POST /uploads 로 받은 파일과 예시 첨부(결재 9 · 공지 21)를 GET /uploads/{id} 로 돌려줘요.
final class MockUploadStore: @unchecked Sendable {
    struct File {
        let filename: String
        let data: Data
    }

    private let lock = NSLock()
    private var files: [String: File] = [
        "9": File(filename: "견적서_iPhone.pdf", data: Data("%PDF-1.4 mock quote".utf8)),
        "21": File(filename: "10월_정산표.csv", data: Data("프로젝트,금액\nBook-on,1500000\n".utf8))
    ]

    func save(id: String, filename: String, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        files[id] = File(filename: filename, data: data)
    }

    func file(id: String) -> File? {
        lock.lock()
        defer { lock.unlock() }
        return files[id]
    }
}
