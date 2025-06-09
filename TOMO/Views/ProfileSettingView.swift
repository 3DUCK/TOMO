// MARK: - ProfileSettingsView.swift
import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var backgroundImage: UIImage? = nil
    @State private var showingImagePicker = false

    let goalOptions = ["취업", "다이어트", "자기계발", "학업"]
    let fontOptions = ["산세리프", "세리프"]
    let soundOptions = ["기본", "차임벨", "알림음1"]
    let themeOptions = ["라이트", "다크"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("프로필")) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let image = backgroundImage {
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
                        .font(settings.fontStyle)

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
                    .font(settings.fontStyle)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("설정")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $backgroundImage)
            }
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)
    }
}
