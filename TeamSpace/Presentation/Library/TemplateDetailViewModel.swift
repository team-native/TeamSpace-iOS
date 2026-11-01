import Foundation
import Observation

@Observable
@MainActor
final class TemplateDetailViewModel {
    private(set) var state: ViewState<LibraryTemplate> = .idle
    private let templateId: Int
    private let fetchTemplateUseCase: FetchLibraryTemplateUseCase

    init(templateId: Int, fetchTemplateUseCase: FetchLibraryTemplateUseCase) {
        self.templateId = templateId
        self.fetchTemplateUseCase = fetchTemplateUseCase
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
