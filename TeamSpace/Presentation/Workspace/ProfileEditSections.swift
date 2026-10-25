import SwiftUI
import PhotosUI

/// 07-13 입력 칸 — 이름 · 부서 · 한 줄 소개 · 관심사
struct ProfileEditFields: View {
    @Bindable var viewModel: ProfileEditViewModel
    let profile: MyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            ProfileField(title: "이름") {
                Text(profile.name).foregroundStyle(Color.tsInk2)
            }
            ProfileField(title: "부서 · 역할") {
                Text(profile.affiliation).foregroundStyle(Color.tsInk2)
            }
            ProfileField(title: "한 줄 소개") {
                TextField("나를 한 줄로 소개해 주세요", text: $viewModel.intro)
                    .foregroundStyle(Color.tsInk)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("관심사")
                    .tsFont(.captionBold)
                    .foregroundStyle(Color.tsInk3)
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(viewModel.interests, id: \.self) { interest in
                        Button { viewModel.removeInterest(interest) } label: {
                            HStack(spacing: Spacing.xxs) {
                                Text("# \(interest)")
                                TSIcon.close.sized(.xxs, weight: .bold)
                                    .foregroundStyle(Color.tsInk3)
                            }
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsInk)
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 32)
                            .background(Color.tsSurface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(interest) 관심사 삭제")
                    }
                    Button("+ 추가") { viewModel.isInterestAlertPresented = true }
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsPrimary)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 32)
                        .background(Color.tsPrimarySoft, in: Capsule())
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

/// 라벨 + 흰 입력 칸
private struct ProfileField<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk3)
            content()
                .tsFont(.body)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
    }
}

/// 07-16 미모티콘 바꾸기 시트 · 사진 고르기 · 관심사 추가 · 오류 알림
struct ProfileEditDialogs: ViewModifier {
    @Bindable var viewModel: ProfileEditViewModel
    @State private var photoItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("미모티콘 바꾸기", isPresented: $viewModel.isAvatarMenuPresented, titleVisibility: .visible) {
                Button("사진 보관함에서 선택") { viewModel.isPhotoPickerPresented = true }
                Button("미모티콘 스티커 붙여넣기") { viewModel.setAvatarImage(UIPasteboard.general.image?.pngData()) }
                Button("배경색 바꾸기") { viewModel.changeBackground() }
                Button("기본 이미지로 변경", role: .destructive) { viewModel.resetAvatar() }
                Button("취소", role: .cancel) {}
            }
            .photosPicker(isPresented: $viewModel.isPhotoPickerPresented, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    viewModel.setAvatarImage(try? await item.loadTransferable(type: Data.self))
                    photoItem = nil
                }
            }
            .alert("관심사 추가", isPresented: $viewModel.isInterestAlertPresented) {
                TextField("예) UI", text: $viewModel.newInterest)
                Button("추가") { viewModel.addInterest() }
                Button("취소", role: .cancel) { viewModel.newInterest = "" }
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("확인", role: .cancel) {}
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
