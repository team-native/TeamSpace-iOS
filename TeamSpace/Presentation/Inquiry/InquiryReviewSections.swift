import SwiftUI

/// 11-6 문의 원문 — 신원 · 접수 · 내용
struct InquiryOriginalCard: View {
    let item: InquiryInboxItem

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "문의 원문")
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(item.authorText)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(item.receivedText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Text(item.inquiry.body)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 11-6 처리 설정 — 담당 부서 · 담당자(메뉴) · 현재 상태
struct InquiryAssignCard: View {
    let viewModel: InquiryReviewViewModel
    let item: InquiryInboxItem

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "처리 설정")
            row(title: "담당 부서") {
                Text(item.inquiry.department.title)
                    .tsFont(.footnoteBold)
            }
            row(title: "담당자") {
                if viewModel.isEditable {
                    Menu {
                        ForEach(viewModel.assignees, id: \.self) { name in
                            Button(name) { Task { await viewModel.assign(name) } }
                        }
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text(item.assignee ?? "미배정")
                                .tsFont(.footnoteBold)
                            TSIcon.chevronDown.sized(.xs)
                        }
                        .foregroundStyle(item.assignee == nil ? Color.tsNegative : Color.tsPrimary)
                    }
                    .accessibilityLabel("담당자 \(item.assignee ?? "미배정"), 바꾸기")
                } else {
                    Text(item.assignee ?? "미배정")
                        .tsFont(.footnoteBold)
                }
            }
            row(title: "현재 상태") {
                StatusBadge(status: item.inquiry.status, size: .small)
            }
        }
    }

    private func row<Value: View>(title: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(title)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
            Spacer()
            value()
                .foregroundStyle(Color.tsInk)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 11-6 공식 답변 / 반려 사유 입력 · 관련 규칙 연결
struct InquiryReplyEditor: View {
    @Bindable var viewModel: InquiryReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TSSegmentedControl(
                items: [InquiryReplyDraft.Kind.answer, .reject],
                selection: viewModel.draft.kind,
                title: \.title,
                onSelect: { viewModel.draft.kind = $0 }
            )
            PostComposeLabel(
                title: viewModel.draft.kind == .answer ? "\(viewModel.item?.inquiry.department.title ?? "") 공식 답변" : "반려 사유",
                trailing: "\(TSFormat.number(viewModel.draft.body.count)) / \(TSFormat.number(InquiryReplyDraft.bodyLimit))"
            )
            TextEditor(text: $viewModel.draft.body)
                .tsFont(.callout)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(Spacing.md)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityLabel(viewModel.draft.kind == .answer ? "공식 답변" : "반려 사유")
            InquiryRuleLinkSection(viewModel: viewModel)
        }
    }
}

/// 11-6 관련 규칙 연결 — 고른 규칙 · 관련 규칙 추가(메뉴)
private struct InquiryRuleLinkSection: View {
    @Bindable var viewModel: InquiryReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "관련 규칙 연결")
            if let rule = viewModel.selectedRule {
                HStack {
                    WorkspaceItemText(title: "\(rule.title) · \(rule.version)", meta: rule.metaText)
                    Spacer(minLength: Spacing.sm)
                    CircleIconButton(icon: .close, accessibilityLabel: "\(rule.title) 연결 빼기", size: 28) {
                        viewModel.draft.referenceRuleId = nil
                    }
                }
                .padding(Spacing.md)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            Menu {
                ForEach(viewModel.rules) { rule in
                    Button(rule.title) { viewModel.draft.referenceRuleId = rule.id }
                }
            } label: {
                Text(viewModel.selectedRule == nil ? "관련 규칙 추가" : "다른 규칙으로 바꾸기")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
        }
    }
}

/// 11-6 등록 시 전달되는 내용
struct InquiryDeliveryCard: View {
    let statusChange: String

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "등록 시 전달되는 내용")
            KeyValueLine(title: "상태 변경", value: statusChange)
            KeyValueLine(title: "알림 수신자", value: "이 문의의 작성자만")
            Text("작성자의 개인 업무 알림으로 ‘문의에 답변이 등록됐어요’를 전달해요. 잠금화면에는 민감한 본문을 표시하지 않아요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct KeyValueLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
            Spacer()
            Text(value)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 11-6 미리보기 · 등록 버튼
struct InquiryReplyActions: View {
    @Bindable var viewModel: InquiryReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if viewModel.isPreviewing, let item = viewModel.item {
                InquiryReplyCard(
                    reply: InquiryReply(department: item.inquiry.department, body: viewModel.draft.body, repliedAt: Date()),
                    isRejection: viewModel.draft.kind == .reject
                )
            }
            HStack(spacing: Spacing.sm) {
                Button(viewModel.isPreviewing ? "미리보기 닫기" : "미리보기") { viewModel.isPreviewing.toggle() }
                    .buttonStyle(.tsSecondary)
                    .disabled(viewModel.draft.body.isEmpty)
                Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimary)
                    .disabled(!viewModel.canSubmit)
            }
        }
    }
}
