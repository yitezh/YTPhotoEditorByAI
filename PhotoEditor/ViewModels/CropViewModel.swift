import CoreGraphics

/// ViewModel managing crop and rotation state for the crop tool.
/// Tracks crop rect, aspect ratio constraint, and rotation count.
class CropViewModel {

    // MARK: - Properties

    /// Current crop rectangle in image coordinates
    var cropRect: CGRect

    /// Currently selected aspect ratio constraint
    var aspectRatio: AspectRatio = .free

    /// Number of 90° clockwise rotations (0–3)
    var rotationCount: Int = 0

    /// Snapshot of state before entering crop mode, used for cancel/restore
    private var savedCropRect: CGRect
    private var savedAspectRatio: AspectRatio = .free
    private var savedRotationCount: Int = 0

    // MARK: - Init

    /// Initialize with the full image bounds as the default crop rect.
    init(imageBounds: CGRect) {
        self.cropRect = imageBounds
        self.savedCropRect = imageBounds
    }

    // MARK: - Actions

    /// Rotate the image 90° clockwise. Wraps around after 4 rotations.
    func rotate90Clockwise() {
        rotationCount = (rotationCount + 1) % 4
    }

    /// Constrain the current cropRect to the selected aspect ratio.
    /// Keeps the center of the crop rect and shrinks the larger dimension.
    /// Does nothing for `.free` aspect ratio.
    func constrainToAspectRatio(within bounds: CGRect) {
        guard let targetRatio = aspectRatio.ratioValue else { return }

        let currentWidth = cropRect.width
        let currentHeight = cropRect.height
        let centerX = cropRect.midX
        let centerY = cropRect.midY

        var newWidth: CGFloat
        var newHeight: CGFloat

        // Determine whether to shrink width or height
        let currentRatio = currentWidth / currentHeight
        if currentRatio > targetRatio {
            // Too wide — shrink width
            newHeight = currentHeight
            newWidth = currentHeight * targetRatio
        } else {
            // Too tall — shrink height
            newWidth = currentWidth
            newHeight = currentWidth / targetRatio
        }

        // Clamp to bounds
        newWidth = min(newWidth, bounds.width)
        newHeight = min(newHeight, bounds.height)

        // Re-center
        var originX = centerX - newWidth / 2
        var originY = centerY - newHeight / 2

        // Keep within bounds
        originX = max(bounds.origin.x, min(originX, bounds.maxX - newWidth))
        originY = max(bounds.origin.y, min(originY, bounds.maxY - newHeight))

        cropRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
    }

    /// Save current state so it can be restored on cancel.
    func saveState() {
        savedCropRect = cropRect
        savedAspectRatio = aspectRatio
        savedRotationCount = rotationCount
    }

    /// Restore the state saved before entering crop mode.
    func restoreState() {
        cropRect = savedCropRect
        aspectRatio = savedAspectRatio
        rotationCount = savedRotationCount
    }

    /// Reset crop rect to the given image bounds and clear rotation.
    func reset(to imageBounds: CGRect) {
        cropRect = imageBounds
        aspectRatio = .free
        rotationCount = 0
    }
}
