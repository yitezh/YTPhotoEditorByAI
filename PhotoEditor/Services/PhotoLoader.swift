import UIKit
import PhotosUI
import CoreImage

/// Handles photo selection via PHPickerViewController and loading the selected
/// image as a CIImage. Provides loading state callbacks for UI feedback.
class PhotoLoader: NSObject {

    // MARK: - Types

    enum LoadingState {
        case idle
        case loading
        case loaded(CIImage, UIImage)
        case failed(Error)
    }

    enum PhotoLoaderError: LocalizedError {
        case noImageSelected
        case loadFailed
        case ciImageCreationFailed

        var errorDescription: String? {
            switch self {
            case .noImageSelected:
                return "No image was selected."
            case .loadFailed:
                return "Failed to load the selected image."
            case .ciImageCreationFailed:
                return "Failed to create image for editing."
            }
        }
    }

    // MARK: - Callbacks

    /// Called when loading state changes
    var onStateChanged: ((LoadingState) -> Void)?

    // MARK: - State

    private(set) var state: LoadingState = .idle {
        didSet { onStateChanged?(state) }
    }

    // MARK: - Public API

    /// Present the photo picker from the given view controller.
    func presentPicker(from viewController: UIViewController) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoLoader: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else {
            state = .failed(PhotoLoaderError.noImageSelected)
            return
        }

        state = .loading

        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            state = .failed(PhotoLoaderError.loadFailed)
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.state = .failed(error)
                    return
                }

                guard let uiImage = object as? UIImage else {
                    self?.state = .failed(PhotoLoaderError.loadFailed)
                    return
                }

                // Create CIImage preserving orientation
                guard let ciImage = CIImage(image: uiImage) else {
                    self?.state = .failed(PhotoLoaderError.ciImageCreationFailed)
                    return
                }

                self?.state = .loaded(ciImage, uiImage)
            }
        }
    }
}
