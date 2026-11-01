import Foundation

/// 07-11 내가 작성한 운영 제안 한 건
struct MyProposal: Equatable, Identifiable, Sendable {
    let id: Int
    /// 예) 업무환경 · 협업
    let category: String
    let title: String
    let body: String
    let authorName: String
    let createdAt: Date
    let status: ProposalStatus
    let recommendCount: Int
    let commentCount: Int
}
