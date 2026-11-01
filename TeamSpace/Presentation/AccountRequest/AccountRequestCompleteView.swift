import SwiftUI

/// 01-3 요청 완료
struct AccountRequestCompleteView: View {
    let receipt: AccountRequestReceipt
    let onBackToLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SuccessMark()
                    .padding(.top, Spacing.xxxl * 2)
                    .padding(.bottom, Spacing.xxl + Spacing.xxs)
                Text("요청을 보냈어요")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .padding(.bottom, Spacing.md)
                Text("운영진이 확인하면 메일과 알림으로 알려드려요.\n보통 1영업일 안에 처리돼요.")
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk2)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Spacing.xxxl + Spacing.xxs)
                ReceiptCard(receipt: receipt)
                    .padding(.bottom, Spacing.lg)
                Label("\(TSFormat.dateTime(receipt.requestedAt)) 요청", systemImage: TSIcon.clock.rawValue)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.horizontal, Spacing.xxl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("로그인으로 돌아가기", action: onBackToLogin)
                .buttonStyle(.tsPrimaryLarge)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.sm)
                .background(Color.tsSurface)
        }
        .background(Color.tsSurface.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
    }
}

private struct SuccessMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.tsPrimarySoft).frame(width: 100, height: 100)
            Circle().fill(Color.tsPrimary).frame(width: 60, height: 60)
            TSIcon.check.image
                .tsIconSize(.xxl, weight: .bold)
                .foregroundStyle(Color.tsOnPrimary)
        }
        .accessibilityHidden(true)
    }
}

private struct ReceiptCard: View {
    let receipt: AccountRequestReceipt

    var body: some View {
        VStack(spacing: 0) {
            KeyValueRow(title: "이름", value: receipt.name)
            TSDivider()
            KeyValueRow(title: "이메일", value: receipt.email)
            TSDivider()
            KeyValueRow(title: "소속", value: receipt.department.displayName)
            TSDivider()
            KeyValueRow(title: "요청 상태") {
                StatusBadge(status: receipt.status)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    AccountRequestCompleteView(
        receipt: AccountRequestReceipt(
            name: "옥물결",
            email: "s26043@gsm.hs.kr",
            department: .design,
            status: .reviewing,
            requestedAt: Date()
        ),
        onBackToLogin: {}
    )
}
