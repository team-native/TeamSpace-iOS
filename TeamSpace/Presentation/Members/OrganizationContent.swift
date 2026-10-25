import SwiftUI

/// 02-5 조직도 — 리더 + 부서 가지
struct OrganizationContent: View {
    let state: ViewState<OrganizationTree>
    let onSelectDepartment: (Department) -> Void
    let onSelectMember: (Member) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "조직도를 볼 수 있는 권한이 없어요.", icon: .infoCircle, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage, onRetry: onRetry)
        case .loaded(let tree):
            LeaderNode(leader: tree.leader) { onSelectMember(tree.leader) }
            VStack(spacing: Spacing.xs) {
                ForEach(tree.units) { unit in
                    UnitBranch(unit: unit) { onSelectDepartment(unit.department) }
                }
            }
            HStack(alignment: .top, spacing: Spacing.sm) {
                TSIcon.organization.sized(.mdLarge)
                Text("조직 구성은 NativeOps에서 관리하고 있어요. 변경 사항이 생기면 알림으로 바로 알려드릴게요.")
                    .tsFont(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Color.tsInk3)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
}

private struct LeaderNode: View {
    let leader: Member
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md + Spacing.xxxs) {
                AvatarView(size: 38)
                    .padding(Spacing.compact)
                    .background(Color.tsOnPrimary.opacity(0.25), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(leader.tag)
                        .tsFont(.caption2Bold)
                    Text(leader.name)
                        .tsFont(.headline)
                    Text(leader.position)
                        .tsFont(.caption)
                }
                .foregroundStyle(Color.tsOnPrimary)
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .background(Color.tsPrimary, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 왼쪽 연결선 + 부서 카드
private struct UnitBranch: View {
    let unit: OrganizationUnit
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.tsLine).frame(width: 2)
                Rectangle().fill(Color.tsLine).frame(width: 12, height: 2)
            }
            .frame(width: 20)
            .padding(.leading, Spacing.sm)
            Button(action: action) {
                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
                    HStack(spacing: Spacing.sm) {
                        Text(unit.name)
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                        StatusBadge(title: "\(unit.members.count)명", tone: unit.department.tone)
                        Spacer(minLength: 0)
                        TSIcon.chevronRight.sized(.mdLarge)
                            .foregroundStyle(Color.tsInk3)
                    }
                    Text(unit.summary)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                    AvatarStack(count: unit.members.count)
                }
                .padding(Spacing.md + Spacing.xxxs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint("\(unit.name) 구성원 보기")
        }
    }
}

/// 겹쳐 놓은 미모티콘 (최대 5개 + 나머지 숫자)
private struct AvatarStack: View {
    let count: Int
    private let maxVisible = 5

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<min(count, maxVisible), id: \.self) { _ in
                AvatarView(size: 32)
                    .padding(Spacing.xxxs)
                    .background(Color.tsSurface, in: Circle())
            }
            if count > maxVisible {
                Text("+\(count - maxVisible)")
                    .tsFont(.caption2Bold)
                    .foregroundStyle(Color.tsInk2)
                    .frame(width: 36, height: 36)
                    .background(Color.tsSurface2, in: Circle())
            }
        }
        .accessibilityHidden(true)
    }
}
