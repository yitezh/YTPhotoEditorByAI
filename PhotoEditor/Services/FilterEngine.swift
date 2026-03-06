import CoreImage
import UIKit

/// Core Image based filter engine that applies EditParameters to images
/// using a chain of CIFilters. Supports non-destructive editing by
/// building the filter chain on each render pass.
class FilterEngine {

    private let context: CIContext

    init() {
        // Use GPU rendering for better performance
        context = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true
        ])
    }

    // MARK: - Public API

    /// Apply all edit parameters to the source image and return the processed CIImage.
    /// The filter chain order: exposure → color controls → highlight/shadow →
    /// temperature/tint → vibrance → sharpen → crop → rotate.
    func apply(parameters: EditParameters, to image: CIImage) -> CIImage {
        var output = image

        // 1. Exposure: CIExposureAdjust
        output = applyExposure(output, value: parameters.exposure)

        // 2. Contrast + Saturation: CIColorControls
        output = applyColorControls(output, contrast: parameters.contrast, saturation: parameters.saturation)

        // 3. Highlights + Shadows: CIHighlightShadowAdjust
        output = applyHighlightShadow(output, highlights: parameters.highlights, shadows: parameters.shadows)

        // 4. Warmth (Temperature): CITemperatureAndTint
        output = applyTemperature(output, warmth: parameters.warmth)

        // 5. Vibrance: CIVibrance
        output = applyVibrance(output, value: parameters.vibrance)

        // 6. Sharpness: CISharpenLuminance
        output = applySharpness(output, value: parameters.sharpness)

        // 7. Crop
        if let codableCrop = parameters.cropRect {
            output = applyCrop(output, rect: codableCrop.cgRect)
        }

        // 8. Rotation
        if parameters.rotationCount > 0 {
            output = applyRotation(output, count: parameters.rotationCount)
        }

        return output
    }

    /// Generate a downsampled preview image for real-time display.
    func generatePreview(parameters: EditParameters, source: CIImage, targetSize: CGSize) -> UIImage? {
        // Downsample source first for performance
        let scale = min(targetSize.width / source.extent.width,
                        targetSize.height / source.extent.height,
                        1.0) // never upscale
        let downsampled: CIImage
        if scale < 1.0 {
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            downsampled = source.transformed(by: transform)
        } else {
            downsampled = source
        }

        let processed = apply(parameters: parameters, to: downsampled)

        guard let cgImage = context.createCGImage(processed, from: processed.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// Render the full resolution output as a CGImage.
    func renderFullResolution(parameters: EditParameters, source: CIImage) -> CGImage? {
        let processed = apply(parameters: parameters, to: source)
        return context.createCGImage(processed, from: processed.extent)
    }

    // MARK: - Private Filter Methods

    /// Map -100~+100 to CIExposureAdjust EV range: -3.0 ~ +3.0
    private func applyExposure(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let ev = value / 100.0 * 3.0 // maps to -3.0 ~ +3.0 EV
        guard let filter = CIFilter(name: "CIExposureAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: "inputEV")
        return filter.outputImage ?? image
    }

    /// Map contrast -100~+100 to CIColorControls range: 0.25 ~ 1.75 (default 1.0)
    /// Map saturation -100~+100 to CIColorControls range: 0.0 ~ 2.0 (default 1.0)
    private func applyColorControls(_ image: CIImage, contrast: Float, saturation: Float) -> CIImage {
        guard contrast != 0 || saturation != 0 else { return image }
        let ciContrast = 1.0 + contrast / 100.0 * 0.75  // 0.25 ~ 1.75
        let ciSaturation = 1.0 + saturation / 100.0      // 0.0 ~ 2.0
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ciContrast, forKey: "inputContrast")
        filter.setValue(ciSaturation, forKey: "inputSaturation")
        filter.setValue(Float(0), forKey: "inputBrightness")
        return filter.outputImage ?? image
    }

    /// Map highlights -100~+100 to CIHighlightShadowAdjust:
    ///   inputHighlightAmount: 0.0 ~ 2.0 (default 1.0)
    ///   inputShadowAmount: -1.0 ~ 1.0 (default 0.0)
    private func applyHighlightShadow(_ image: CIImage, highlights: Float, shadows: Float) -> CIImage {
        guard highlights != 0 || shadows != 0 else { return image }
        let hlAmount = 1.0 - highlights / 100.0  // -100→2.0 (reduce HL), +100→0.0 (boost HL)
        let shAmount = shadows / 100.0            // -100→-1.0, +100→1.0
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(hlAmount, forKey: "inputHighlightAmount")
        filter.setValue(shAmount, forKey: "inputShadowAmount")
        return filter.outputImage ?? image
    }

    /// Map warmth -100~+100 to CITemperatureAndTint:
    ///   inputNeutral: (4000, 0) ~ (8000, 0), default (6500, 0)
    ///   Negative = cooler (lower temp), Positive = warmer (higher temp)
    private func applyTemperature(_ image: CIImage, warmth: Float) -> CIImage {
        guard warmth != 0 else { return image }
        // Map -100~+100 to 4000K~8000K (neutral = 6500K)
        let temperature = 6500.0 + Double(warmth) / 100.0 * 1500.0
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: CGFloat(temperature), y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        return filter.outputImage ?? image
    }

    /// Map -100~+100 to CIVibrance amount: -1.0 ~ +1.0
    private func applyVibrance(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let amount = value / 100.0 // -1.0 ~ +1.0
        guard let filter = CIFilter(name: "CIVibrance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: "inputAmount")
        return filter.outputImage ?? image
    }

    /// Map 0~+100 to CISharpenLuminance sharpness: 0.0 ~ 2.0
    /// Negative values are clamped to 0 (no negative sharpening).
    private func applySharpness(_ image: CIImage, value: Float) -> CIImage {
        guard value != 0 else { return image }
        let sharpness = max(0, value) / 100.0 * 2.0 // 0.0 ~ 2.0
        guard let filter = CIFilter(name: "CISharpenLuminance") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(sharpness, forKey: "inputSharpness")
        return filter.outputImage ?? image
    }

    // MARK: - Crop & Rotation

    /// Crop the image to the specified rect.
    private func applyCrop(_ image: CIImage, rect: CGRect) -> CIImage {
        let clampedRect = rect.intersection(image.extent)
        guard !clampedRect.isEmpty else { return image }
        return image.cropped(to: clampedRect)
    }

    /// Rotate the image by 90° clockwise, repeated `count` times.
    /// count is expected to be 0-3 (mod 4).
    private func applyRotation(_ image: CIImage, count: Int) -> CIImage {
        let normalizedCount = ((count % 4) + 4) % 4
        guard normalizedCount > 0 else { return image }

        var output = image
        for _ in 0..<normalizedCount {
            output = rotate90Clockwise(output)
        }
        return output
    }

    /// Rotate a CIImage 90° clockwise.
    /// CIImage coordinate system is bottom-left origin, so a clockwise rotation
    /// in display coordinates is: rotate -90° then translate.
    private func rotate90Clockwise(_ image: CIImage) -> CIImage {
        let width = image.extent.width
        let height = image.extent.height

        // Rotate -90° (clockwise in standard coords)
        // Then translate so the image origin is back at (0,0)
        let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
        let translation = CGAffineTransform(translationX: 0, y: width)
        let transform = rotation.concatenating(translation)

        var rotated = image.transformed(by: transform)
        // Normalize origin to (0, 0)
        let origin = rotated.extent.origin
        if origin.x != 0 || origin.y != 0 {
            rotated = rotated.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
        }
        return rotated
    }
}
