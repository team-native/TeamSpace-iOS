import SwiftUI

/// 12-2b 위 — 부서 · 상태 · 제목 · 작성자 · 날짜 · 조회 · 본문
struct ProposalDetailHeader: View {
    let detail: ProposalDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: detail.proposal.department, tone: .neutral, size: .small)
                StatusBadge(status: detail.proposal.status, size: .small)
            }
            Text(detail.proposal.title)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(detail.metaText)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            Text(detail.body)
                .tsFont(.body)
                .foregroundStyle(Color.tsInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 12-2b 추천 · 댓글 수 · 안내
struct ProposalRecommendBar: View {
    let detail: ProposalDetail
    let note: String
    let isLoading: Bool
    let onRecommend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Button(action: onRecommend) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: detail.isRecommended ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .tsIconSize(.sm)
                        Text("추천 \(detail.proposal.recommendCount)")
                            .tsFont(.captionBold)
                    }
                    .foregroundStyle(detail.isRecommended ? Color.tsOnPrimary : Color.tsPrimary)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 34)
                    .background(detail.isRecommended ? Color.tsPrimary : Color.tsPrimarySoft, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityAddTraits(detail.isRecommended ? .isSelected : [])
                BoardCountLabel(icon: .message, count: detail.proposal.commentCount, label: "댓글")
            }
            Text(note)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 12-2b 진행 상태 — 접수 · 검토 중 · 진행 · 완료 (날짜 또는 —)
struct ProposalStepsCard: View {
    let detail: ProposalDetail

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "진행 상태")
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(detail.stepDates.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(step.date == nil ? Color.tsLine : Color.tsPrimary)
                            .frame(width: 12, height: 12)
                        Text(step.status.stepTitle)
                            .tsFont(.caption2Bold)
                            .foregroundStyle(step.date == nil ? Color.tsInk3 : Color.tsInk)
                        Text(step.date.map(TSFormat.shortDate) ?? "—")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    if index < ProposalStatus.steps.count - 1 {
                        Rectangle()
                            .fill(Color.tsLine)
                            .frame(height: 1)
                            .padding(.top, 6)
                            .frame(maxWidth: 24)
                    }
                }
            }
        }
    }
}

/// 12-2b 담당 부서 답변
struct ProposalAnswerCard: View {
    let answer: ProposalAnswer

    var body: some View {
        WorkspaceCard(background: .tsPrimarySoft) {
            HStack {
                Text("\(answer.department) 답변")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
                Spacer()
                Text(TSFormat.shortDate(answer.answeredAt))
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Text(answer.body)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 12-2b 댓글 목록
struct ProposalCommentsCard: View {
    let comments: [ProposalComment]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "댓글 \(comments.count)")
            if comments.isEmpty {
                Text("아직 댓글이 없어요. 첫 의견을 남겨 보세요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(comments) { comment in
                TSDivider()
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(comment.headerText)
                        .tsFont(.caption2Bold)
                        .foregroundStyle(comment.isProposer ? Color.tsPrimary : Color.tsInk3)
                    Text(comment.body)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 12-2b 아래 댓글 입력 — 실명 · 익명 · 등록
struct ProposalCommentBar: View {
    @Bindable var viewModel: ProposalDetailViewModel

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button { viewModel.isCommentAnonymous.toggle() } label: {
                Text(viewModel.isCommentAnonymous ? "익명" : "실명")
                    .tsFont(.captionBold)
                    .foregroundStyle(viewModel.isCommentAnonymous ? Color.tsInk2 : Color.tsPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .frame(minHeight: 30)
                    .background(viewModel.isCommentAnonymous ? Color.tsSurface2 : Color.tsPrimarySoft, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isCommentAnonymous ? "익명으로 댓글 작성, 바꾸기" : "실명으로 댓글 작성, 바꾸기")
            TextField("댓글을 남겨보세요", text: $viewModel.commentText, axis: .vertical)
                .tsFont(.callout)
                .lineLimit(1...4)
            Button("등록") { Task { await viewModel.sendComment() } }
                .tsFont(.footnoteBold)
                .foregroundStyle(viewModel.canSendComment ? Color.tsPrimary : Color.tsInk3)
                .disabled(!viewModel.canSendComment)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.md)
        .background(Color.tsSurface)
    }
}

/// 12-2c 담당자 처리 — 담당 부서 · Admin 에게만 보여요.
struct ProposalManageCard: View {
    @Bindable var viewModel: ProposalDetailViewModel

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "담당자 처리")
            Text("상태를 바꾸거나 공식 답변을 남기면 제안자에게 알림이 가요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
            TSSegmentedControl(
                items: ProposalManageDraft.Action.allCases,
                selection: viewModel.manageDraft.action,
                title: \.title,
                onSelect: { viewModel.manageDraft.action = $0 }
            )
            if viewModel.manageDraft.action.needsBody {
                PostComposeLabel(
                    title: viewModel.manageDraft.action == .answer ? "공식 답변" : "반려 사유",
                    trailing: "\(TSFormat.number(viewModel.manageDraft.body.count)) / \(TSFormat.number(ProposalManageDraft.bodyLimit))"
                )
                TextEditor(text: $viewModel.manageDraft.body)
                    .tsFont(.callout)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(Spacing.md)
                    .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    .accessibilityLabel(viewModel.manageDraft.action == .answer ? "공식 답변" : "반려 사유")
            }
            Button(viewModel.manageDraft.action.needsBody ? "\(viewModel.manageDraft.action.title) 등록" : "\(viewModel.manageDraft.action.title)으로 바꾸기") {
                Task { await viewModel.submitManage() }
            }
            .buttonStyle(.tsPrimary)
            .disabled(!viewModel.canSubmitManage)
        }
    }
}
