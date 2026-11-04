import Foundation

/// 첨부 파일 내려받기 — 업로드 id 가 있는 파일만
struct DownloadAttachmentUseCase {
    private let uploadRepository: UploadRepository

    init(uploadRepository: UploadRepository) {
        self.uploadRepository = uploadRepository
    }

    func execute(_ file: FileAttachment) async throws -> URL {
        guard let id = file.fileId, file.canDownload else { throw AppError.invalidInput("내려받을 수 없는 파일이에요.") }
        return try await uploadRepository.download(id: id, filename: file.name)
    }
}
