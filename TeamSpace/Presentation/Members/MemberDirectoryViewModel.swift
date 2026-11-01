import Foundation
import Observation

/// 03 팀원 소개 — 목록 · 조직도
@Observable
@MainActor
final class MemberDirectoryViewModel {
    /// 처음에 보여줄 인원 (Figma: 8명 + "N명 더 보기")
    static let collapsedCount = 8

    private(set) var state: ViewState<[Member]> = .idle
    private(set) var organizationState: ViewState<OrganizationTree> = .idle
    var mode: MemberDirectoryMode = .list
    var query = ""
    var departmentFilter: MemberDepartmentFilter = .all
    var isExpanded = false

    private let fetchMembersUseCase: FetchMembersUseCase
    private let fetchOrganizationUseCase: FetchOrganizationUseCase

    init(fetchMembersUseCase: FetchMembersUseCase, fetchOrganizationUseCase: FetchOrganizationUseCase) {
        self.fetchMembersUseCase = fetchMembersUseCase
        self.fetchOrganizationUseCase = fetchOrganizationUseCase
    }

    private var members: [Member] {
        state.value ?? []
    }

    /// "Native 24명 · 5개 부서"
    var summary: String {
        let departments = Set(members.map(\.department)).subtracting([.leader, .unknown])
        return "Native \(members.count)명 · \(departments.count)개 부서"
    }

    /// 칩에 보여줄 부서 (구성원이 있는 부서만)
    var departmentFilters: [MemberDepartmentFilter] {
        let present = Set(members.map(\.department))
        return [.all] + Department.allCases.filter { present.contains($0) }.map { .department($0) }
    }

    func title(for filter: MemberDepartmentFilter) -> String {
        switch filter {
        case .all: return "전체 \(members.count)"
        case .department(let department): return department.directoryName
        }
    }

    /// 검색어 · 부서 필터를 적용한 목록
    var filteredMembers: [Member] {
        let keyword = query.trimmingCharacters(in: .whitespaces).lowercased()
        return members.filter { member in
            guard departmentFilter.matches(member) else { return false }
            guard !keyword.isEmpty else { return true }
            return [member.name, member.tag, member.position, member.department.directoryName]
                .contains { $0.lowercased().contains(keyword) }
        }
    }

    /// 검색 중이거나 펼쳤으면 전부, 아니면 앞 8명
    var visibleMembers: [Member] {
        isShowingAll ? filteredMembers : Array(filteredMembers.prefix(Self.collapsedCount))
    }

    var hiddenCount: Int {
        isShowingAll ? 0 : max(filteredMembers.count - Self.collapsedCount, 0)
    }

    private var isShowingAll: Bool {
        isExpanded || !query.isEmpty || departmentFilter != .all
    }

    /// 이번 주 새 멤버 (최근 7일 안에 합류)
    func newMember(now: Date = Date()) -> Member? {
        let weekAgo = now.addingTimeInterval(-7 * 86_400)
        return members.filter { $0.joinedAt >= weekAgo }.max { $0.joinedAt < $1.joinedAt }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let result = try await fetchMembersUseCase.execute()
            state = result.isEmpty ? .empty : .loaded(result)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "members.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 조직도는 처음 열 때 한 번 불러옵니다.
    func loadOrganizationIfNeeded() async {
        guard organizationState.value == nil else { return }
        organizationState = .loading
        do {
            organizationState = .loaded(try await fetchOrganizationUseCase.execute())
        } catch AppError.forbidden {
            organizationState = .forbidden
        } catch {
            AppLog.record(error, context: "organization.load")
            organizationState = .failed(error)
        }
    }

    /// 조직도에서 부서를 누르면 그 부서 목록으로 이동
    func showMembers(of department: Department) {
        departmentFilter = .department(department)
        query = ""
        mode = .list
    }
}
