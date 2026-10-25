import SwiftUI

/// 08-7 상단 — PM 권한 배지 · 제목 · 정원 · 현황 · 칩
struct ApplicantBoardHeader: View {
    let board: ApplicantBoard
    @Bindable var viewModel: ApplicantReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("내 프로젝트에 맞는 지원자를 찾아요")
                .tsFont(.micro)
                .foregroundStyle(Color.tsPrimary)
            StatusBadge(title: "\(board.projectName) PM 권한 · \(board.pmName)", tone: .primary, size: .small)
            Text("\(board.opening.title) 지원자를 검토해요")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, Spacing.sm)
        WorkspaceCard {
            ApplicantInfoRow(title: "모집 정원", value: viewModel.headcountText)
            ApplicantInfoRow(title: "지원 현황", value: viewModel.progressText.isEmpty ? "지원자 없음" : viewModel.progressText)
            Text("모집 \(TSFormat.fullDate(board.recruitStart))–\(TSFormat.shortDate(board.recruitEnd)) · 결과 예정 \(TSFormat.shortDate(board.resultDueDate))")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .padding(Spacing.sm + Spacing.xxxs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        FlowLayout(spacing: Spacing.xs) {
            ForEach(viewModel.filters, id: \.self) { filter in
                FilterChip(title: "\(filter.title) \(viewModel.count(of: filter))", isSelected: viewModel.filter == filter) {
                    viewModel.filter = filter
                }
            }
        }
    }
}

private struct ApplicantInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .tsFont(.footnoteMedium)
                .foregroundStyle(Color.tsInk)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 08-7 선택한 지원자 — 신청 내용 · 결과 · 사유 · 등록
struct SelectedApplicantCard: View {
    let applicant: Applicant
    @Bindable var viewModel: ApplicantReviewViewModel

    var body: some View {
        WorkspaceCard {
            Text("\(applicant.name) · \(applicant.role)")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: "선택한 지원자", tone: .primary, size: .small)
                StatusBadge(status: applicant.status, size: .small)
            }
            ApplicantInfoRow(title: "신청일", value: "\(TSFormat.shortDate(applicant.appliedAt)) \(TSFormat.time(applicant.appliedAt))")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("신청 내용")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(applicant.message)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                if let link = applicant.portfolioUrl, let url = URL(string: link) {
                    Link("작업물 링크 열기 ↗", destination: url)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsPrimary)
                }
            }
            if applicant.status.isCancelable {
                ApplicantDecisionForm(viewModel: viewModel)
            } else if let reason = applicant.resultReason {
                ApplicantInfoRow(title: "결과 안내 사유", value: reason)
            }
        }
    }
}

/// 참여 확정 / 미선정 + 결과 안내 사유 + 등록
private struct ApplicantDecisionForm: View {
    @Bindable var viewModel: ApplicantReviewViewModel

    var body: some View {
        HStack(spacing: Spacing.xs) {
            WorkspaceCountChip(title: "참여 확정", isSelected: viewModel.decision == .accept) { viewModel.decision = .accept }
            WorkspaceCountChip(title: "미선정", isSelected: viewModel.decision == .decline) { viewModel.decision = .decline }
        }
        Text("결과 안내 사유")
            .tsFont(.footnoteBold)
            .foregroundStyle(Color.tsInk)
        TextField("신청자에게 전할 결과 안내를 적어 주세요.", text: $viewModel.reason, axis: .vertical)
            .lineLimit(3...6)
            .tsFont(.footnote)
            .padding(Spacing.md)
            .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        Text("미선정 시에도 사유를 작성해요. 등록 전 결과와 수신자를 다시 확인해 주세요.")
            .tsFont(.caption2)
            .foregroundStyle(Color.tsInk3)
        Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
            .buttonStyle(.tsPrimary)
            .disabled(!viewModel.canSubmit)
    }
}

/// 08-7 다른 지원자 — 누르면 선택
struct ApplicantCompactCard: View {
    let applicant: Applicant
    let onSelect: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(applicant.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: applicant.status, size: .small)
            }
            WorkspaceItemText(title: "\(applicant.name) · \(applicant.role)", meta: applicant.message)
            WorkspaceLinkRow(title: applicant.status == .submitted ? "검토 시작" : "신청 내용 검토", action: onSelect)
        }
    }
}
