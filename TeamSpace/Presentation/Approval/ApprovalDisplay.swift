import SwiftUI

extension ApprovalStatus: BadgeRepresentable {
    var badgeTitle: String {
        switch self {
        case .draft: return "작성 중"
        case .pending: return "결재 대기"
        case .reviewing: return "검토 중"
        case .approved: return "승인"
        case .rejected: return "반려"
        case .unknown: return "확인 중"
        }
    }

    var badgeTone: BadgeTone {
        switch self {
        case .draft, .unknown: return .neutral
        case .pending: return .amber
        case .reviewing: return .primary
        case .approved: return .positive
        case .rejected: return .negative
        }
    }

    /// 05-1 상단 요약 숫자 색
    var summaryColor: Color {
        switch self {
        case .draft, .unknown: return .tsInk3
        case .pending: return .tsAmber
        case .reviewing: return .tsPrimary
        case .approved: return .tsPositive
        case .rejected: return .tsNegative
        }
    }
}

extension ApprovalKind {
    var title: String {
        switch self {
        case .expense: return "비용"
        case .staffing: return "인력 지원"
        case .other: return "기타"
        case .unknown: return "결재"
        }
    }
}

/// 결재 탭 — 내가 올린 결재 / 받은 결재
enum ApprovalTab: Hashable, CaseIterable {
    case mine
    case received
}

extension ApprovalItem {
    /// "비용 · 오늘" / "비용 · 임시 저장" / "비용 · 10.02"
    var metaText: String {
        let when: String
        if status == .draft {
            when = "임시 저장"
        } else if Calendar.current.isDateInToday(updatedAt) {
            when = "오늘"
        } else if Calendar.current.isDateInYesterday(updatedAt) {
            when = "어제"
        } else {
            when = TSFormat.shortDate(updatedAt)
        }
        return "\(kind.title) · \(when)"
    }
}

/// 금액 + 작은 "원"
struct WonText: View {
    let amount: Int
    var size: CGFloat = 15

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(TSFormat.number(amount))
                .font(.system(size: size, weight: .bold))
            Text("원")
                .font(.system(size: size * 0.75, weight: .bold))
        }
        .foregroundStyle(Color.tsInk)
        .accessibilityElement(children: .combine)
    }
}
