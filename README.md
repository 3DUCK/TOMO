# TOMO: 동기부여 명언 & 기록 iOS 위젯 앱

---

### iOS프로그래밍[7] 미니 프로젝트
### 1971448 김건우

---

## 시연 영상
[![TOMO 시연<img width="784" alt="스크린샷 2025-06-18 22 20 34" src="https://github.com/user-attachments/assets/fb35e0a4-afb9-448e-a229-c4911f5e887c" />
 영상](https://youtu.be/NZ7QS8mZqpo)


---

## 소개
TOMO는 사용자의 목표(취업, 다이어트, 자기계발, 학업)에 맞는 맞춤형 동기부여 문구를 매일 제공하고, 자신의 감정과 메모를 기록할 수 있는 iOS 앱입니다. Firebase Cloud Functions와 Firestore를 백엔드로 사용하며, SwiftUI 기반의 현대적인 UI/UX, 위젯, 다크/라이트 테마, 커스텀 폰트, 배경 이미지 등 다양한 개인화 기능을 지원합니다.

---

## 주요 기능
- **오늘의 문구**: 목표별로 매일 새로운 명언을 AI(OpenAI)로 생성, Firestore에서 실시간 제공
- **히스토리(기록) 캘린더**: 날짜별로 과거 명언, 감정, 메모를 캘린더와 리스트로 조회/검색/필터링
- **감정 태그 & 메모**: 각 명언에 감정 이모티콘과 메모를 추가, 수정, 저장 가능
- **목표/테마/폰트/배경 이미지 설정**: 사용자 맞춤 목표, 테마(다크/라이트), 폰트, 배경 이미지 선택 지원
- **iOS 위젯 지원**: 오늘의 문구를 홈 화면 위젯으로 표시
- **Firebase Cloud Functions**: 매일 4개 주제별 명언 자동 생성 및 Firestore 저장
- **앱/위젯 데이터 동기화**: App Group, UserDefaults, WidgetKit 활용

---

## 아키텍처
<img width="1680" alt="스크린샷 2025-06-18 22 19 12" src="https://github.com/user-attachments/assets/2d5ff7f8-90b6-4c22-99eb-e8bf999b62a8" />


---

## 프로젝트 구조
```
TOMO/
├── AppConstants.swift           # 앱 전역 상수 정의
├── FSCalendarRepresentable.swift # UIKit 캘린더 SwiftUI 래퍼
├── GoogleService-Info.plist      # Firebase 설정 파일
├── Models/
│   ├── Quote.swift               # 명언(문구) 데이터 모델
│   └── User.swift                # 사용자 설정/프로필 모델
├── Resources/
│   ├── *.TTF                     # 커스텀 폰트 파일
│   └── Assets.xcassets/          # 앱 아이콘, 색상 등
├── Services/
│   └── QuoteService.swift        # Firestore 연동 서비스
├── ViewModels/
│   └── QuoteViewModel.swift      # 명언/기록 데이터 관리
├── Views/
│   ├── HistoryCalendarView.swift # 기록(히스토리) 캘린더/리스트 뷰
│   ├── ImagePicker.swift         # 배경 이미지 선택 뷰
│   ├── MainTabView.swift         # 메인 탭 네비게이션
│   ├── MemoEditView.swift        # 메모/감정 편집 시트
│   ├── ProfileSettingView.swift  # 설정(목표, 폰트, 테마 등)
│   └── TodayQuoteView.swift      # 오늘의 문구 뷰
│
├── TOMOApp.swift                 # 앱 진입점
├── Info.plist, TOMO.entitlements # 앱 설정/권한
│
├── TOMOWidget/                   # iOS 위젯 확장
│   ├── TOMOWidget.swift, ...
│   └── Assets.xcassets/
│
└── tomo-functions/               # Firebase Cloud Functions 백엔드
    ├── src/index.ts              # 명언 생성/저장 함수 (Node.js, TypeScript)
    ├── package.json, tsconfig.json, ...
    └── ...
```

---

## 기술 스택
- **iOS 앱**: Swift, SwiftUI, Combine, WidgetKit, UIKit(일부), App Group
- **백엔드**: Firebase Cloud Functions (Node.js/TypeScript), Firestore, OpenAI API
- **기타**: GoogleService-Info.plist, App Entitlements, Custom Font, Assets

---

## 빌드 및 실행 방법
1. **Firebase 프로젝트 및 Firestore, Functions, 인증 활성화**
2. `GoogleService-Info.plist`를 TOMO 프로젝트에 추가
3. `pod install` 또는 Swift Package Manager로 Firebase SDK 설치
4. Xcode에서 `TOMO.xcodeproj` 열기
5. 빌드 타겟: iOS 15.0 이상 권장
6. 앱 실행 (시뮬레이터/실기기)
7. 백엔드 함수 배포:
   ```bash
   cd tomo-functions/functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

---

## 주요 파일 설명
- **Quote.swift**: 명언 데이터 모델, Firestore 연동, 목표별 필드(employment, diet, selfdev, study) 지원
- **QuoteService.swift**: Firestore에서 오늘의 문구/모든 문구 조회, 메모/감정 업데이트
- **QuoteViewModel.swift**: 앱/위젯 데이터 동기화, UserDefaults 캐싱, UI 데이터 제공
- **HistoryCalendarView.swift**: 날짜/감정/검색어 기반 기록 필터링, 메모 편집
- **TodayQuoteView.swift**: 목표별 오늘의 문구 표시, 타이핑 애니메이션, 배경 이미지 지원
- **ProfileSettingView.swift**: 목표, 폰트, 테마, 배경 이미지 등 사용자 설정
- **tomo-functions/src/index.ts**: 매일 4개 주제별 명언 생성, Firestore 저장 (KST 기준)

---

## 환경설정 및 권한
- **App Group**: 앱-위젯 데이터 공유 (group.geonu.tomo)
- **Firebase**: Firestore, Functions, 인증 활성화 필요
- **Custom Font**: 고양일산 L/R, 조선일보명조 포함
- **iOS 권한**: 사진 접근(배경 이미지), 네트워크 등

---
