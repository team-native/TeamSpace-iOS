import SwiftUI

/// 08-3 상단 — 모집 중 · 역할 배지 · 제목 · 소개
struct RecruitmentHeader: View {
    let post: RecruitmentPost

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("모집 정보를 읽고 나에게 맞는 프로젝트를 찾아 함께 만들어 나가요")
                .tsFont(.micro)
                .foregroundStyle(Color.tsPrimary)
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: "모집 중", tone: .primary, size: .small)
                StatusBadge(title: post.roleBadgeText, tone: .violet, size: .small)
            }
            Text(post.headline)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(post.introduction)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
        .padding(.top, Spacing.sm)
    }
}

private struct RecruitmentRow: View {
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
        .frame(minHeight: 30)
        .accessibilityElement(children: .combine)
    }
}

/// 08-3 모집 정보
struct RecruitmentInfoCard: View {
    let post: RecruitmentPost

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "모집 정보")
            RecruitmentRow(title: "역할", value: post.opening.title)
            RecruitmentRow(title: "활동 기간", value: post.activityPeriod)
            RecruitmentRow(title: "활동 시간", value: post.activityHours)
            RecruitmentRow(title: "모집 기간", value: post.recruitPeriodText)
            RecruitmentRow(title: "담당 부서", value: post.department)
        }
    }
}

/// 08-3 이런 일을 함께해요 · 필요한 역량
struct RecruitmentDutiesCard: View {
    let post: RecruitmentPost

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "이런 일을 함께해요")
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                ForEach(post.duties, id: \.self) { duty in
                    Text("• \(duty)")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
            }
            WorkspaceCardTitle(title: "필요한 역량")
                .padding(.top, Spacing.xs)
            Text(post.requirements)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
            Text(post.applyTip)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }
}

/// 08-3 PM에게 물어보세요
struct RecruitmentPMCard: View {
    let pmName: String
    let projectName: String
    let onOpenProfile: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "PM에게 물어보세요")
            HStack(spacing: Spacing.md) {
                AvatarView(size: 40)
                Text("\(pmName) · \(projectName) PM")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
            }
            Button("PM 프로필 · 연락처 보기", action: onOpenProfile)
                .buttonStyle(.tsSecondary)
        }
    }
}

/// 08-4 참여 신청 시트
struct ApplySheet: View {
    @Bindable var viewModel: RecruitmentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("\(viewModel.post?.projectName ?? "")에 참여 신청")
                            .tsFont(.headline)
                            .foregroundStyle(Color.tsInk)
                        Text("PM \(viewModel.post?.pmName ?? "") 님에게 신청서가 전달돼요.")
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk3)
                    }
                    Spacer()
                    CircleIconButton(icon: .close, accessibilityLabel: "닫기", size: 28, background: .tsSurface2) { dismiss() }
                }
                ApplySheetLabel(title: "지원 자리")
                Text(viewModel.post.map { "\($0.opening.title) · \(TSFormat.month($0.opening.startDate)) ~ \(TSFormat.month($0.opening.endDate))" } ?? "")
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk)
                    .padding(.horizontal, Spacing.lg)
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                ApplySheetLabel(title: "가능한 시간")
                HStack(spacing: Spacing.xs) {
                    ForEach(Availability.selectable, id: \.self) { option in
                        WorkspaceCountChip(title: option.title, isSelected: viewModel.availability == option) {
                            viewModel.availability = option
                        }
                    }
                }
                HStack {
                    ApplySheetLabel(title: "한 마디")
                    Spacer()
                    Text(viewModel.messageCountText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                TextField("작업물 링크, 참여 가능한 시기 등을 알려주세요.", text: $viewModel.message, axis: .vertical)
                    .lineLimit(3...6)
                    .tsFont(.callout)
                    .padding(Spacing.md + Spacing.xxxs)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                Button("신청하기") { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSubmit)
            }
            .padding(Spacing.xl)
            .padding(.top, Spacing.sm)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.tsSurface)
    }
}

private struct ApplySheetLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .tsFont(.captionBold)
            .foregroundStyle(Color.tsInk3)
    }
}
