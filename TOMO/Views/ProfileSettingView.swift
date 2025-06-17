// MARK: - ProfileSettingsView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct ProfileSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var showingImagePicker = false

    let goalOptions = ["취업", "다이어트", "자기계발", "학업"]
    let fontOptions = ["고양일산 L", "고양일산 R", "조선일보명조"]
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
        GeometryReader { geometry in
            // MARK: - 전체 화면 크기 계산
            let totalWidth = geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
            let totalHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom

            ZStack {
                // MARK: - 배경 이미지 레이어
                if let bgImage = displayBackgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: totalWidth, height: totalHeight)
                        .blur(radius: 5)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                          Color.black.opacity(0.5) :
                                          Color.white.opacity(0.5))
                                .frame(width: totalWidth, height: totalHeight)
                        )
                } else {
                    Color(.systemBackground)
                        .frame(width: totalWidth, height: totalHeight)
                }

                // MARK: - 프로필 사진과 Form을 담는 VStack
                VStack {
                    Spacer() // 상단에 공간을 주어 프로필 사진 위치 조정

                    // MARK: - 프로필 사진 버튼
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        if let image = displayBackgroundImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 230)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(radius: 10)
                        } else {
                            Image(systemName: "photo.artframe")
                                .resizable()
                                .frame(width: 300, height: 230)
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

                    // MARK: - ScrollView + VStack
                    ScrollView {
                        VStack(spacing: 12) {
                            // 프로필 Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("목표 문구 주제")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "목표 문구 주제", options: goalOptions, selection: $settings.goal,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                Text("글꼴")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "글꼴", options: fontOptions, selection: $settings.font,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                Text("테마")
                                    .padding(.bottom, 3)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                CustomPicker(title: "테마", options: themeOptions, selection: $settings.theme,
                                             font: settings.getCustomFont(size: 18),
                                             textColor: currentColorScheme == .dark ? .white : .black)
                                Text("배경 이미지")
                                    .padding(.bottom, 1)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black)
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
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                }
                                // MARK: - 배경 이미지 제거 버튼
                                Button(action: {
                                    settings.backgroundImageData = nil
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("배경 이미지 제거")
                                            .font(settings.getCustomFont(size: 18))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    .padding(20)
                                    .background(Color.clear)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .offset(y: 20)
                    }
                }
            }
            .ignoresSafeArea(.all)
            .preferredColorScheme(settings.preferredColorScheme)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: Binding(
                get: { self.displayBackgroundImage },
                set: { newImage in
                    self.settings.backgroundImageData = newImage?.jpegData(compressionQuality: 0.8)
                }
            ))
        }
        .onAppear {
            // 초기 설정 로직
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
    var buttonBackgroundMaterial: Material = .ultraThinMaterial
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
            .background(buttonBackgroundMaterial)
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
