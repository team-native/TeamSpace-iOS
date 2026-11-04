import Foundation

/// 첨부 파일 내려받기 — GET /uploads/{id}
protocol UploadRepository: Sendable {
    /// 받은 파일을 기기 임시 폴더에 `filename` 으로 저장하고 그 주소를 돌려줘요.
    func download(id: String, filename: String) async throws -> URL
}
