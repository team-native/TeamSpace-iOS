import Foundation

/// 12 운영 제안 가짜 저장소 — Figma 12-1b · 12-2b 예시 (날짜는 오늘 기준)
/// 내 제안(12 · 11 · 9)은 07-11 내가 작성한 운영 제안과 같은 ID 예요.
final class MockProposalStore: @unchecked Sendable {
    private struct Record {
        var summary: ProposalSummaryDTO
        let body: String
        var viewCount: Int
        var steps: [ProposalStepDTO]
        let answer: ProposalAnswerDTO?
        var comments: [ProposalCommentDTO]
        var isRecommended = false
    }

    private static let me = "옥물결"
    private let lock = NSLock()
    private var records: [Record] = []

    init(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        func at(_ daysAgo: Double, _ hour: Double = 10) -> Date { today.addingTimeInterval(-daysAgo * 86_400 + hour * 3_600) }
        records = Self.seed(at: at)
    }

    private static func summary(
        _ id: Int, _ department: String, _ title: String, _ excerpt: String, author: String?, _ date: Date,
        _ status: ProposalStatus, recommend: Int, comments: Int, mine: Bool = false
    ) -> ProposalSummaryDTO {
        ProposalSummaryDTO(
            id: id, department: department, title: title, excerpt: excerpt, isAnonymous: author == nil,
            authorName: author, createdAt: date, status: status, recommendCount: recommend, commentCount: comments, isMine: mine
        )
    }

    /// 댓글 수만큼 만들어요. (앞의 몇 개는 Figma 예시)
    private static func comments(_ count: Int, after date: Date, first: [(String?, String)] = []) -> [ProposalCommentDTO] {
        let fillers: [(String?, String)] = [(nil, "좋은 제안이에요!"), ("양지우", "저도 필요하다고 느꼈어요."), ("안율", "검토 결과가 궁금해요.")]
        return (0..<count).map { index in
            let item = index < first.count ? first[index] : fillers[index % fillers.count]
            return ProposalCommentDTO(
                id: index + 1, authorName: item.0, isAnonymous: item.0 == nil, isProposer: false, isMine: false,
                body: item.1, createdAt: date.addingTimeInterval(Double(index + 1) * 3_600)
            )
        }
    }

    private static func seed(at: (Double, Double) -> Date) -> [Record] {
        let ops = "NativeOps"
        return [
            Record(
                summary: summary(16, ops, "스터디 회고를 TIL과 함께 올리면 좋겠어요",
                                 "지금 스터디 운영도 좋지만, 매주 TIL을 올릴 때 짧은 회고를 같이 쓰면 좋겠어요.",
                                 author: nil, at(3, 10), .reviewing, recommend: 32, comments: 7),
                body: "지금 스터디 운영도 좋지만, 매주 TIL을 올릴 때 짧은 회고를 같이 쓰면 배운 점이 더 오래 남을 것 같아요.\n\n"
                    + "회고 양식을 하나 만들어 공유하면 부담 없이 시작할 수 있어요.",
                viewCount: 127,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(3, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(2, 11))],
                answer: ProposalAnswerDTO(department: ops, body: "좋은 제안 감사해요. 다음 달 스터디부터 회고 양식을 시범으로 써 보고, 결과를 이 글에 다시 남길게요.",
                                          answeredAt: at(2, 11)),
                comments: comments(7, after: at(3, 10), first: [(nil, "회고 양식 생기면 바로 써 볼게요!"), ("이시우", "운영팀에서 양식 초안을 만들어 볼게요.")])
            ),
            Record(
                summary: summary(12, ops, "회의실 예약 현황을 한눈에 보고 싶어요", "회의실 예약이 겹치지 않게 캘린더로 확인하고 싶어요.",
                                 author: nil, at(7, 10), .reviewing, recommend: 32, comments: 2, mine: true),
                body: "예약이 겹치는 일이 잦아서, 이번 주 회의실 예약 현황을 앱에서 바로 볼 수 있으면 좋겠어요.",
                viewCount: 96,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(7, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(4, 10))],
                answer: nil,
                comments: comments(2, after: at(7, 10))
            ),
            Record(
                summary: summary(15, "NativeLab", "외주 견적 템플릿을 공유 문서로 만들어요", "견적서 양식을 팀 문서함에 올려두면 좋겠어요.",
                                 author: nil, at(9, 14), .inProgress, recommend: 21, comments: 4),
                body: "견적서 양식을 팀 문서함에 올려두면 처음 견적을 내는 팀원도 쉽게 따라 할 수 있어요.",
                viewCount: 74,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(9, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(8, 10)),
                        ProposalStepDTO(status: .inProgress, reachedAt: at(5, 10))],
                answer: ProposalAnswerDTO(department: "NativeLab", body: "템플릿 초안을 만들고 있어요. 이번 달 안에 문서함에 올릴게요.", answeredAt: at(5, 10)),
                comments: comments(4, after: at(9, 10))
            ),
            Record(
                summary: summary(11, "PMO", "회의 기록 양식을 통일해요", "회의 기록 양식을 통일시키면 더욱 보기 편할 것 같아요.",
                                 author: me, at(9, 10), .reviewing, recommend: 18, comments: 3, mine: true),
                body: "Book-on 회의부터 공통 양식을 시범 적용하면 좋겠어요.",
                viewCount: 58,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(9, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(8, 10))],
                answer: nil,
                comments: comments(3, after: at(9, 10))
            ),
            Record(
                summary: summary(14, "FA", "월 정산 내역을 팀 게시판에 공개해요", "정산 기준과 내역을 매달 공지로 안내해 주세요.",
                                 author: "이시우", at(14, 15), .completed, recommend: 45, comments: 11),
                body: "정산 기준과 내역을 매달 공지로 안내해 주시면 모두가 같은 기준으로 이해할 수 있어요.",
                viewCount: 203,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(14, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(13, 10)),
                        ProposalStepDTO(status: .inProgress, reachedAt: at(10, 10)), ProposalStepDTO(status: .completed, reachedAt: at(1, 10))],
                answer: ProposalAnswerDTO(department: "FA", body: "이번 달부터 정산 기준 안내를 공지로 올리고 있어요. 공지 · 재무 분류에서 확인해 주세요.", answeredAt: at(1, 10)),
                comments: comments(11, after: at(14, 10))
            ),
            Record(
                summary: summary(9, ops, "집중 업무 시간을 캘린더에 표시해요", "서로의 집중 시간을 존중할 수 있도록 공통 표기 방식을 제안해요.",
                                 author: me, at(14, 10), .answered, recommend: 9, comments: 2, mine: true),
                body: "서로의 집중 시간을 존중할 수 있도록 공통 표기 방식을 제안해요.",
                viewCount: 40,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(14, 10)), ProposalStepDTO(status: .reviewing, reachedAt: at(12, 10))],
                answer: ProposalAnswerDTO(department: ops, body: "캘린더에 ‘집중’ 태그를 쓰는 방식으로 안내할게요.", answeredAt: at(11, 10)),
                comments: comments(2, after: at(14, 10))
            ),
            Record(
                summary: summary(13, ops, "프로젝트 회고 시간을 정기 일정으로 넣어요", "프로젝트가 끝나면 회고 일정을 자동으로 잡아주세요.",
                                 author: nil, at(17, 10), .received, recommend: 14, comments: 3),
                body: "프로젝트가 끝나면 회고 일정을 자동으로 잡아주시면 잊지 않고 회고할 수 있어요.",
                viewCount: 35,
                steps: [ProposalStepDTO(status: .received, reachedAt: at(17, 10))],
                answer: nil,
                comments: comments(3, after: at(17, 10))
            )
        ]
    }

    /// GET /proposals
    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(ProposalListResponseDTO(list: records.map(\.summary)))
    }

    /// GET /proposals/{id} — 볼 때마다 조회 수 +1
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.summary.id == id }) else { return nil }
        records[index].viewCount += 1
        let record = records[index]
        return envelope(ProposalDetailDTO(
            proposal: record.summary, body: record.body, viewCount: record.viewCount, isRecommended: record.isRecommended,
            steps: record.steps, answer: record.answer, comments: record.comments
        ))
    }

    /// POST /proposals/{id}/recommend
    func toggleRecommend(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.summary.id == id }) else { return nil }
        records[index].isRecommended.toggle()
        records[index].summary.recommendCount += records[index].isRecommended ? 1 : -1
        return envelope(ProposalRecommendResponseDTO(
            isRecommended: records[index].isRecommended, recommendCount: records[index].summary.recommendCount
        ))
    }

    /// POST /proposals/{id}/comments
    func addComment(id: Int, request: ProposalCommentRequestDTO) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.summary.id == id }) else { return nil }
        let comment = ProposalCommentDTO(
            id: (records[index].comments.map(\.id).max() ?? 0) + 1,
            authorName: request.isAnonymous ? nil : Self.me,
            isAnonymous: request.isAnonymous,
            isProposer: records[index].summary.isMine,
            isMine: true,
            body: request.body,
            createdAt: Date()
        )
        records[index].comments.append(comment)
        records[index].summary.commentCount += 1
        return envelope(comment)
    }

    private func envelope<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
