import SwiftUI

/// 공지 확인 현황 [Admin] — "12 / 24명 확인" · 진행 막대 · 확인 안 한 사람 보기
struct NoticeReceiptCard: View {
    let text: String
    let progress: Double
    let onShowUnconfirmed: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                WorkspaceCardTitle(title: "확인 현황")
                Spacer(minLength: Spacing.sm)
                Text(text)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            ProgressView(value: progress)
                .tint(Color.tsPrimary)
                .accessibilityLabel("확인 비율")
            WorkspaceLinkRow(title: "확인 안 한 사람 보기", subtitle: "관리자만 볼 수 있어요", action: onShowUnconfirmed)
        }
    }
}

/// 미확인자 목록 시트 — 이름 · 이메일
struct NoticeUnconfirmedSheet: View {
    @Bindable var viewModel: NoticeDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("확인 안 한 사람")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.xl)
        .background(Color.tsBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.unconfirmedState {
        case .idle, .loading:
            LoadingSkeletonView(message: "목록을 불러오는 중이에요", count: 2)
        case .empty:
            InfoBanner(message: "모두 확인했어요.", icon: .checkCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "확인 현황은 관리자만 볼 수 있어요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "목록을 불러오지 못했어요") { Task { await viewModel.loadUnconfirmed() } }
        case .loaded(let members):
            VStack(alignment: .leading, spacing: 0) {
                Text("\(members.count)명")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
                    .padding(.bottom, Spacing.sm)
                ForEach(members) { member in
                    HStack(spacing: Spacing.md) {
                        AvatarView(size: 32)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(member.name)
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            if !member.email.isEmpty {
                                Text(member.email)
                                    .tsFont(.caption2)
                                    .foregroundStyle(Color.tsInk3)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Spacing.sm)
                    .accessibilityElement(children: .combine)
                    if member.id != members.last?.id { TSDivider() }
                }
            }
        }
    }
}
