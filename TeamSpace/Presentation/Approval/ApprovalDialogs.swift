import SwiftUI

/// 05-9 승인 확인
struct ApproveConfirmDialog: View {
    let nextApprover: Approver?
    let isProcessing: Bool
    let onApprove: () -> Void
    let onCancel: () -> Void

    var body: some View {
        TSDialog(onDismiss: onCancel) {
            VStack(spacing: Spacing.xxl) {
                VStack(spacing: Spacing.md) {
                    AvatarView(size: 72)
                    if let nextApprover {
                        Text("다음 결재자 **\(nextApprover.name) (\(nextApprover.role))**")
                            .tsFont(.caption)
                            .foregroundStyle(Color.tsPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xxs)
                            .background(Capsule().fill(Color.tsPrimarySoft))
                    }
                }
                VStack(spacing: Spacing.sm) {
                    Text("이 요청을 승인할까요?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.tsInk)
                    Text(message)
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: Spacing.sm) {
                    Button(action: onApprove) {
                        if isProcessing {
                            ProgressView().tint(Color.tsOnPrimary)
                        } else {
                            Text("승인")
                        }
                    }
                    .buttonStyle(.tsPrimary)
                    .disabled(isProcessing)
                    Button("취소", action: onCancel)
                        .buttonStyle(.tsSecondary)
                }
            }
            .padding(Spacing.xxl)
        }
    }

    private var message: String {
        guard let nextApprover else { return "승인하면 결재가 최종 완료돼요." }
        return "승인하면 다음 결재자 \(nextApprover.name)(\(nextApprover.role)) 님에게 자동으로 넘어가요."
    }
}

/// 05-10 처리 완료
struct DecisionCompletedDialog: View {
    let decision: ApprovalDecision
    let requesterName: String
    let onConfirm: () -> Void

    var body: some View {
        TSDialog(onDismiss: onConfirm) {
            VStack(spacing: 0) {
                VStack(spacing: Spacing.xl) {
                    Image(systemName: decision == .approve ? "checkmark" : "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.tsOnPrimary)
                        .frame(width: 70, height: 70)
                        .background(Circle().fill(decision == .approve ? Color.tsPrimary : Color.tsNegative))
                    VStack(spacing: Spacing.xs) {
                        Text(decision == .approve ? "승인했어요" : "반려했어요")
                            .tsFont(.title3)
                            .foregroundStyle(Color.tsInk)
                        Text("\(requesterName) 님에게 결과를 알림으로 보냈어요.")
                            .tsFont(.callout)
                            .foregroundStyle(Color.tsInk3)
                    }
                    HStack(spacing: Spacing.md) {
                        AvatarView(size: 44)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(requesterName)
                                .tsFont(.calloutBold)
                                .foregroundStyle(Color.tsInk)
                            Text("결재 요청자")
                                .tsFont(.caption)
                                .foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                        StatusBadge(
                            title: decision == .approve ? "승인됨" : "반려됨",
                            tone: decision == .approve ? .primary : .negative
                        )
                    }
                    .padding(Spacing.lg)
                    .background(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).fill(Color.tsBackground))
                }
                .padding(Spacing.xxl)
                Button(action: onConfirm) {
                    Text("확인")
                        .tsFont(.subheadline)
                        .foregroundStyle(Color.tsOnPrimary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.tsPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("05-9") {
    ApproveConfirmDialog(
        nextApprover: Approver(id: 2, name: "김민준", role: "FA", status: .waiting, note: ""),
        isProcessing: false, onApprove: {}, onCancel: {}
    )
}

#Preview("05-10") {
    DecisionCompletedDialog(decision: .approve, requesterName: "이시우", onConfirm: {})
}
