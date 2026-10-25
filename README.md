# TeamSpace-iOS

동아리 내부 운영 앱 **팀스페이스** iOS 클라이언트입니다.
SwiftUI · iOS 17 · `@Observable` · async/await · Clean Architecture (Presentation → Domain ← Data)

## 개발 환경 (VS Code)

macOS + **Xcode 16 이상** 설치가 필요해요. (편집·실행은 VS Code)

```bash
# 1) 도구 설치 (최초 1회)
brew install xcodegen xcode-build-server

# 2) 프로젝트 생성 — project.yml → TeamSpace.xcodeproj (git 에 올리지 않아요)
xcodegen generate

# 3) VS Code 자동완성 연결
xcode-build-server config -project TeamSpace.xcodeproj -scheme TeamSpace
```

VS Code 추천 확장: **SweetPad**(빌드·실행), **Swift**(자동완성).
SweetPad 패널 → Build & Run → 시뮬레이터 선택.
파일을 추가/삭제하면 `xcodegen generate` 를 다시 실행하세요.
`#Preview` 는 `open TeamSpace.xcodeproj` 로 Xcode 에서 확인할 수 있어요.

## 서버 연결

기본은 **Mock 서버**(`Data/Mock/MockTransport`)라 서버 없이 실행돼요. 응답은 API 명세서(Notion) 예시와 같은 `{ code, message, data }` 형식이에요.

| 입력 | 결과 |
| --- | --- |
| 아무 이메일 + 아무 비밀번호 | 200 로그인 성공 |
| 비밀번호 `wrong` | 401 → "이메일 또는 비밀번호를 다시 확인해 주세요." |

실서버를 쓰려면 `Config/Secrets.xcconfig.example` 을 `Config/Secrets.xcconfig` 로 복사하고
`API_BASE_URL` 을 채운 뒤 `USE_MOCK_API = NO` 로 바꾸세요. (`Secrets.xcconfig` 는 git 에 올라가지 않아요)

## 폴더 구조

```
TeamSpace/
├── App/            진입점, DIContainer(생성자 주입), Logger
├── Presentation/   기능 폴더 = View + ViewModel + 전용 컴포넌트
├── Domain/         Entity · UseCase · Repository Protocol (Foundation 만)
├── Data/           RepositoryImpl, 네트워크
├── DesignSystem/   디자인 토큰 + 공용 컴포넌트
└── Resources/      Assets
```

## 협업 규칙 (팀스 iOS 컨벤션)

- 이슈 / PR 제목: `[Feat] - #12 :: 프로젝트 목록 화면 구현`
- 브랜치: `feat/#12-project-list`
- 커밋: `feat: 프로젝트 목록 구현 (#12)` (이모지 X)
- PR 템플릿: 변경사항 · 검증 · 체크리스트 · 관련이슈
