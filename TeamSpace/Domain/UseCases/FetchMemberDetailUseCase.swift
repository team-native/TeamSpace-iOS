import Foundation

struct FetchMemberDetailUseCase {
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func execute(id: Int) async throws -> MemberDetail {
        try await memberRepository.fetchMember(id: id)
    }
}
