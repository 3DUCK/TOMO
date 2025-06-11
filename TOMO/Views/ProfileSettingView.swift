// MARK: - ProfileSettingsView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct ProfileSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    // @State private var backgroundImage: UIImage? = nil // 이제 settings에서 관리
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("프로필")) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let image = displayBackgroundImage { // displayBackgroundImage 사용
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }

                    TextField("닉네임", text: $settings.nickname)
//                        .font(settings.fontStyle)

                    Picker("목표 문구 주제", selection: $settings.goal) {
                        ForEach(goalOptions, id: \.self) { goal in
                            Text(goal).font(settings.fontStyle)
                        }
                    }
                }

                Section(header: Text("개인화 설정")) {
                    Picker("글꼴", selection: $settings.font) {
                        ForEach(fontOptions, id: \.self) { font in
                            Text(font).font(settings.fontStyle)
                        }
                    }

                    Picker("알림음", selection: $settings.sound) {
                        ForEach(soundOptions, id: \.self) { sound in
                            Text(sound).font(settings.fontStyle)
                        }
                    }

                    Picker("테마", selection: $settings.theme) {
                        ForEach(themeOptions, id: \.self) { theme in
                            Text(theme).font(settings.fontStyle)
                        }
                    }

                    Button("배경 이미지 선택") {
                        showingImagePicker = true
                    }
//                    .font(settings.fontStyle)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("설정")
            .sheet(isPresented: $showingImagePicker) {
                // ImagePicker에서 이미지를 선택하면 settings.backgroundImageData에 저장
                ImagePicker(image: Binding(
                    get: { self.displayBackgroundImage },
                    set: { newImage in
                        self.settings.backgroundImageData = newImage?.jpegData(compressionQuality: 0.8) // UIImage를 Data로 변환
                    }
                ))
            }
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)
        // .onAppear, .onDisappear 등 필요한 라이프사이클 훅 추가
    }
}
