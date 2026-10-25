import SwiftUI
import UIKit

/// 02-4 팀원 상세
struct MemberDetailView: View {
    @State private var viewModel: MemberDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(viewModel: MemberDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                CircleIconButton(icon: .chevronLeft, accessibilityLabel: "뒤로", size: 34, background: .tsSurface) {
                    dismiss()
                }
                Spacer()
                CircleIconButton(icon: .link, accessibilityLabel: "프로필 링크 복사", size: 34, background: .tsSurface) {
                    UIPasteboard.general.string = viewModel.profileLink
                    viewModel.didCopyLink()
                }
            }
            .frame(height: 44)
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .alert(viewModel.toastMessage ?? "", isPresented: toastBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        case .empty, .forbidden:
            InfoBanner(message: "이 팀원의 정보를 볼 수 있는 권한이 없어요.", icon: .infoCircle, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            MemberProfileHeader(detail: detail)
            MemberContactButtons(
                onMail: { if let url = viewModel.mailURL(detail) { openURL(url) } },
                onMessage: { onNavigate(.comingSoon(title: "메시지")) }
            )
            MemberInfoCard(detail: detail, joinedText: viewModel.joinedText(detail))
            if !detail.projects.isEmpty {
                MemberProjectsSection(projects: detail.projects)
            }
            if !detail.interests.isEmpty {
                MemberInterestsSection(interests: detail.interests)
            }
        }
    }

    private var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        MemberDetailView(
            viewModel: DIContainer.preview().makeMemberDetailViewModel(memberId: 4),
            onNavigate: { _ in }
        )
    }
}
