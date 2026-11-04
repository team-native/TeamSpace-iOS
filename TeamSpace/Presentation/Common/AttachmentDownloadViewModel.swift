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
    /// 미리 받아 둔 파일 (게시글 사진 썸네일)
    private(set) var localURLs: [String: URL] = [:]
    private(set) var failedIds: Set<String> = []

    private let downloadAttachmentUseCase: DownloadAttachmentUseCase

    init(downloadAttachmentUseCase: DownloadAttachmentUseCase) {
        self.downloadAttachmentUseCase = downloadAttachmentUseCase
    }

    /// 화면에 바로 보여줄 파일을 받아 둬요. 실패하면 알림 없이 자리만 표시해요.
    func prefetch(_ file: FileAttachment) async {
        guard localURLs[file.id] == nil else { return }
        do {
            localURLs[file.id] = try await downloadAttachmentUseCase.execute(file)
            failedIds.remove(file.id)
        } catch {
            AppLog.record(error, context: "attachment.prefetch")
            failedIds.insert(file.id)
        }
    }

    func open(_ file: FileAttachment) async {
        if let url = localURLs[file.id] {
            previewURL = url
            return
        }
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
