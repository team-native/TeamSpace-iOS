import SwiftUI

// MARK: - 14 공통 상태 (빈 화면 · 검색 결과 없음 · 로딩 · 오류 · 접근 불가)

/// 14-1 · 14-2 · 14-4 가운데 정렬 안내 — 큰 아이콘 + 제목 + 설명
struct StateMessage: View {
    let icon: TSIcon
    var iconSize: TSIconSize = .state
    var tint: Color = .tsPrimary
    let title: String
    var titleStyle: TSFontStyle = .title4
    let message: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            icon.sized(iconSize)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .tsFont(titleStyle)
                .foregroundStyle(Color.tsInk)
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .lineSpacing(Spacing.xxs)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// 14-1 첫 이용 빈 화면 — 흰 카드 안 안내 + (선택) 첫 행동 버튼
struct EmptyStateView: View {
    var icon: TSIcon = .listPlus
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            StateMessage(icon: icon, title: title, message: message)
                .padding(.vertical, Spacing.xxl + Spacing.xl)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.tsPrimary)
            }
        }
        .tsCard()
    }
}

/// 14-2 검색 결과 없음 — 카드 없이 안내 + 필터 초기화 · 검색어 수정
struct NoResultsView: View {
    let query: String
    var onResetFilters: (() -> Void)?
    var onEditQuery: (() -> Void)?
    var showsPrivacyNote = true

    var body: some View {
        VStack(spacing: Spacing.lg) {
            StateMessage(
                icon: .searchX,
                iconSize: .stateSmall,
                title: "일치하는 결과가 없어요",
                titleStyle: .title3,
                message: message
            )
            .padding(.vertical, Spacing.xxxl + Spacing.xxs)
            if let onResetFilters {
                Button("필터 초기화", action: onResetFilters)
                    .buttonStyle(.tsPrimary)
            }
            if let onEditQuery {
                Button("검색어 수정", action: onEditQuery)
                    .buttonStyle(.tsSecondary)
            }
            if showsPrivacyNote {
                InfoBanner(
                    message: "권한이 제한된 정보와 익명 문의는 검색되지 않아요. 익명 작성자의 신원 · 소속을 짐작할 수 있는 내용은 결과에서 제외돼요.",
                    icon: .infoCircle,
                    style: .hint
                )
                StateFootnote("권한이 없는 결과의 제목이나 개수도 표시하지 않아요.")
            }
        }
    }

    private var message: String {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let head = trimmed.isEmpty ? "검색 결과가 없어요." : "‘\(trimmed)’에 해당하는 결과가 없어요."
        let tail = onResetFilters == nil ? "검색어를 바꿔보세요." : "필터를 해제하거나 검색어를 바꿔보세요."
        return head + "\n" + tail
    }
}

/// 14-3 목록 로딩 — 불러오는 중 안내 + 스켈레톤 카드 + 비활성 버튼
struct LoadingSkeletonView: View {
    var message = "목록을 불러오는 중이에요"
    var count = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                SpinningLoader()
                Text(message)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard()
            }
            Text("불러오는 중 · 잠시 기다려 주세요")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk3)
                .frame(maxWidth: .infinity)
                .frame(height: TSButtonStyle.Size.medium.height)
                .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            StateFootnote("로딩 중에는 목록 항목을 사용할 수 없어요. 아직 결과 개수가 확정되지 않았어요.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// 14-4 불러오기 오류 — 비어 있는 상태와 구분되도록 다시 시도를 먼저 보여줘요.
struct ErrorStateView: View {
    let message: String
    var title = "목록을 불러오지 못했어요"
    var onBack: (() -> Void)?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                StateMessage(
                    icon: .cloudAlert,
                    tint: .tsNegative,
                    title: title,
                    titleStyle: .stateTitle,
                    message: message
                )
                .padding(.vertical, Spacing.xxxl + Spacing.xxs)
                Button("다시 시도", action: onRetry)
                    .buttonStyle(.tsPrimary)
                if let onBack {
                    Button("이전 화면으로 돌아가기", action: onBack)
                        .buttonStyle(.tsSecondary)
                }
            }
            .tsCard()
            InfoBanner(
                message: "내용이 없는 상태가 아니에요. 데이터를 불러오지 못해 결과와 개수를 확인할 수 없어요.",
                icon: .infoCircle,
                style: .hint
            )
            StateFootnote("문제가 계속되면 잠시 후 다시 시도해 주세요.")
        }
    }
}

/// 14-5 알림 진입 · 접근 불가 — 권한이 없으면 제목 · 요청자 · 금액 등은 보여주지 않아요.
struct AccessDeniedView: View {
    var code = "ACCESS-403"
    var onInquire: (() -> Void)?
    var backTitle = "이전 화면으로 돌아가기"
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.card) {
                TSIcon.circleX.sized(.stateSmall)
                    .foregroundStyle(Color.tsPrimary)
                    .accessibilityHidden(true)
                StatusBadge(title: "현재 계정에 권한 없음", tone: .neutral)
                Text("이 자료를 볼 수 있는\n권한이 없어요.")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Text("접근 권한이 변경되어 연결된 자료를 열 수 없어요. 필요한 업무라면 담당자에게 확인해 주세요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .lineSpacing(Spacing.xxs)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, Spacing.xl + Spacing.xxxs)

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("안전하게 보호된 자료")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text("자료 제목, 요청자, 금액 등 민감한 정보는 이 화면에 표시하지 않아요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .lineSpacing(Spacing.xxs)
                HStack(spacing: Spacing.lg) {
                    Text("문의 코드")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                        .frame(width: 88, alignment: .leading)
                    Text(code)
                        .tsFont(.footnoteMedium)
                        .foregroundStyle(Color.tsInk)
                        .textSelection(.enabled)
                }
                .accessibilityElement(children: .combine)
                StateFootnote("문의 시 이 코드와 알림을 받은 시각만 전달해 주세요.")
            }
            .fixedSize(horizontal: false, vertical: true)
            .tsCard()

            if let onInquire {
                Button("NativeOps에 권한 문의", action: onInquire)
                    .buttonStyle(.tsPrimary)
            }
            Button(backTitle, action: onBack)
                .buttonStyle(.tsSecondary)
            InfoBanner(
                message: "알림 링크로 들어와도 현재 권한을 우회하지 않아요. 권한 확인 후 허용된 내용만 표시해요.",
                icon: .infoCircle,
                style: .hint
            )
        }
    }
}

// MARK: - Parts

/// 14 공통 상태 맨 아래 회색 작은 설명
struct StateFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .tsFont(.caption2)
            .foregroundStyle(Color.tsInk3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 14-3 스켈레톤 카드 한 장 — 메타 · 상태 · 제목 · 설명 2줄 · 행동
private struct SkeletonCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top) {
                bar(width: 170, height: 12)
                Spacer(minLength: 0)
                Capsule().fill(Color.tsSurface2).frame(width: 48, height: 22)
            }
            bar(width: 125, height: 20, color: .tsLine)
            bar(width: nil, height: 12)
            bar(width: 225, height: 12)
            bar(width: 100, height: 12)
        }
        .padding(.vertical, Spacing.sm)
        .tsCard()
        .opacity(isDimmed ? 0.55 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isDimmed = true
            }
        }
    }

    private func bar(width: CGFloat?, height: CGFloat, color: Color = .tsSurface2) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

/// 14-3 불러오는 중 아이콘 (동작 줄이기면 멈춰 있어요)
private struct SpinningLoader: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSpinning = false

    var body: some View {
        TSIcon.loader.sized(.action)
            .foregroundStyle(Color.tsPrimary)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview("14-1 · 14-2") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            EmptyStateView(
                title: "아직 등록한 할 일이 없어요",
                message: "오늘 기억하고 싶은 일을 적어보세요.\n날짜나 프로젝트는 나중에 연결해도 좋아요.",
                actionTitle: "＋ 첫 할 일 추가",
                action: {}
            )
            NoResultsView(query: "Book-off", onResetFilters: {}, onEditQuery: {})
        }
        .padding(Spacing.screen)
    }
    .background(Color.tsBackground)
}

#Preview("14-3 · 14-4") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            LoadingSkeletonView(message: "프로젝트 목록을 불러오는 중이에요")
            ErrorStateView(
                message: "일시적인 연결 문제로 프로젝트를 표시할 수 없어요. 네트워크를 확인하고 다시 시도해 주세요.",
                onBack: {},
                onRetry: {}
            )
        }
        .padding(Spacing.screen)
    }
    .background(Color.tsBackground)
}

#Preview("14-5") {
    ScrollView {
        AccessDeniedView(onInquire: {}, backTitle: "알림 목록으로 돌아가기", onBack: {})
            .padding(Spacing.screen)
    }
    .background(Color.tsBackground)
}
