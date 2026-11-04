import Foundation

final class UploadRepositoryImpl: UploadRepository, @unchecked Sendable {
    private let client: APIClient
    private let directory: URL

    init(client: APIClient, directory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("Attachments", isDirectory: true)) {
        self.client = client
        self.directory = directory
    }

    func download(id: String, filename: String) async throws -> URL {
        let data: Data
        do {
            data = try await client.data(Endpoint(method: .get, path: "uploads/\(id)"))
        } catch let error as NetworkError {
            throw error.asAppError
        }
        // 같은 이름 파일이 겹치지 않게 id 폴더에 저장해요.
        let folder = directory.appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(Self.safeName(filename))
        try data.write(to: url, options: .atomic)
        return url
    }

    /// 경로 문자를 빼요. 비면 "file"
    static func safeName(_ filename: String) -> String {
        let cleaned = filename
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty || cleaned.hasPrefix(".") ? "file" + cleaned : cleaned
    }
}
