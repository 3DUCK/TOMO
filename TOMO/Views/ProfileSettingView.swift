//
// ProfileSettingsView.swift
//
// 이 파일은 앱의 '설정' 탭에 해당하는 뷰를 정의합니다.
// 사용자가 앱의 다양한 설정을 개인화할 수 있도록 UI를 제공합니다.
//
// 주요 기능:
// - 사용자 목표 문구 주제, 글꼴, 테마(다크/라이트 모드)를 설정할 수 있습니다.
// - 사용자 지정 배경 이미지를 앨범에서 선택하거나 기존 이미지를 제거할 수 있습니다.
// - 설정 변경 사항을 `UserSettings`를 통해 영구적으로 저장하고 앱 전반에 걸쳐 반영합니다.
// - 재사용 가능한 `CustomPicker` 컴포넌트를 사용하여 드롭다운 메뉴와 유사한 선택 기능을 제공합니다.
//

import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

/// 사용자가 앱의 다양한 설정을 개인화할 수 있는 프로필 및 설정 뷰.
/// 목표, 글꼴, 테마, 배경 이미지 등을 설정할 수 있습니다.
struct ProfileSettingsView: View {
    /// 사용자 설정(목표, 글꼴, 테마, 배경 이미지 등)을 관리하는 환경 객체.
    @EnvironmentObject var settings: UserSettings
    /// 이미지 피커(ImagePicker)를 표시할지 여부를 제어하는 상태 변수.
    @State private var showingImagePicker = false

    /// 목표 문구 주제에 대한 옵션 목록.
    let goalOptions = ["취업", "다이어트", "자기계발", "학업"]
    /// 폰트(글꼴)에 대한 옵션 목록.
    let fontOptions = ["고양일산 L", "고양일산 R", "조선일보명조"]
    /// 사운드 옵션 목록 (현재 사용되지 않지만, 확장성을 위해 포함될 수 있음).
    let soundOptions = ["기본", "차임벨", "알림음1"]
    /// 테마(다크/라이트 모드)에 대한 옵션 목록.
    let themeOptions = ["라이트", "다크"]

    /// `UserSettings`에 저장된 배경 이미지 데이터를 `UIImage`로 변환하여 반환합니다.
    /// 이미지가 없으면 `nil`을 반환합니다.
    var displayBackgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    /// 현재 시스템의 다크/라이트 모드 설정.
    @Environment(\.colorScheme) var currentColorScheme: ColorScheme

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            // MARK: - 전체 화면 크기 계산 (SafeArea 포함)
            // 배경 이미지가 전체 화면을 덮도록 하기 위함
            let totalWidth = geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
            let totalHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom

            ZStack {
                // MARK: - 배경 이미지 레이어
                if let bgImage = displayBackgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill() // 이미지를 화면에 꽉 채우도록 스케일
                        .frame(width: totalWidth, height: totalHeight)
                        .clipped() // 프레임을 벗어나는 부분은 잘라냄
                        .blur(radius: 5) // 배경 이미지에 블러 효과 적용
                        .overlay(
                            // 테마에 따라 오버레이 색상 및 투명도 조절
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) : // 다크 모드일 때 어둡게
                                      Color.white.opacity(0.5))   // 라이트 모드일 때 밝게
                                .frame(width: totalWidth, height: totalHeight)
                        )
                } else {
                    // 배경 이미지가 없을 경우 시스템 기본 배경색 사용
                    Color(.systemBackground)
                        .frame(width: totalWidth, height: totalHeight)
                }

                // MARK: - 프로필 사진 및 설정 Form을 담는 VStack
                VStack {
                    Spacer() // 상단에 공간을 주어 프로필 사진이 중앙에 가깝게 위치하도록 조정

                    // MARK: - 프로필 사진/배경 이미지 선택 버튼
                    Button(action: {
                        showingImagePicker = true // 이미지 피커 활성화
                    }) {
                        if let image = displayBackgroundImage {
                            // 배경 이미지가 설정되어 있으면 해당 이미지 표시
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 230)
                                .cornerRadius(20)
                                .overlay(
                                    // 흰색 테두리 추가
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 10) // 그림자 효과
                        } else {
                            // 배경 이미지가 없으면 기본 플레이스홀더 이미지 표시
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .frame(width: 300, height: 230)
                                .foregroundColor(.gray)
                                .background(Color.white.opacity(0.8)) // 반투명 흰색 배경
                                .cornerRadius(20)
                                .overlay(
                                    // 회색 테두리 추가
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(radius: 5) // 그림자 효과
                        }
                    }
                    .padding(.top, 50) // 상단 패딩
                    .offset(y: 20) // 약간 아래로 이동 (Spacer와 조합하여 위치 조정)

                    // MARK: - ScrollView + 설정 항목을 담는 VStack
                    ScrollView {
                        VStack(spacing: 12) {
                            // 목표 문구 주제 설정
                            VStack(alignment: .leading, spacing: 12) {
                                Text("목표 문구 주제")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "목표 문구 주제", options: goalOptions, selection: $settings.goal,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                
                                // 글꼴 설정
                                Text("글꼴")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "글꼴", options: fontOptions, selection: $settings.font,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                
                                // 테마 설정
                                Text("테마")
                                    .padding(.bottom, 3) // 약간 더 큰 아래 패딩
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "테마", options: themeOptions, selection: $settings.theme,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                
                                // 배경 이미지 선택 버튼
                                Text("배경 이미지")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                Button(action: {
                                    showingImagePicker = true // 이미지 피커 활성화
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("배경 이미지 선택")
                                            .font(settings.getCustomFont(size: 18))
                                            .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(.ultraThinMaterial) // 흐림 효과 배경
                                    .cornerRadius(12)
                                }
                                // MARK: - 배경 이미지 제거 버튼
                                Button(action: {
                                    settings.backgroundImageData = nil // 배경 이미지 데이터 삭제
                                    print("ProfileSettingsView 🗑️ Background image removed.")
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("배경 이미지 제거")
                                            .font(settings.getCustomFont(size: 18))
                                            .foregroundColor(.gray) // 회색 텍스트
                                        Spacer()
                                    }
                                    .padding(20) // 배경 이미지 선택 버튼보다 큰 패딩으로 시각적 구분
                                    .background(Color.clear) // 투명 배경
                                    .cornerRadius(12)
                                }
                            }
                            .padding() // VStack 내부의 설정 항목들에 패딩
                            .background(Color.clear) // 배경 투명
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24) // ScrollView 내부 VStack의 좌우 패딩
                        .padding(.bottom, 40) // 하단 패딩
                        .offset(y: 20) // 약간 아래로 이동하여 프로필 사진과 겹치지 않게
                    }
                }
            }
            .ignoresSafeArea(.all) // 모든 SafeArea 무시 (배경 이미지가 전체 화면을 덮도록)
            .preferredColorScheme(settings.preferredColorScheme) // 사용자 설정에 따른 다크/라이트 모드 적용
        }
        // 이미지 피커 시트
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: Binding(
                get: { self.displayBackgroundImage }, // 현재 이미지 표시
                set: { newImage in
                    // 선택된 새 이미지를 JPEG 데이터로 변환하여 UserSettings에 저장
                    self.settings.backgroundImageData = newImage?.jpegData(compressionQuality: 0.8)
                    print("ProfileSettingsView 📸 New background image selected and saved.")
                }
            ))
        }
        .onAppear {
            // 뷰가 나타날 때 초기 설정 로직 (현재는 추가적인 초기화 없음)
            print("ProfileSettingsView ➡️ onAppear: View appeared.")
        }
    }
}

// MARK: - 재사용 가능한 커스텀 피커 컴포넌트
/// 드롭다운 메뉴처럼 동작하며 옵션 목록 중 하나를 선택할 수 있는 재사용 가능한 SwiftUI 뷰.
/// - T: 선택 가능한 항목의 타입으로, `Hashable`과 `CustomStringConvertible`을 준수해야 합니다.
struct CustomPicker<T: Hashable & CustomStringConvertible>: View {
    let title: String          // 피커의 제목
    let options: [T]           // 선택 가능한 옵션 목록
    @Binding var selection: T  // 현재 선택된 값에 대한 바인딩
    var font: Font = .body     // 텍스트에 적용할 폰트
    var textColor: Color = .primary // 텍스트 색상
    var buttonBackgroundMaterial: Material = .ultraThinMaterial // 버튼 배경 재질
    var cornerRadius: CGFloat = 12 // 버튼의 모서리 둥글기 반경
    
    /// 현재 환경의 색상 스킴 (라이트/다크 모드).
    @Environment(\.colorScheme) var colorScheme
    /// 시트(Sheet)를 표시할지 여부를 제어하는 상태 변수.
    @State private var showSheet = false

    var body: some View {
        // 피커 버튼 (탭하면 옵션 시트가 나타남)
        Button(action: { showSheet = true }) {
            HStack {
                Spacer()
                Text(selection.description.isEmpty ? title : selection.description) // 선택된 값이 없으면 제목 표시
                    .font(font)
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(10)
            .background(buttonBackgroundMaterial)
            .cornerRadius(cornerRadius)
        }
        // 옵션 선택 시트
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 0) {
                // 시트 제목
                Text(title)
                    .font(.headline)
                    .padding()
                Divider() // 제목과 옵션 목록 사이 구분선
                
                // 옵션 목록 스크롤 뷰
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selection = option // 선택된 값 업데이트
                                showSheet = false   // 시트 닫기
                                print("CustomPicker ✅ Selected '\(option.description)' for \(title).")
                            }) {
                                HStack {
                                    Spacer()
                                    Text(option.description)
                                        .font(font)
                                        .foregroundColor(selection == option ? .accentColor : (colorScheme == .dark ? .white : .black)) // 선택된 항목 강조
                                    if selection == option {
                                        Image(systemName: "checkmark") // 선택된 항목에 체크마크 표시
                                            .foregroundColor(.accentColor)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(selection == option ? Color.accentColor.opacity(0.15) : Color.clear) // 선택된 항목 배경 강조
                            }
                            Divider() // 각 옵션 아이템 사이 구분선
                        }
                    }
                }
                // 닫기 버튼
                Button("닫기") { showSheet = false }
                    .font(.body)
                    .padding()
            }
            .background(colorScheme == .dark ? Color.black : Color.white) // 시트 배경색
            .presentationDetents([.medium, .large]) // iOS 15+에서 시트의 크기 조절 가능하게 함
        }
    }
}
