// MARK: - ProfileSettingsView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct ProfileSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var showingImagePicker = false

    let goalOptions = ["취업", "다이어트", "자기계발", "학업"]
    let fontOptions = ["고양일산 L", "고양일산 R", "조선일보명조"] // 예시 폰트 옵션
    let soundOptions = ["기본", "차임벨", "알림음1"]
    let themeOptions = ["라이트", "다크"]

    // UI에 표시될 이미지 (UserSettings의 Data를 UIImage로 변환)
    var displayBackgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    // MARK: - Environment에서 colorScheme 직접 가져오기
    @Environment(\.colorScheme) var currentColorScheme: ColorScheme

    var body: some View {
        // MARK: - GeometryReader를 최상단에 배치하고 ignoresSafeArea() 적용 (HistoryCalendarView와 동일)
        GeometryReader { geometry in
            ZStack {
                // MARK: - 배경 이미지 레이어: geometry.size를 사용하여 정확한 화면 크기 적용 (HistoryCalendarView와 동일)
                if let bgImage = displayBackgroundImage { // settings.backgroundImageData에서 오는 이미지 사용
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height) // GeometryReader가 측정한 정확한 크기
//                        .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                        .blur(radius: 5) // 원하는 블러 강도 값으로 조절하세요 (예: 5, 10, 20 등)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                          Color.black.opacity(0.5) :
                                          Color.white.opacity(0.5)
                                      )
                                .frame(width: geometry.size.width, height: geometry.size.height + 300) // 오버레이도 정확한 크기
                        )
                } else {
                    // 배경 이미지가 없을 경우, 시스템 배경색 적용
                    Color(.systemBackground)
                        .frame(width: geometry.size.width, height: geometry.size.height) // 배경색도 정확한 크기
                }
                
                // MARK: - 프로필 사진과 Form을 담는 VStack 추가
                VStack {
                    Spacer() // 상단에 공간을 주어 프로필 사진 위치 조정

                    // MARK: - 프로필 사진 버튼 (Form 바깥으로 이동 및 사각형으로 변경)
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        if let image = displayBackgroundImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 10)
                        } else {
                            Image(systemName: "person.crop.rectangle.fill")
                                .resizable()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.gray)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.top, 50)
                    .offset(y: 20)

                    // MARK: - ScrollView + VStack으로 변경
                    ScrollView {
                        VStack(spacing: 12) {
                            // 프로필 Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("프로필")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                TextField("닉네임", text: $settings.nickname)
                                CustomPicker(title: "목표 문구 주제", options: goalOptions, selection: $settings.goal,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                            }
                            .padding()
                            .background(Color.clear) // 투명 배경
                            .cornerRadius(12)

                            // 개인화 설정 Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("개인화 설정")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "글꼴", options: fontOptions, selection: $settings.font,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "테마", options: themeOptions, selection: $settings.theme,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("배경 이미지 선택")
                                            .font(settings.getCustomFont(size: 18))
                                            .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(.ultraThinMaterial) // ⭐️ 수정된 부분: Color.ultraThinMaterial -> .ultraThinMaterial
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.clear) // 투명 배경
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .offset(y: 50)
                    }
                }
                // ...existing code...
            } // End of ZStack
            // MARK: - GeometryReader 자체가 안전 영역을 무시하도록 설정 (HistoryCalendarView와 동일)
            .ignoresSafeArea(.all)
            .preferredColorScheme(settings.preferredColorScheme)
            // toolbarColorScheme은 SwiftUI 4.0 이상에서만 적용 가능하며,
            // 배경 이미지와 ZStack으로 전체를 덮었기 때문에 NavigationBar의 배경은 이미 투명해졌을 수 있습니다.
            // .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)

        } // End of GeometryReader
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: Binding(
                get: { self.displayBackgroundImage },
                set: { newImage in
                    self.settings.backgroundImageData = newImage?.jpegData(compressionQuality: 0.8) // UIImage를 Data로 변환
                }
            ))
        }
        .onAppear {
            // 필요에 따라 초기 설정이나 데이터 로드 로직 추가
        }
    }
}

// MARK: - 재사용 가능한 커스텀 피커
struct CustomPicker<T: Hashable & CustomStringConvertible>: View {
    let title: String
    let options: [T]
    @Binding var selection: T
    var font: Font = .body
    var textColor: Color = .primary
    var buttonBackgroundMaterial: Material = .ultraThinMaterial // ⭐️ 수정된 부분: buttonColor -> buttonBackgroundMaterial 타입 변경
    var cornerRadius: CGFloat = 12
    @Environment(\.colorScheme) var colorScheme
    @State private var showSheet = false

    var body: some View {
        Button(action: { showSheet = true }) {
            HStack {
                Spacer()
                Text(selection.description.isEmpty ? title : selection.description)
                    .font(font)
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(10)
            .background(buttonBackgroundMaterial) // ⭐️ 수정된 부분: buttonColor -> buttonBackgroundMaterial 사용
            .cornerRadius(cornerRadius)
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.headline)
                    .padding()
                Divider()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selection = option
                                showSheet = false
                            }) {
                                HStack {
                                    Spacer()
                                    Text(option.description)
                                        .font(font)
                                        .foregroundColor(selection == option ? .accentColor : (colorScheme == .dark ? .white : .black))
                                    if selection == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(selection == option ? Color.accentColor.opacity(0.15) : Color.clear)
                            }
                            Divider()
                        }
                    }
                }
                Button("닫기") { showSheet = false }
                    .font(.body)
                    .padding()
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .presentationDetents([.medium, .large])
        }
    }
}
