import Foundation
import Observation

/// 첨부 파일 눌러 내려받기 → 미리보기 (결재 · 공지 상세가 함께 써요)
@Observable
@MainActor
final class AttachmentDownloadViewModel {
    private(set) var downloadingId: String?
    /// 내려받은 파일 — 있으면 미리보기를 열어요.
    var previewURL: URL?
    var errorMessage: String?

    private let downloadAttachmentUseCase: DownloadAttachmentUseCase

    init(downloadAttachmentUseCase: DownloadAttachmentUseCase) {
        self.downloadAttachmentUseCase = downloadAttachmentUseCase
    }

    func open(_ file: FileAttachment) async {
        guard downloadingId == nil else { return }
        downloadingId = file.id
        defer { downloadingId = nil }
        do {
            previewURL = try await downloadAttachmentUseCase.execute(file)
        } catch {
            AppLog.record(error, context: "attachment.download")
            errorMessage = error.userMessage
        }
    }
}
