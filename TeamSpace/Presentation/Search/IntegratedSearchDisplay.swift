import Foundation

extension SearchHit {
    /// 카드 위 배지 — "운영 규정" · "공개 게시글" …
    var badgeTitle: String? {
        switch category {
        case .documents:
            switch documentType?.uppercased() {
            case "RULE", "POLICY": return "운영 규정"
            case "TEMPLATE": return "템플릿"
            case "PROJECT": return "프로젝트 문서"
            case "FINANCE": return "재무 문서"
            default: return "문서"
            }
        case .people: return "공개 프로필"
        case .posts: return "공개 게시글"
        case .proposals: return "운영 제안"
        case .projects: return nil
        }
    }

    /// "2" → "v2", "v1.3" 은 그대로
    var versionText: String? {
        guard let version, !version.isEmpty else { return nil }
        return version.first?.isNumber == true ? "v\(version)" : version
    }

    var isRule: Bool {
        ["RULE", "POLICY"].contains(documentType?.uppercased() ?? "")
    }

    /// 카드 아래 회색 한 줄
    var metaText: String {
        let date = createdAt.map(TSFormat.shortDate)
        switch category {
        case .documents:
            return [versionText, date.map { "\($0) 수정" }].compactMap { $0 }.joined(separator: " · ")
        case .projects:
            let progressText = progress.map { "진행률 \($0)%" }
            return [department, pmName.map { "PM \($0)" }, progressText].compactMap { $0 }.joined(separator: " · ")
        case .people:
            return snippet
        case .posts:
            return [author, date, commentCount.map { "댓글 \($0)" }].compactMap { $0 }.joined(separator: " · ")
        case .proposals:
            let status = proposalStatus.flatMap { $0 == .unknown ? nil : $0.title }
            return [author, date, likeCount.map { "추천 \($0)" }, status].compactMap { $0 }.joined(separator: " · ")
        }
    }

    /// 카드 아래 이동 문구
    var linkTitle: String {
        switch category {
        case .documents: return isRule ? "규정 본문 보기" : "문서 열기"
        case .projects: return "프로젝트 보기"
        case .people: return "팀원 소개 보기"
        case .posts: return "게시글 보기"
        case .proposals: return "운영 제안 상세 보기"
        }
    }

    var route: AppRoute {
        // 문서는 서버 slug 그대로 열어요.
        if category == .documents {
            let slug = documentSlug ?? serverId
            if isRule { return .ruleDetail(id: slug) }
            return documentType?.uppercased() == "TEMPLATE" ? .templateDetail(id: slug) : .comingSoon(title: title)
        }
        guard let id = targetId else { return .comingSoon(title: title) }
        switch category {
        case .documents: return .comingSoon(title: title)
        case .projects: return .projectDetail(id: id)
        case .people: return .memberDetail(id: id)
        case .posts: return .postDetail(id: id)
        case .proposals: return .proposalDetail(id: id)
        }
    }
}
