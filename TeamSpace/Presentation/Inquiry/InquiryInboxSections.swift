import SwiftUI

/// 11-5 위 — 권한 배지 · 제목 · 열람 범위 안내
struct InquiryInboxHeader: View {
    let roleTitle: String
    let department: InquiryDepartment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            StatusBadge(title: roleTitle, tone: .primary, icon: .lock, size: .small)
            Text("팀의 목소리에 답해요")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            InfoBanner(
                message: "현재 계정은 \(department.title)에 배정된 문의만 볼 수 있어요. "
                    + "다른 부서 문의와 작성자 신원은 임의로 열람할 수 없어요. 일반 구성원에게는 이 받은함이 보이지 않아요.",
                icon: .shield,
                style: .muted
            )
        }
        .padding(.top, Spacing.sm)
    }
}

/// 11-5 부서 칩 — 내 부서만 열리고 나머지는 잠겨 있어요.
struct InquiryDepartmentLockBar: View {
    let department: InquiryDepartment

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(InquiryDepartment.selectable.sorted { $0 == department && $1 != department }, id: \.self) { item in
                    let isMine = item == department
                    HStack(spacing: Spacing.xxs) {
                        Text(item.title)
                            .tsFont(isMine ? .captionBold : .captionMedium)
                        if !isMine {
                            TSIcon.lock.sized(.xs)
                        }
                    }
                    .foregroundStyle(isMine ? Color.tsOnPrimary : Color.tsInk3)
                    .padding(.horizontal, Spacing.md)
                    .frame(height: 30)
                    .background(isMine ? Color.tsPrimary : Color.tsSurface2, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(isMine ? "\(item.title) 받은함" : "\(item.title) 받은함, 잠김")
                }
            }
            .padding(1)
        }
    }
}

/// 11-5 상태 칩 (개수 포함)
struct InquiryInboxFilterBar: View {
    @Bindable var viewModel: InquiryInboxViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(viewModel.filters, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        count: viewModel.count(of: filter),
                        isSelected: viewModel.filter == filter
                    ) { viewModel.filter = filter }
                }
            }
            .padding(1)
        }
    }
}

/// 11-5 문의 카드 — 접수일 · 익명 · 상태 · 제목 · 담당 · 다음 할 일
struct InquiryInboxCard: View {
    let item: InquiryInboxItem
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(item.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: item.inquiry.status, size: .small)
            }
            WorkspaceItemText(title: item.inquiry.title, meta: item.assigneeText)
            WorkspaceLinkRow(title: item.actionTitle, action: onOpen)
        }
    }
}

/// 11-5 최근 처리 이력
struct InquiryInboxLogCard: View {
    let logs: [InquiryInboxLog]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "최근 처리 이력")
            ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                if index > 0 { TSDivider() }
                WorkspaceItemText(title: log.title, meta: log.detailText)
            }
        }
    }
}
