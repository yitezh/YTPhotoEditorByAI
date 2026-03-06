import UIKit
import Photos
import CoreImage

/// Manages full-resolution rendering and saving edited photos to the user's
/// photo library. Supports JPEG and PNG formats with configurable quality.
class ExportManager {

    // MARK: - Types

    enum ExportError: LocalizedError {
        case renderFailed
        case encodingFailed
        case saveFailed(Error)
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "Failed to render the full resolution image."
            case .encodingFailed:
                return "Failed to encode the image data."
            case .saveFailed(let error):
                return "Failed to save to photo library: \(error.localizedDescription)"
            case .permissionDenied:
                return "Photo library access is required to save images. Please enable it in Settings."
            }
        }
    }

    // MARK: - Dependencies

    private let filterEngine: FilterEngine

    // MARK: - Callbacks

    /// Called with progress value 0.0 to 1.0 during export
    var onProgress: ((Float) -> Void)?

    // MARK: - Init

    init(filterEngine: FilterEngine) {
        self.filterEngine = filterEngine
    }

    // MARK: - Public API

    /// Export the edited photo to the user's photo library.
    /// - Parameters:
    ///   - source: The original CIImage
    ///   - parameters: Current edit parameters to apply
    ///   - format: Export format (JPEG or PNG)
    ///   - quality: JPEG quality 1-100, default 90. Ignored for PNG.
    ///   - completion: Result callback on main thread
    func export(
        source: CIImage,
        parameters: EditParameters,
        format: ExportFormat,
        quality: Int = 90,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let clampedQuality = min(100, max(1, quality))

        onProgress?(0.1)

        // Render on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Step 1: Render full resolution
            guard let cgImage = self.filterEngine.renderFullResolution(
                parameters: parameters,
                source: source
            ) else {
                DispatchQueue.main.async {
                    self.onProgress?(0)
                    completion(.failure(ExportError.renderFailed))
                }
                return
            }

            DispatchQueue.main.async { self.onProgress?(0.4) }

            // Step 2: Encode to data
            let uiImage = UIImage(cgImage: cgImage)
            let imageData: Data?

            switch format {
            case .jpeg:
                imageData = uiImage.jpegData(compressionQuality: CGFloat(clampedQuality) / 100.0)
            case .png:
                imageData = uiImage.pngData()
            }

            guard let data = imageData else {
                DispatchQueue.main.async {
                    self.onProgress?(0)
                    completion(.failure(ExportError.encodingFailed))
                }
                return
            }

            DispatchQueue.main.async { self.onProgress?(0.7) }

            // Step 3: Save to photo library
            self.saveToPhotoLibrary(data: data, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.onProgress?(1.0)
                        completion(.success(()))
                    case .failure(let error):
                        self.onProgress?(0)
                        completion(.failure(error))
                    }
                }
            })
        }
    }

    // MARK: - Private

    private func saveToPhotoLibrary(
        data: Data,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(.failure(ExportError.permissionDenied))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: options)
            }, completionHandler: { success, error in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(ExportError.saveFailed(
                        error ?? NSError(domain: "ExportManager", code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "Unknown save error"])
                    )))
                }
            })
        }
    }
}
