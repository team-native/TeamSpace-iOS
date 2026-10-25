import Foundation
import Observation

/// 08-1 전체 프로젝트 탐색
@Observable
@MainActor
final class ProjectListViewModel {
    private(set) var state: ViewState<[ProjectSummary]> = .idle
    var query = ""
    var statusFilter: ProjectStatusFilter = .all
    /// nil = 부서 전체
    var department: String?
    var recruitingOnly = false
    var interestOnly = false
    /// 내 관심 직군 (07-13 프로필 관심사)
    private(set) var interests: [String] = []

    private let fetchProjectsUseCase: FetchProjectsUseCase
    private let fetchProfileUseCase: FetchProfileUseCase

    init(fetchProjectsUseCase: FetchProjectsUseCase, fetchProfileUseCase: FetchProfileUseCase) {
        self.fetchProjectsUseCase = fetchProjectsUseCase
        self.fetchProfileUseCase = fetchProfileUseCase
    }

    private var all: [ProjectSummary] { state.value ?? [] }

    /// 부서 칩 메뉴 — 프로젝트에 있는 부서만
    var departments: [String] {
        Array(Set(all.map(\.department))).sorted()
    }

    var departmentTitle: String {
        department ?? "부서 전체"
    }

    var projects: [ProjectSummary] {
        all.filter { project in
            (statusFilter.status == nil || project.status == statusFilter.status)
                && (department == nil || project.department == department)
                && (!recruitingOnly || project.isRecruiting)
                && (!interestOnly || project.recruitsAny(of: interests))
                && project.matches(query)
        }
    }

    /// "전체 프로젝트 4개"
    var countText: String {
        "\(statusFilter == .all ? "전체" : statusFilter.title) 프로젝트 \(projects.count)개"
    }

    var emptyMessage: String {
        interestOnly && interests.isEmpty
            ? "프로필에 관심사를 추가하면 맞는 모집을 찾아드려요."
            : "조건에 맞는 프로젝트가 없어요. 검색어나 필터를 바꿔 보세요."
    }

    func load() async {
        if state.value == nil { state = .loading }
        async let profile = try? fetchProfileUseCase.execute()
        do {
            state = .loaded(try await fetchProjectsUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "project.list.load")
            if state.value == nil { state = .failed(error) }
        }
        let loadedProfile = await profile
        interests = loadedProfile?.interests ?? []
    }
}
