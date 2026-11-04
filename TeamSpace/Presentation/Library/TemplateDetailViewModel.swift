import Foundation
import Observation

@Observable
@MainActor
final class TemplateDetailViewModel {
    private(set) var state: ViewState<LibraryTemplate> = .idle
    private let templateId: String
    private let fetchTemplateUseCase: FetchLibraryTemplateUseCase
    /// 원본 양식 파일 내려받기
    let attachmentDownloader: AttachmentDownloadViewModel?

    init(
        templateId: String,
        fetchTemplateUseCase: FetchLibraryTemplateUseCase,
        attachmentDownloader: AttachmentDownloadViewModel? = nil
    ) {
        self.templateId = templateId
        self.fetchTemplateUseCase = fetchTemplateUseCase
        self.attachmentDownloader = attachmentDownloader
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await fetchTemplateUseCase.execute(id: templateId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "library.template")
            state = .failed(error)
        }
    }
}
