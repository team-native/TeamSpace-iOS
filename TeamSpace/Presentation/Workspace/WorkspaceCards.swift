import SwiftUI

/// 07 내 공간 카드 — 흰 배경 r20, 안쪽 여백 18
struct WorkspaceCard<Content: View>: View {
    var background: Color = .tsSurface
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// 카드 아래 "○○ 보기 >" 줄 (설명이 있으면 두 줄)
struct WorkspaceLinkRow: View {
    let title: String
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(title)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk2)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: Spacing.sm)
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 카드 안 제목 (15 Bold)
struct WorkspaceCardTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .tsFont(.bodyBold)
            .foregroundStyle(Color.tsInk)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 카드 안 항목 — 제목(13 Bold) + 설명(12)
struct WorkspaceItemText: View {
    let title: String
    let meta: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
                .lineLimit(1)
            Text(meta)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 07-1 상단 — 뒤로 · 가운데 제목 · 오른쪽 더보기
struct WorkspaceTopBar: View {
    let onBack: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Text("내 공간")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            HStack {
                CircleIconButton(
                    icon: .chevronLeft,
                    accessibilityLabel: "뒤로",
                    size: 34,
                    background: .tsSurface,
                    hasBorder: true,
                    action: onBack
                )
                Spacer()
                Button(action: onMenu) {
                    TSIcon.ellipsis.sized(.base, weight: .semibold)
                        .foregroundStyle(Color.tsInk)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
            }
        }
        .frame(height: 48)
        .padding(.horizontal, Spacing.screen)
        .background(Color.tsBackground)
    }
}

/// 07-1 프로필 카드
struct WorkspaceProfileCard: View {
    let user: AuthUser
    let affiliation: String?
    let onEdit: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack(spacing: Spacing.md) {
                AvatarView(size: 48)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(user.name) 님")
                        .tsFont(.subheadline)
                        .foregroundStyle(Color.tsInk)
                    if let affiliation {
                        Text(affiliation)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            WorkspaceLinkRow(title: "프로필 확인 · 편집", subtitle: user.workspaceRoleSummary, action: onEdit)
        }
    }
}

/// 07 하단 안내 (연한 파란 배경 + 정보 아이콘)
struct WorkspaceNote: View {
    var message = "내 익명 활동은 내 공간에서만 확인해요. 알림 읽음, 할 일 완료, 결재 승인은 각각 다른 상태예요."

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            TSIcon.infoCircle.sized(.base)
                .foregroundStyle(Color.tsPrimary)
                .accessibilityHidden(true)
            Text(message)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

/// 07 화면 위 작은 파란 설명 + 큰 제목
struct WorkspacePageTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(eyebrow)
                .tsFont(.micro)
                .foregroundStyle(Color.tsPrimary)
            Text(title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, Spacing.sm)
    }
}
