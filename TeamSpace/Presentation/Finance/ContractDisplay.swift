import SwiftUI

extension CollectionStatus {
    var title: String {
        switch self {
        case .collected: return "수금 완료"
        case .scheduled: return "수금 예정"
        case .unknown: return "확인 필요"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .collected: return .positive
        case .scheduled: return .warning
        case .unknown: return .neutral
        }
    }
}

extension ContractStep {
    /// "09.02 · 계약서 서명"
    var caption: String {
        guard let date else { return note }
        return "\(TSFormat.shortDate(date)) · \(note)"
    }
}

/// 04-3 필터 칩
enum CollectionFilter: Hashable, CaseIterable {
    case all
    case collected
    case scheduled

    var title: String {
        switch self {
        case .all: return "전체"
        case .collected: return "수금 완료"
        case .scheduled: return "수금 예정"
        }
    }

    func matches(_ contract: FinanceContract) -> Bool {
        switch self {
        case .all: return true
        case .collected: return contract.status == .collected
        case .scheduled: return contract.status == .scheduled
        }
    }
}

/// 04-3 정렬
enum CollectionSort: Hashable, CaseIterable {
    case latest
    case amount

    var title: String {
        switch self {
        case .latest: return "최신순"
        case .amount: return "금액 큰 순"
        }
    }
}

/// 이니셜 타일 (B · M · C …) — 이름으로 색을 정해 항상 같은 색이 나와요
struct InitialTile: View {
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .tsFont(.calloutBold)
            .foregroundStyle(palette.foreground)
            .frame(width: size, height: size)
            .background(palette.background, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .accessibilityHidden(true)
    }

    private var palette: (foreground: Color, background: Color) {
        let tones: [(Color, Color)] = [
            (.tsPrimary, .tsPrimarySoft),
            (.tsInk2, .tsSurface2),
            (.tsApricot, .tsApricotSoft)
        ]
        let index = name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % tones.count
        return tones[index]
    }
}

/// 04-3 한 줄 — 이니셜 · 이름 · 상태 · 날짜 / 금액 · 내용
struct FinanceContractRow: View {
    let contract: FinanceContract

    var body: some View {
        HStack(spacing: Spacing.md) {
            InitialTile(name: contract.name)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(contract.name)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                HStack(spacing: Spacing.xs) {
                    StatusBadge(title: contract.status.title, tone: contract.status.tone, size: .small)
                    Text(TSFormat.shortDate(contract.collectedAt))
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            Spacer(minLength: Spacing.sm)
            VStack(alignment: .trailing, spacing: Spacing.xxxs) {
                Text(TSFormat.won(contract.amount))
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Text(contract.title)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, Spacing.md + Spacing.xxxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
