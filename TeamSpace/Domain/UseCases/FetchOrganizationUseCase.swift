import Foundation

struct FetchOrganizationUseCase {
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    /// 구성원이 없는 부서는 조직도에서 숨깁니다.
    func execute() async throws -> OrganizationTree {
        let tree = try await memberRepository.fetchOrganization()
        return OrganizationTree(leader: tree.leader, units: tree.units.filter { !$0.members.isEmpty })
    }
}
