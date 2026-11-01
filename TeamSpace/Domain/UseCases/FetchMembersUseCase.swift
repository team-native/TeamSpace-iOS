import Foundation

struct FetchMembersUseCase {
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    /// 부서 순서(Leader → NativeOps → …) 다음 이름 순으로 정렬합니다.
    func execute() async throws -> [Member] {
        let order = Department.allCases
        return try await memberRepository.fetchMembers().sorted {
            let left = order.firstIndex(of: $0.department) ?? order.count
            let right = order.firstIndex(of: $1.department) ?? order.count
            return left == right ? $0.name < $1.name : left < right
        }
    }
}
