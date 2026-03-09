import CoreImage
import UIKit

/// Central ViewModel coordinating editing state, filter engine, and edit history.
/// Manages parameter updates, filter preset application/removal, crop, undo/redo,
/// and notifies the UI layer via callbacks.
class PhotoEditorViewModel {

    // MARK: - Dependencies

    let filterEngine: FilterEngine
    let editHistory: EditHistory

    // MARK: - State

    /// Current editing parameters applied to the image
    private(set) var currentParameters: EditParameters = .default

    /// The currently active filter preset, nil if none
    private(set) var activeFilter: FilterPreset?

    /// Parameters saved before a filter was applied, used to restore on cancel
    private var preFilterParameters: EditParameters?

    /// The original source image (full resolution)
    var sourceImage: CIImage?

    /// Target size for preview generation
    var previewSize: CGSize = CGSize(width: 1080, height: 1920)

    // MARK: - Callbacks

    /// Called when the preview image needs to be refreshed
    var onPreviewUpdated: ((UIImage?) -> Void)?

    /// Called when undo/redo availability changes
    var onHistoryChanged: (() -> Void)?

    // MARK: - Computed Properties

    var canUndo: Bool { editHistory.canUndo }
    var canRedo: Bool { editHistory.canRedo }

    // MARK: - Init

    init(filterEngine: FilterEngine = FilterEngine(),
         editHistory: EditHistory = EditHistory()) {
        self.filterEngine = filterEngine
        self.editHistory = editHistory
        // Push initial default state so undo can always restore to baseline
        editHistory.push(currentParameters)
    }

    // MARK: - Parameter Updates

    /// Update a single adjustment parameter by key and refresh the preview.
    /// This version pushes to history immediately (used for non-interactive changes).
    func updateParameter(_ key: AdjustmentKey, value: Float) {
        let clamped = min(100, max(-100, value))
        switch key {
        case .exposure:   currentParameters.exposure = clamped
        case .contrast:   currentParameters.contrast = clamped
        case .highlights: currentParameters.highlights = clamped
        case .shadows:    currentParameters.shadows = clamped
        case .saturation: currentParameters.saturation = clamped
        case .vibrance:   currentParameters.vibrance = clamped
        case .warmth:     currentParameters.warmth = clamped
        case .sharpness:  currentParameters.sharpness = clamped
        }
        pushAndRefresh()
    }

    /// Update a single adjustment parameter without pushing to history.
    /// Used during interactive slider dragging for real-time preview.
    func updateParameterPreview(_ key: AdjustmentKey, value: Float) {
        let clamped = min(100, max(-100, value))
        switch key {
        case .exposure:   currentParameters.exposure = clamped
        case .contrast:   currentParameters.contrast = clamped
        case .highlights: currentParameters.highlights = clamped
        case .shadows:    currentParameters.shadows = clamped
        case .saturation: currentParameters.saturation = clamped
        case .vibrance:   currentParameters.vibrance = clamped
        case .warmth:     currentParameters.warmth = clamped
        case .sharpness:  currentParameters.sharpness = clamped
        }
        refreshPreview()
    }

    /// Commit the current parameter state to history.
    /// Called when user finishes interactive adjustment (e.g., slider touch up).
    func commitParameterChange() {
        editHistory.push(currentParameters)
        onHistoryChanged?()
    }

    /// Reset a single parameter to its default value (0).
    func resetParameter(_ key: AdjustmentKey) {
        updateParameter(key, value: 0)
    }

    // MARK: - Filter Presets

    /// Apply a filter preset. Saves current manual parameters so they can be
    /// restored if the filter is later removed.
    func applyFilter(_ preset: FilterPreset) {
        // Save current manual parameters before applying filter
        preFilterParameters = currentParameters

        // Copy the preset's adjustment values into current parameters,
        // preserving crop/rotation state
        var newParams = preset.parameters
        newParams.cropRect = currentParameters.cropRect
        newParams.rotationCount = currentParameters.rotationCount
        currentParameters = newParams

        activeFilter = preset
        pushAndRefresh()
    }

    /// Remove the currently active filter and restore the previous manual parameters.
    func removeFilter() {
        guard activeFilter != nil else { return }

        if let saved = preFilterParameters {
            // Restore saved manual parameters, preserving current crop/rotation
            var restored = saved
            restored.cropRect = currentParameters.cropRect
            restored.rotationCount = currentParameters.rotationCount
            currentParameters = restored
        }

        activeFilter = nil
        preFilterParameters = nil
        pushAndRefresh()
    }

    // MARK: - Crop

    /// Apply crop and rotation from the crop tool.
    func applyCrop(_ rect: CGRect, rotation: Int) {
        currentParameters.cropRect = CodableCGRect(rect)
        currentParameters.rotationCount = rotation
        pushAndRefresh()
    }

    // MARK: - Undo / Redo

    /// Undo the last edit operation.
    func undo() {
        if let restored = editHistory.undo() {
            currentParameters = restored
            refreshPreview()
            onHistoryChanged?()
        }
    }

    /// Redo the most recently undone operation.
    func redo() {
        if let restored = editHistory.redo() {
            currentParameters = restored
            refreshPreview()
            onHistoryChanged?()
        }
    }

    // MARK: - Private Helpers

    /// Push current parameters to history and refresh the preview.
    private func pushAndRefresh() {
        editHistory.push(currentParameters)
        onHistoryChanged?()
        refreshPreview()
    }

    /// Generate and deliver a new preview image from current parameters.
    private func refreshPreview() {
        guard let source = sourceImage else { return }
        let preview = filterEngine.generatePreview(
            parameters: currentParameters,
            source: source,
            targetSize: previewSize
        )
        onPreviewUpdated?(preview)
    }
}
