//
// ImagePicker.swift

/// `ImagePicker`는 SwiftUI에서 iOS의 `PHPickerViewController`를 사용할 수 있도록 래핑하는 구조체입니다.
/// 사용자 앨범에서 이미지를 선택하여 앱으로 가져오는 기능을 제공합니다.
///
/// 이 `UIViewControllerRepresentable`은 다음과 같은 역할을 수행합니다:
/// 1. `PHPickerConfiguration`을 설정하여 단일 이미지만 선택 가능하도록 합니다.
/// 2. 사용자가 이미지를 선택하면 해당 이미지를 `UIImage` 형태로 `@Binding` 변수에 전달합니다.
/// 3. 시스템의 사진 접근 권한을 자동으로 처리합니다.
///

import SwiftUI
import PhotosUI // PHPickerViewController를 사용하기 위해 임포트

struct ImagePicker: UIViewControllerRepresentable {
    /// 선택된 이미지를 바인딩하여 상위 뷰로 전달하는 `UIImage` 타입의 바인딩 변수.
    @Binding var image: UIImage?

    /// `PHPickerViewController`를 생성하고 초기 설정을 적용합니다.
    /// - Parameter context: 환경 정보에 접근할 수 있는 컨텍스트.
    /// - Returns: 설정된 `PHPickerViewController` 인스턴스.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1 // 단일 이미지 선택 제한
        config.filter = .images   // 이미지 파일만 필터링

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator // 코디네이터를 델리게이트로 설정
        return picker
    }

    /// `PHPickerViewController`를 업데이트합니다. (여기서는 추가적인 업데이트 로직이 필요하지 않습니다.)
    /// - Parameters:
    ///   - uiViewController: 업데이트할 `PHPickerViewController` 인스턴스.
    ///   - context: 환경 정보에 접근할 수 있는 컨텍스트.
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    /// `ImagePicker`와 `PHPickerViewControllerDelegate` 프로토콜 사이의 통신을 관리하는 코디네이터를 생성합니다.
    /// - Returns: `Coordinator` 인스턴스.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// `PHPickerViewController`의 델리게이트 메서드를 구현하여 이미지 선택 결과를 처리하는 코디네이터 클래스.
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        /// 부모 `ImagePicker` 뷰에 대한 참조.
        let parent: ImagePicker

        /// `Coordinator` 초기화.
        /// - Parameter parent: 이 코디네이터를 생성한 `ImagePicker` 인스턴스.
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// 이미지가 선택되거나 선택이 취소될 때 호출되는 델리게이트 메서드.
        /// - Parameters:
        ///   - picker: 이미지가 선택된 `PHPickerViewController` 인스턴스.
        ///   - results: 선택된 이미지들의 결과 배열.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true) // 이미지 선택기를 닫습니다.

            // 첫 번째 결과의 itemProvider가 UIImage를 로드할 수 있는지 확인
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            // 이미지 로드를 비동기적으로 수행
            provider.loadObject(ofClass: UIImage.self) { image, error in
                // UI 업데이트는 메인 스레드에서 수행해야 합니다.
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.parent.image = uiImage // 선택된 이미지를 @Binding 변수에 할당
                    } else if let error = error {
                        print("ImagePicker ❌ Error loading image: \(error.localizedDescription)")
                    } else {
                        print("ImagePicker ⚠️ Could not load image as UIImage.")
                    }
                }
            }
        }
    }
}
