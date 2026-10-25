import SwiftUI

/// 02-8 알림 진입 · 로그인 필요 — 로그인 화면 위쪽 안내
struct NotificationEntryHeader: View {
    let entry: NotificationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.xs) {
                Text("안전하게 알림으로 진입해요")
                    .tsFont(.micro)
                    .foregroundStyle(Color.tsPrimary)
                StatusBadge(title: "세션 만료", tone: .neutral)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("로그인하면 확인하던\n요청으로 돌아가요.")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Text("\(entry.type.entryLabel) 알림에서 오셨네요. 계정 보호를 위해 다시 로그인해 주세요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("돌아갈 위치")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(entry.type.entryDestination)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text("인증 전에는 문서 제목·요청자·금액을 표시하지 않아요.")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
}

/// 02-8 로그인 버튼 아래 — 안내 + 진입 취소
struct NotificationEntryFooter: View {
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            InfoBanner(
                message: "로그인 성공 후 저장된 원래 목적지로 이동하고 권한을 다시 확인해요. 접근 권한이 없으면 내용을 노출하지 않아요.",
                icon: .infoCircle,
                style: .muted
            )
            Button("알림 진입 취소", action: onCancel)
                .buttonStyle(.ts(.secondary, size: .medium))
        }
    }
}

extension NotificationType {
    /// "결재 요청 알림에서 오셨네요."
    var entryLabel: String {
        switch self {
        case .approval: return "결재 요청"
        case .approvalResult: return "결재 결과"
        case .finance: return "재정"
        case .schedule: return "일정 변경"
        case .rule: return "규칙 변경"
        case .notice: return "전체 공지"
        case .inquiryAnswer: return "문의 답변"
        case .unknown: return "TeamSpace"
        }
    }

    /// 02-8 돌아갈 위치
    var entryDestination: String {
        switch self {
        case .approval: return "개인 업무 → 받은 결재 요청"
        case .approvalResult: return "개인 업무 → 내가 올린 결재"
        case .finance: return "NativeLab 재정 → 재무"
        case .schedule: return "Native 일정 → 일정 상세"
        case .rule: return "제도·규칙 → 규칙 개정 비교"
        case .notice: return "전체 공지 → 공지 상세"
        case .inquiryAnswer: return "개인 업무 → 내 문의 답변"
        case .unknown: return "알림 센터"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        if let entry = NotificationEntry(type: "APPROVAL", deepLink: "/approvals/12") {
            NotificationEntryHeader(entry: entry)
        }
        NotificationEntryFooter(onCancel: {})
    }
    .padding()
}
