import SwiftUI

/// 항목명(고정 폭) + 값
private struct PermissionKeyValue: View {
    let title: String
    let value: String
    var titleWidth: CGFloat = 92

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
                .frame(width: titleWidth, alignment: .leading)
            Text(value)
                .tsFont(.footnoteMedium)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 07-15 현재 내 역할
struct CurrentRoleCard: View {
    let viewModel: PermissionsViewModel

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "현재 내 역할")
            StatusBadge(title: viewModel.roleBadgeText, tone: .primary, size: .small)
            PermissionKeyValue(title: "소속", value: viewModel.affiliation ?? "-")
            PermissionKeyValue(title: "추가 운영 권한", value: viewModel.user.extraPermissionText)
            Text("여기서는 역할을 직접 변경할 수 없어요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

/// 07-15 허용되는 기능
struct AllowedFeaturesCard: View {
    let features: [String]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "허용되는 기능")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        TSIcon.check.sized(.sm, weight: .bold)
                            .foregroundStyle(Color.tsPrimary)
                        Text(feature)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk2)
                    }
                }
            }
        }
    }
}

/// 07-15 역할별 기능 범위 예시
struct RoleScopeCard: View {
    private let rows: [(String, String)] = [
        ("구성원", "기본 업무와 본인 활동 확인"),
        ("PM", "담당 프로젝트 편집·지원자 검토·일정 관리"),
        ("NativeOps", "배정된 문의 처리·조직 운영·공지 게시"),
        ("FA", "허용된 재정 세부 내역·예산 검토"),
        ("Leader", "지정된 결재·조직 운영 범위 확인")
    ]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "역할별 기능 범위 예시")
            ForEach(rows, id: \.0) { row in
                PermissionKeyValue(title: row.0, value: row.1, titleWidth: 80)
            }
        }
    }
}

/// 07-15 제한되는 재정 항목
struct RestrictedFinanceCard: View {
    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "제한되는 재정 항목")
            Text("계좌 정보 · 계약 원문 · 개별 배분금")
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
            Text("소속이나 직책만으로 자동 공개되지 않아요. 승인된 업무 범위에 따라 세부 접근 권한이 달라질 수 있어요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 07-15 권한이 더 필요하다면 — 3단계 + 문의 버튼
struct PermissionRequestCard: View {
    let onRequest: () -> Void

    private let steps: [(String, String)] = [
        ("업무 목적과 필요한 범위 정리", "프로젝트·기간·자료 범위를 함께 적어요."),
        ("NativeOps에 권한 요청", "해당 부서와 운영자가 적정 범위를 검토해요."),
        ("승인 결과 확인", "검토 후 계정에 적용된 범위를 다시 확인해요.")
    ]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "권한이 더 필요하다면")
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Text("\(index + 1)")
                        .tsFont(.captionBold)
                        .foregroundStyle(index == 0 ? Color.tsOnPrimary : Color.tsInk2)
                        .frame(width: 24, height: 24)
                        .background(index == 0 ? Color.tsPrimary : Color.tsSurface2, in: Circle())
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(step.0)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(index == 0 ? Color.tsPrimary : Color.tsInk)
                        Text(step.1)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            Button("업무용 권한 요청 문의", action: onRequest)
                .buttonStyle(.tsPrimary)
                .padding(.top, Spacing.xs)
        }
    }
}
