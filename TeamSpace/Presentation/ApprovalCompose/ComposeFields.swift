import SwiftUI

/// 05-5 · 05-6 입력 칸 — 라벨 + 회색 둥근 칸
struct ComposeField<Content: View>: View {
    let label: String
    var height: CGFloat = 46
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            content()
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.tsSurface2))
        }
    }
}

/// 누르면 메뉴 · 시트가 열리는 칸의 내용 (값 + 오른쪽 아이콘)
struct ComposeValueLabel: View {
    let value: String?
    let placeholder: String
    var icon: TSIcon = .chevronDown

    var body: some View {
        HStack {
            Text(value ?? placeholder)
                .tsFont(.callout)
                .foregroundStyle(value == nil ? Color.tsInk3 : Color.tsInk)
                .lineLimit(1)
            Spacer(minLength: Spacing.xxs)
            icon.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .contentShape(Rectangle())
    }
}

/// 결재선 미리보기 (안율 OL → 김민준 FA → 이시우 Leader)
struct ApprovalLinePreview: View {
    let approvers: [(name: String, role: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("결재선")
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            HStack(spacing: 0) {
                ForEach(Array(approvers.enumerated()), id: \.offset) { index, approver in
                    if index > 0 {
                        TSIcon.chevronRight.sized(.base)
                            .foregroundStyle(Color.tsInk3)
                            .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: Spacing.xxs) {
                        AvatarView(size: 36)
                        Text(approver.name)
                            .tsFont(.caption2Bold)
                            .foregroundStyle(Color.tsInk)
                        Text(approver.role)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.tsInk3)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.tsSurface2))
        }
    }

    /// 지금은 고정 결재선 — 결재선 조회 API 가 생기면 서버 값으로 바꿔요.
    static let defaultLine: [(name: String, role: String)] = [("안율", "OL"), ("김민준", "FA"), ("이시우", "Leader")]
}

/// 시트 상단 제목 + 닫기 버튼
struct ComposeSheetHeader: View {
    let title: String
    let subtitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: Spacing.sm)
            CircleIconButton(icon: .close, accessibilityLabel: "닫기", size: 32, background: .tsSurface2, action: onClose)
        }
    }
}
