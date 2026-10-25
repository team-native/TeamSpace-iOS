import SwiftUI

/// 07-3 프로필 — 미모티콘 · 이름 · 소속 · 프로필 편집
struct WorkspaceMenuProfileCard: View {
    let name: String
    let affiliation: String?
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(size: 45)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("\(name) 님")
                    .tsFont(.subheadline)
                    .foregroundStyle(Color.tsInk)
                if let affiliation {
                    Text(affiliation)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.sm)
            Button("프로필 편집", action: onEdit)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsOnPrimary)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(height: 33)
                .background(Color.tsPrimary, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// 07-3 나에게 온 결재 요청 — 위쪽은 결재 탭으로, 아래 한 건은 결재 상세로
struct ReceivedApprovalCard: View {
    let count: Int
    let latest: ApprovalItem?
    let onOpenTab: () -> Void
    let onOpenItem: (ApprovalItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button(action: onOpenTab) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("나에게 온 결재 요청")
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsPrimary)
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                            Text("\(count)")
                                .tsFont(.title1)
                                .foregroundStyle(Color.tsInk)
                            Text(count == 0 ? "건 · 지금은 확인할 요청이 없어요" : "건이 확인을 기다려요")
                                .tsFont(.footnoteMedium)
                                .foregroundStyle(Color.tsInk2)
                        }
                    }
                    Spacer()
                    IconTile(icon: .tabApproval, iconSize: .lg, tileSize: 42, tint: .tsOnPrimary, background: .tsPrimary, isCircle: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("결재 탭으로 이동")
            if let latest {
                Button { onOpenItem(latest) } label: { ReceivedApprovalRow(item: latest) }
                    .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

private struct ReceivedApprovalRow: View {
    let item: ApprovalItem

    var body: some View {
        HStack(spacing: Spacing.sm + Spacing.xxxs) {
            AvatarView(size: 30)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(item.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
                Text("\(item.requesterName) · \(item.requesterDepartment) · \(TSFormat.relative(item.updatedAt))")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: Spacing.sm)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(Spacing.md + Spacing.xxxs)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// 07-3 메뉴 — 업무 대시보드 · 내 활동 · 참여 프로젝트 · 예정된 일정
struct WorkspaceMenuList: View {
    let onNavigate: (AppRoute) -> Void

    private var rows: [(title: String, route: AppRoute)] {
        [
            ("업무 대시보드", .workspaceDashboard),
            ("내 활동", .comingSoon(title: "내 활동")),
            ("참여 프로젝트", .workspaceProjects),
            ("예정된 일정", .workspaceSchedules)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { TSDivider() }
                Button { onNavigate(row.route) } label: {
                    HStack {
                        Text(row.title)
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                        Spacer()
                        TSIcon.chevronRight.sized(.base)
                            .foregroundStyle(Color.tsInk3)
                    }
                    .frame(height: 55)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// 07-3 하단 — 익명 활동 안내
struct WorkspacePrivacyNote: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            TSIcon.lock.sized(.sm)
                .foregroundStyle(Color.tsInk3)
                .accessibilityHidden(true)
            Text("익명 게시글 · 문의의 작성자 정보는 나에게만 보여요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 37, alignment: .leading)
        .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
