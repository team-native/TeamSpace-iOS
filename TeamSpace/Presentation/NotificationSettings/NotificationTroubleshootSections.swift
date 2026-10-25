import SwiftUI

/// 02-7 상단 — 큰 아이콘 + 상태 배지 + 제목
struct TroubleshootHeader: View {
    let isResolved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .center, spacing: Spacing.md) {
                IconTile(
                    icon: isResolved ? .bellRing : .bellOff,
                    iconSize: .heroSmall,
                    tileSize: 64,
                    tint: isResolved ? .tsPositive : .tsNegative,
                    background: isResolved ? .tsPositiveSoft : .tsNegativeSoft,
                    isCircle: true
                )
                StatusBadge(
                    title: isResolved ? "기기 알림 켜짐" : "기기 알림 꺼짐",
                    tone: isResolved ? .positive : .negative
                )
            }
            ScreenTitle(
                title: isResolved ? "알림이 다시 켜졌어요." : "기기에서 알림이\n차단되어 있어요.",
                subtitle: isResolved
                    ? "이제 결재 · 재정 소식을 바로 받을 수 있어요."
                    : "앱 안 알림센터에는 계속 쌓이지만, 잠금 화면 · 배너로는 받을 수 없어요."
            )
        }
    }
}

/// 02-7 진단 결과 카드
struct DiagnosisCard: View {
    let diagnoses: [NotificationDiagnosis]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(diagnoses.enumerated()), id: \.element.id) { index, diagnosis in
                if index > 0 { TSDivider() }
                HStack {
                    Text(diagnosis.title)
                        .tsFont(.footnoteMedium)
                        .foregroundStyle(Color.tsInk2)
                    Spacer()
                    StatusBadge(title: diagnosis.value, tone: diagnosis.level.tone)
                }
                .padding(.vertical, Spacing.md)
            }
        }
        .tsCard(padding: Spacing.lg)
    }
}

/// 02-7 다시 켜는 방법 3단계
struct TroubleshootChecklist: View {
    private let steps = [
        "기기 설정 열기 → 알림 → TeamSpace 로 이동해요.",
        "'알림 허용'을 켜고, 잠금 화면 · 배너를 선택해요.",
        "집중 모드를 쓴다면 허용된 앱에 TeamSpace 를 추가해요."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("이렇게 다시 켜 주세요")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Text("\(index + 1)")
                            .tsFont(.captionBold)
                            .foregroundStyle(Color.tsPrimary)
                            .frame(width: 22, height: 22)
                            .background(Color.tsPrimarySoft, in: Circle())
                        Text(step)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tsCard(padding: Spacing.lg)
        }
    }
}

extension NotificationDiagnosis.Level {
    var tone: BadgeTone {
        switch self {
        case .ok: return .positive
        case .check: return .amber
        case .problem: return .negative
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        TroubleshootHeader(isResolved: false)
        DiagnosisCard(diagnoses: [
            NotificationDiagnosis(id: "a", title: "iOS 알림 권한", value: "꺼짐", level: .problem),
            NotificationDiagnosis(id: "b", title: "집중 모드", value: "기기에서 확인", level: .check)
        ])
        TroubleshootChecklist()
    }
    .padding()
    .background(Color.tsBackground)
}
