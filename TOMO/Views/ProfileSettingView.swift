// MARK: - ProfileSettingsView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct ProfileSettingsView: View {
    @EnvironmentObject var settings: UserSettings
    // @State private var backgroundImage: UIImage? = nil // 이제 settings에서 관리하므로 이 줄은 필요 없습니다.
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
                        .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                        .blur(radius: 5) // 원하는 블러 강도 값으로 조절하세요 (예: 5, 10, 20 등)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                        Color.black.opacity(0.5) :
                                        Color.white.opacity(0.5)
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height) // 오버레이도 정확한 크기
                        )
                } else {
                    // 배경 이미지가 없을 경우, 시스템 배경색 적용
                    Color(.systemBackground)
                        .frame(width: geometry.size.width, height: geometry.size.height) // 배경색도 정확한 크기
                }

                
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
                            // .font(settings.fontStyle) // 주석 해제하여 폰트 적용 가능

                            Picker("목표 문구 주제", selection: $settings.goal) {
                                ForEach(goalOptions, id: \.self) { goal in
                                    Text(goal).font(settings.getCustomFont(size: 16)) // 폰트 적용
                                }
                            }
                        }

                        Section(header: Text("개인화 설정")) {
                            Picker("글꼴", selection: $settings.font) {
                                ForEach(fontOptions, id: \.self) { font in
                                    Text(font).font(settings.getCustomFont(size: 16)) // 폰트 적용
                                }
                            }

                            Picker("알림음", selection: $settings.sound) {
                                ForEach(soundOptions, id: \.self) { sound in
                                    Text(sound).font(settings.getCustomFont(size: 16)) // 폰트 적용
                                }
                            }

                            Picker("테마", selection: $settings.theme) {
                                ForEach(themeOptions, id: \.self) { theme in
                                    Text(theme).font(settings.getCustomFont(size: 16)) // 폰트 적용
                                }
                            }

                            Button("배경 이미지 선택") {
                                showingImagePicker = true
                            }
                            // .font(settings.fontStyle) // 주석 해제하여 폰트 적용 가능
                        }
                    }
                    .offset(y: 100)
                    // MARK: - Form의 배경을 투명하게 설정하여 ZStack의 배경이 보이도록 함
                    .scrollContentBackground(.hidden)
                    .navigationTitle("설정")
                }
                // MARK: - NavigationView도 배경 이미지 위에 겹쳐지도록 투명한 배경 설정
                // .background(Color.clear) // NavigationView 자체에는 명시적으로 background를 주지 않아도 Form이 .hidden이면 잘 동작합니다.

            } // End of ZStack
            // MARK: - GeometryReader 자체가 안전 영역을 무시하도록 설정 (HistoryCalendarView와 동일)
            .ignoresSafeArea(.all)
            .preferredColorScheme(settings.preferredColorScheme)
        // toolbarColorScheme은 SwiftUI 4.0 이상에서만 적용 가능하며,
        // 배경 이미지와 ZStack으로 전체를 덮었기 때문에 NavigationBar의 배경은 이미 투명해졌을 수 있습니다.
        // .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)

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
