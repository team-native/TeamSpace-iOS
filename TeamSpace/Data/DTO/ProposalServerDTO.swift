import Foundation

/// GET /proposals · /proposals/{id} 의 한 항목 (TeamSpace-backend develop `community._proposal_view`)
/// 익명이면 author · dept 가 없어요. comments 는 상세에만 있어요.
struct ServerProposalDTO: Decodable {
    struct History: Decodable {
        let status: String
        let at: Date?
    }

    struct Answer: Decodable {
        let who: String?
        let at: Date?
        let text: String
    }

    let id: Int
    /// 앱은 대상 부서를 category 로 보내요.
    let category: String
    let title: String
    let body: String
    let status: String
    let anonymous: Bool
    let recommendCount: Int
    let commentCount: Int
    let createdAt: Date
    let mine: Bool
    let author: String?
    /// 작성자 조직도 id — 익명이면 빈 값
    let authorId: String?
    let answer: Answer?
    let history: [History]
    let comments: [ServerProposalCommentDTO]?
    /// 조회 수 — 상세를 열 때마다 서버가 1씩 올려요.
    let views: Int?
    /// 내가 추천했는지 (상세에만 있어요)
    let recommended: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        category = (try? container.decodeIfPresent(String.self, forKey: .category)) ?? ""
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        body = (try? container.decodeIfPresent(String.self, forKey: .body)) ?? ""
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "접수"
        anonymous = (try? container.decodeIfPresent(Bool.self, forKey: .anonymous)) ?? false
        recommendCount = (try? container.decodeIfPresent(Int.self, forKey: .recommendCount))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .likes)) ?? 0
        commentCount = (try? container.decodeIfPresent(Int.self, forKey: .commentCount)) ?? 0
        createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        mine = (try? container.decodeIfPresent(Bool.self, forKey: .mine)) ?? false
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        authorId = (try? container.decodeStringOrInt(forKey: .authorId)).flatMap { $0.isEmpty ? nil : $0 }
        answer = try? container.decodeIfPresent(Answer.self, forKey: .answer)
        history = (try? container.decodeIfPresent([History].self, forKey: .history)) ?? []
        comments = try? container.decodeIfPresent([ServerProposalCommentDTO].self, forKey: .comments)
        views = try? container.decodeIfPresent(Int.self, forKey: .views)
        recommended = try? container.decodeIfPresent(Bool.self, forKey: .recommended)
    }

    private enum CodingKeys: String, CodingKey {
        case id, category, title, body, status, anonymous, likes, recommendCount, commentCount, createdAt, mine, author
        case answer, history, comments, views, recommended, authorId
    }

    func toEntity() -> ProposalSummary {
        ProposalSummary(
            id: id,
            department: category,
            title: title,
            excerpt: ServerPostItemDTO.excerpt(of: body),
            isAnonymous: anonymous,
            authorName: anonymous ? nil : author,
            createdAt: createdAt,
            status: ProposalStatus(serverValue: status),
            recommendCount: recommendCount,
            commentCount: commentCount,
            isMine: mine
        )
    }

    func toDetail() -> ProposalDetail {
        let summary = toEntity()
        return ProposalDetail(
            proposal: summary,
            body: body,
            viewCount: views,
            isRecommended: recommended ?? false,
            steps: history.compactMap { item in
                item.at.map { ProposalStep(status: ProposalStatus(serverValue: item.status).step, reachedAt: $0) }
            },
            answer: answer.map {
                ProposalAnswer(department: category.isEmpty ? $0.who ?? "운영진" : category, body: $0.text, answeredAt: $0.at ?? createdAt)
            },
            comments: (comments ?? []).map {
                $0.toEntity(proposalAuthor: anonymous ? nil : author, proposalAuthorId: anonymous ? nil : authorId)
            }
        )
    }
}

/// 상세의 댓글 · POST /proposals/{id}/comments 응답
/// 익명 제안에 제안자가 단 댓글은 author 가 "글쓴이"예요.
struct ServerProposalCommentDTO: Decodable {
    static let proposerLabel = "글쓴이"

    let id: Int
    let text: String
    let createdAt: Date?
    let anonymous: Bool
    let mine: Bool?
    let author: String?
    let anonymousNumber: Int?
    /// 작성자 조직도 id — 익명이면 빈 값
    let authorId: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        anonymousNumber = try? container.decodeIfPresent(Int.self, forKey: .anonymousNumber)
        text = (try? container.decodeIfPresent(String.self, forKey: .text)) ?? ""
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        anonymous = (try? container.decodeIfPresent(Bool.self, forKey: .anonymous)) ?? false
        mine = try? container.decodeIfPresent(Bool.self, forKey: .mine)
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        authorId = (try? container.decodeStringOrInt(forKey: .authorId)).flatMap { $0.isEmpty ? nil : $0 }
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, createdAt, anonymous, mine, author, anonymousNumber, authorId
    }

    /// 실명 제안이면 제안자 id 로 제안자 댓글을 알아봐요. id 가 없으면(옛 서버) 같은 이름으로 봐요.
    func toEntity(proposalAuthor: String?, proposalAuthorId: String? = nil, now: Date = Date()) -> ProposalComment {
        let isSameAuthor: Bool
        if let proposalAuthorId, let authorId {
            isSameAuthor = proposalAuthorId == authorId
        } else {
            isSameAuthor = author != nil && author == proposalAuthor
        }
        let isProposer = author == Self.proposerLabel || (!anonymous && isSameAuthor)
        return ProposalComment(
            id: id,
            authorName: anonymous || author == Self.proposerLabel ? nil : author,
            isAnonymous: anonymous || author == Self.proposerLabel,
            isProposer: isProposer,
            isMine: mine ?? true,
            body: text,
            createdAt: createdAt ?? now,
            anonymousNumber: isProposer ? nil : anonymousNumber ?? ServerCommentDTO.anonymousNumber(from: author)
        )
    }
}

/// POST /proposals/{id}/recommend 응답
struct ServerProposalRecommendDTO: Decodable {
    let recommended: Bool
    let recommendCount: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recommended = try container.decode(Bool.self, forKey: .recommended)
        recommendCount = (try? container.decodeIfPresent(Int.self, forKey: .recommendCount))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .likes)) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case recommended, recommendCount, likes
    }
}

/// POST /proposals/{id}/comments 요청
struct ServerProposalCommentRequestDTO: Codable, Equatable {
    let text: String
    let anonymous: Bool
}

/// PATCH /admin/proposals/{id} 요청 — 답변이 없으면 `answer` 를 보내지 않아요. (답변이 있으면 서버가 반려가 아닌 한 답변 완료로 바꿔요)
struct ServerProposalManageRequestDTO: Codable, Equatable {
    let status: String
    let answer: String?
}

/// POST /proposals 응답 `{id, status}`
struct ServerProposalCreatedDTO: Decodable {
    let id: Int
    let status: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case id, status
    }
}

/// POST /proposals 요청 — 대상 부서를 category 와 dept 에 함께 넣어요.
/// (dept 는 서버가 담당 부서 권한 확인에 써요. 응답의 dept 는 실명 작성자의 소속이라 category 로 읽어요.)
struct ServerProposalCreateRequestDTO: Codable, Equatable {
    let title: String
    let body: String
    let category: String
    let dept: String
    let anonymous: Bool
}

/// PATCH /proposals/{id} 요청 (`ProposalPatch`) — 익명 여부는 못 바꿔요.
struct ServerProposalPatchRequestDTO: Codable, Equatable {
    let title: String
    let body: String
    let category: String
    let dept: String
}

extension ProposalStatus {
    /// 서버 상태 (접수 · 검토 중 · 협업 중 · 답변 완료 · 반려), 예전 영문 값도 받아요.
    init(serverValue: String) {
        switch serverValue.trimmingCharacters(in: .whitespaces) {
        case "접수": self = .received
        case "검토 중", "검토중": self = .reviewing
        case "협업 중", "협업중", "진행 중": self = .inProgress
        case "답변 완료": self = .answered
        case "반려": self = .rejected
        case "완료": self = .completed
        default: self = ProposalStatus(rawValue: serverValue) ?? .unknown
        }
    }

    /// 목 서버에서 쓰는 서버 상태 이름
    var serverValue: String {
        switch self {
        case .received, .unknown: return "접수"
        case .reviewing: return "검토 중"
        case .inProgress: return "협업 중"
        case .completed, .answered, .adopted, .closed: return "답변 완료"
        case .rejected: return "반려"
        }
    }

    /// 12-2b 4단계 중 어디에 해당하는지 — 답변 완료 · 반려는 마지막 단계(완료)
    var step: ProposalStatus {
        switch self {
        case .answered, .adopted, .closed, .rejected: return .completed
        default: return self
        }
    }
}
