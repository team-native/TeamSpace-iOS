import Foundation

/// 10-5 분류 칩 — 전체 · 공지 · 재무 · 규칙
enum NoticeFilter: Hashable {
    case all
    case category(NoticeCategory)

    static let allCases: [NoticeFilter] = [.all, .category(.notice), .category(.finance), .category(.rule)]

    var title: String {
        switch self {
        case .all: return "전체"
        case .category(let category): return category.title
        }
    }

    func matches(_ notice: NoticeSummary) -> Bool {
        switch self {
        case .all: return true
        case .category(let category): return notice.category == category
        }
    }
}

extension NoticeSummary {
    /// "고정 · 10.01" / "어제" / "3일 전" / "10.10"
    func dateText(now: Date = Date()) -> String {
        isPinned ? "고정 · \(TSFormat.shortDate(updatedAt))" : TSFormat.dayLabel(updatedAt, now: now)
    }
}

extension NoticeDetail {
    /// "김민준 · FA"
    var authorText: String { "\(authorName) · \(authorRole)" }

    /// "2026.10.10 · 조회 52"
    var metaText: String { "\(TSFormat.fullDate(notice.updatedAt)) · 조회 \(viewCount)" }

    /// 아래 버튼 — "확인했어요" / "10.18 확인 완료"
    var acknowledgeTitle: String {
        acknowledgedAt.map { "\(TSFormat.shortDate($0)) 확인 완료" } ?? "확인했어요"
    }
}

extension NoticeLinkedDocument {
    /// "문서함 · FINANCE"
    var caption: String { "문서함 · \(category.rawValue)" }

    /// 규칙은 09-2, 템플릿은 06-3, 나머지는 준비 중 화면
    var route: AppRoute {
        switch category {
        case .rule: return .ruleDetail(id: id)
        case .template: return .templateDetail(id: id)
        default: return .comingSoon(title: title)
        }
    }
}

extension NoticeAudience {
    var title: String {
        switch self {
        case .native: return "Native"
        case .inspace: return "Inspace"
        }
    }

    /// "Native 전체 구성원에게 게시해요. Inspace를 선택하면 대상 조직이 달라져요."
    var note: String {
        let other: NoticeAudience = self == .native ? .inspace : .native
        return "\(title) 전체 구성원에게 게시해요. \(other.title)를 선택하면 대상 조직이 달라져요."
    }
}

extension NoticeDraft {
    /// 10-7 게시 전 확인
    var checklist: [String] {
        let marks: String
        switch (isImportant, isPinned) {
        case (true, true): marks = "중요 표시·상단 고정 사용"
        case (true, false): marks = "중요 표시 사용"
        case (false, true): marks = "상단 고정 사용"
        case (false, false): marks = "중요 표시·상단 고정 사용 안 함"
        }
        let timingText = timing == .scheduled ? "\(Self.scheduleText(scheduledAt)) 예약 게시" : "지금 바로 게시"
        return [
            "대상: \(audience.title) 전체",
            marks,
            timingText,
            sendsPush ? "전체 공지 카테고리로 알림 생성" : "알림 없이 게시"
        ]
    }

    /// "대상 확인 · 예약 게시 확정"
    var publishTitle: String {
        timing == .scheduled ? "대상 확인 · 예약 게시 확정" : "대상 확인 · 지금 게시"
    }

    /// "10.17 09:00"
    static func scheduleText(_ date: Date) -> String {
        "\(TSFormat.shortDate(date)) \(TSFormat.time(date))"
    }
}

extension NoticeAttachment {
    /// "240KB · 업로드 완료"
    var sizeText: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(data.count))) · 업로드 완료"
    }
}
