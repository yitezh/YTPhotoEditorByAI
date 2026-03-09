import UIKit

/// Main photo editor view controller with Lightroom-style dark theme.
/// Layout: top navigation bar → image preview → tool tab bar → adjustment panel.
/// Binds to PhotoEditorViewModel for state management.
class PhotoEditorViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: PhotoEditorViewModel

    // MARK: - UI Components

    private let previewView = ImagePreviewView()
    private let toolTabBar = ToolTabBarView()
    private let adjustmentPanel = AdjustmentPanelView()
    private let filterPresetView = FilterPresetView()
    private let cropOverlayView = CropOverlayView()

    /// Pending source image to set after layout is ready
    private var pendingSourceImage: UIImage?

    /// Retained during export to prevent premature deallocation
    private var activeExportManager: ExportManager?

    /// ViewModel for crop state management
    private lazy var cropViewModel = CropViewModel(imageBounds: .zero)

    // Navigation bar buttons
    private let backButton = UIButton(type: .system)
    private let undoButton = UIButton(type: .system)
    private let redoButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    private let navBar = UIView()

    // MARK: - Colors

    private let bgColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0) // #1A1A1A
    private let textColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0) // #E0E0E0
    private let disabledColor = UIColor(white: 0.35, alpha: 1.0)

    // MARK: - Init

    init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        setupNavBar()
        setupSubviews()
        bindViewModel()

        // Show initial tab
        adjustmentPanel.switchToTab(.light, parameters: viewModel.currentParameters, animated: false)
        updateHistoryButtons()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Process any pending source image now that layout is complete
        if let image = pendingSourceImage {
            pendingSourceImage = nil
            applySourceImage(image)
        }
    }

    // MARK: - Theme

    private func setupTheme() {
        view.backgroundColor = bgColor
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation Bar

    private func setupNavBar() {
        navBar.backgroundColor = bgColor

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)

        configureNavButton(backButton, systemName: "chevron.left", config: symbolConfig)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        configureNavButton(undoButton, systemName: "arrow.uturn.backward", config: symbolConfig)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)

        configureNavButton(redoButton, systemName: "arrow.uturn.forward", config: symbolConfig)
        redoButton.addTarget(self, action: #selector(redoTapped), for: .touchUpInside)

        configureNavButton(exportButton, systemName: "square.and.arrow.up", config: symbolConfig)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)

        navBar.addSubview(backButton)
        navBar.addSubview(undoButton)
        navBar.addSubview(redoButton)
        navBar.addSubview(exportButton)
        view.addSubview(navBar)
    }

    private func configureNavButton(_ button: UIButton, systemName: String, config: UIImage.SymbolConfiguration) {
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = textColor
    }

    // MARK: - Subviews

    private func setupSubviews() {
        view.addSubview(previewView)
        view.addSubview(toolTabBar)
        view.addSubview(adjustmentPanel)
        view.addSubview(filterPresetView)
        view.addSubview(cropOverlayView)

        toolTabBar.delegate = self
        adjustmentPanel.delegate = self
        filterPresetView.delegate = self
        cropOverlayView.delegate = self

        // Filter preset view is hidden by default, shown when effects tab is selected
        filterPresetView.isHidden = true
        // Crop overlay is hidden by default
        cropOverlayView.isHidden = true
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let w = view.bounds.width

        // Nav bar
        let navHeight: CGFloat = 44
        navBar.frame = CGRect(x: 0, y: safeTop, width: w, height: navHeight)

        let btnSize: CGFloat = 44
        backButton.frame = CGRect(x: 8, y: 0, width: btnSize, height: navHeight)
        exportButton.frame = CGRect(x: w - btnSize - 8, y: 0, width: btnSize, height: navHeight)
        redoButton.frame = CGRect(x: exportButton.frame.minX - btnSize - 4, y: 0, width: btnSize, height: navHeight)
        undoButton.frame = CGRect(x: redoButton.frame.minX - btnSize - 4, y: 0, width: btnSize, height: navHeight)

        // Bottom area
        let tabBarHeight: CGFloat = 44
        let panelHeight: CGFloat = 200
        let bottomAreaHeight = tabBarHeight + panelHeight + safeBottom

        // Preview fills remaining space
        let previewTop = navBar.frame.maxY
        let previewHeight = view.bounds.height - previewTop - bottomAreaHeight
        previewView.frame = CGRect(x: 0, y: previewTop, width: w, height: previewHeight)

        // Tool tab bar
        toolTabBar.frame = CGRect(x: 0, y: previewView.frame.maxY, width: w, height: tabBarHeight)

        // Adjustment panel
        adjustmentPanel.frame = CGRect(x: 0, y: toolTabBar.frame.maxY, width: w, height: panelHeight + safeBottom)

        // Filter preset view shares the same frame as adjustment panel
        filterPresetView.frame = adjustmentPanel.frame
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.onPreviewUpdated = { [weak self] image in
            DispatchQueue.main.async {
                self?.previewView.updateImage(image)
            }
        }

        viewModel.onHistoryChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.updateHistoryButtons()
            }
        }
    }

    private func updateHistoryButtons() {
        undoButton.isEnabled = viewModel.canUndo
        undoButton.tintColor = viewModel.canUndo ? textColor : disabledColor

        redoButton.isEnabled = viewModel.canRedo
        redoButton.tintColor = viewModel.canRedo ? textColor : disabledColor
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func undoTapped() {
        viewModel.undo()
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }

    @objc private func redoTapped() {
        viewModel.redo()
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }

    @objc private func exportTapped() {
        let alert = UIAlertController(title: "导出照片", message: "选择导出格式", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "JPEG（高质量）", style: .default) { [weak self] _ in
            self?.performExport(format: .jpeg, quality: 90)
        })
        alert.addAction(UIAlertAction(title: "PNG（无损）", style: .default) { [weak self] _ in
            self?.performExport(format: .png, quality: 100)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        // iPad popover anchor
        if let popover = alert.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }

        present(alert, animated: true)
    }

    private func performExport(format: ExportFormat, quality: Int) {
        guard let source = viewModel.sourceImage else { return }

        let exportManager = ExportManager(filterEngine: viewModel.filterEngine)
        activeExportManager = exportManager

        // Show progress HUD
        let progressAlert = UIAlertController(title: "导出中…", message: "\n", preferredStyle: .alert)
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 20, y: 60, width: 230, height: 2)
        progressAlert.view.addSubview(progressView)
        present(progressAlert, animated: true)

        exportManager.onProgress = { progress in
            DispatchQueue.main.async {
                progressView.setProgress(progress, animated: true)
            }
        }

        exportManager.export(
            source: source,
            parameters: viewModel.currentParameters,
            format: format,
            quality: quality
        ) { [weak self] result in
            progressAlert.dismiss(animated: true) {
                switch result {
                case .success:
                    self?.showExportSuccess()
                case .failure(let error):
                    self?.showExportError(error)
                }
            }
        }
    }

    private func showExportSuccess() {
        let alert = UIAlertController(title: "导出成功", message: "照片已保存到相册", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    private func showExportError(_ error: Error) {
        let alert = UIAlertController(title: "导出失败", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.exportTapped()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Public

    /// Update the preview with a new source image.
    func setSourceImage(_ image: UIImage) {
        // If preview view hasn't been laid out yet, defer until viewDidAppear
        if previewView.bounds.width == 0 || previewView.bounds.height == 0 {
            pendingSourceImage = image
            return
        }
        applySourceImage(image)
    }

    private func applySourceImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        viewModel.sourceImage = ciImage
        viewModel.previewSize = CGSize(width: previewView.bounds.width * UIScreen.main.scale,
                                       height: previewView.bounds.height * UIScreen.main.scale)
        // Generate initial preview
        let preview = viewModel.filterEngine.generatePreview(
            parameters: viewModel.currentParameters,
            source: ciImage,
            targetSize: viewModel.previewSize
        )
        previewView.updateImage(preview)

        // Generate a small thumbnail for filter preset previews
        let thumbSize = CGSize(width: 144, height: 144)
        let thumbPreview = viewModel.filterEngine.generatePreview(
            parameters: .default,
            source: ciImage,
            targetSize: thumbSize
        )
        filterPresetView.updateThumbnail(thumbPreview)
    }

    /// Configure the available filter presets.
    func setFilterPresets(_ presets: [FilterPreset]) {
        filterPresetView.configure(presets: presets, thumbnailImage: nil)
    }

    /// Enter crop mode: show the crop overlay on top of the preview.
    func enterCropMode() {
        // Show the original (uncropped but rotated) image as background for the crop overlay
        if let source = viewModel.sourceImage {
            var noCropParams = viewModel.currentParameters
            noCropParams.cropRect = nil
            // Keep the current rotation
            let uncropped = viewModel.filterEngine.generatePreview(
                parameters: noCropParams,
                source: source,
                targetSize: viewModel.previewSize
            )
            previewView.updateImage(uncropped)
        }

        // Calculate the actual image display rect within the preview view (aspect-fit)
        let imageDisplayRect = calculateImageDisplayRect(rotationCount: viewModel.currentParameters.rotationCount)

        cropViewModel = CropViewModel(imageBounds: imageDisplayRect)
        cropViewModel.saveState()

        // Convert existing image-space crop rect back to view coordinates for display
        var initialViewCropRect: CGRect? = nil
        if let codableRect = viewModel.currentParameters.cropRect {
            initialViewCropRect = convertImageRectToViewRect(codableRect.cgRect)
        }
        cropViewModel.rotationCount = viewModel.currentParameters.rotationCount

        cropOverlayView.frame = CGRect(
            x: previewView.frame.origin.x,
            y: previewView.frame.origin.y,
            width: previewView.frame.width,
            height: view.bounds.height - previewView.frame.origin.y
        )
        cropOverlayView.configure(
            imageBounds: imageDisplayRect,
            initialCropRect: initialViewCropRect,
            rotationCount: cropViewModel.rotationCount
        )
        cropOverlayView.isHidden = false

        // Hide bottom controls while cropping
        toolTabBar.isHidden = true
        adjustmentPanel.isHidden = true
        filterPresetView.isHidden = true
        navBar.isHidden = true
    }

    /// Calculate the aspect-fit display rect of the source image within the preview view.
    /// Takes into account the current rotation count (odd rotations swap width/height).
    private func calculateImageDisplayRect(rotationCount: Int = 0) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return previewView.bounds }

        let imageExtent = sourceImage.extent
        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0,
              imageExtent.width > 0, imageExtent.height > 0 else {
            return previewView.bounds
        }

        // Odd rotation counts swap width and height
        let imageW: CGFloat
        let imageH: CGFloat
        if rotationCount % 2 == 0 {
            imageW = imageExtent.width
            imageH = imageExtent.height
        } else {
            imageW = imageExtent.height
            imageH = imageExtent.width
        }

        let imageAspect = imageW / imageH
        let viewAspect = viewSize.width / viewSize.height

        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            let offsetY = (viewSize.height - displayHeight) / 2
            return CGRect(x: 0, y: offsetY, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            let offsetX = (viewSize.width - displayWidth) / 2
            return CGRect(x: offsetX, y: 0, width: displayWidth, height: displayHeight)
        }
    }

    /// Convert a rect from CIImage pixel coordinates back to the preview view's coordinate space.
    /// Takes rotation into account - the imageRect should be in the rotated image's coordinate space.
    private func convertImageRectToViewRect(_ imageRect: CGRect) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return imageRect }

        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return imageRect }

        // Get the rotated image extent (swap width/height for odd rotation counts)
        let originalExtent = sourceImage.extent
        let rotationCount = viewModel.currentParameters.rotationCount
        
        let rotatedWidth: CGFloat
        let rotatedHeight: CGFloat
        if rotationCount % 2 == 0 {
            rotatedWidth = originalExtent.width
            rotatedHeight = originalExtent.height
        } else {
            rotatedWidth = originalExtent.height
            rotatedHeight = originalExtent.width
        }

        let imageAspect = rotatedWidth / rotatedHeight
        let viewAspect = viewSize.width / viewSize.height

        var displayRect: CGRect
        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            let offsetY = (viewSize.height - displayHeight) / 2
            displayRect = CGRect(x: 0, y: offsetY, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            let offsetX = (viewSize.width - displayWidth) / 2
            displayRect = CGRect(x: offsetX, y: 0, width: displayWidth, height: displayHeight)
        }

        let scaleX = displayRect.width / rotatedWidth
        let scaleY = displayRect.height / rotatedHeight

        let viewX = imageRect.origin.x * scaleX + displayRect.origin.x
        let viewW = imageRect.width * scaleX
        let viewH = imageRect.height * scaleY
        // Flip Y axis: CIImage bottom-left → UIKit top-left
        let viewY = displayRect.maxY - (imageRect.origin.y + imageRect.height) * scaleY

        return CGRect(x: viewX, y: viewY, width: viewW, height: viewH)
    }

    /// Exit crop mode and restore normal editing UI.
    private func exitCropMode() {
        cropOverlayView.isHidden = true
        navBar.isHidden = false
        toolTabBar.isHidden = false

        // Restore the correct panel based on current tab
        let currentTab = toolTabBar.selectedTab
        if currentTab == .effects {
            filterPresetView.isHidden = false
        } else {
            adjustmentPanel.isHidden = false
        }
    }
}

// MARK: - ToolTabBarViewDelegate

extension PhotoEditorViewController: ToolTabBarViewDelegate {
    func toolTabBarView(_ tabBar: ToolTabBarView, didSelectTab tab: ToolTab) {
        if tab == .crop {
            enterCropMode()
            // Reset tab selection back to previous non-crop tab after entering crop mode
            toolTabBar.selectTab(.light, animated: false)
        } else if tab == .effects {
            // Show filter presets, hide adjustment sliders
            adjustmentPanel.isHidden = true
            filterPresetView.isHidden = false
        } else {
            // Show adjustment sliders, hide filter presets
            filterPresetView.isHidden = true
            adjustmentPanel.isHidden = false
            adjustmentPanel.switchToTab(tab, parameters: viewModel.currentParameters, animated: true)
        }
    }
}

// MARK: - AdjustmentPanelViewDelegate

extension PhotoEditorViewController: AdjustmentPanelViewDelegate {
    func adjustmentPanelView(_ panel: AdjustmentPanelView, didChangeValue value: Float, forKey key: AdjustmentKey) {
        // During slider dragging: update preview only, don't push to history
        viewModel.updateParameterPreview(key, value: value)
    }

    func adjustmentPanelView(_ panel: AdjustmentPanelView, didEndChangingValue value: Float, forKey key: AdjustmentKey) {
        // When slider touch ends: commit to history
        viewModel.commitParameterChange()
    }

    func adjustmentPanelView(_ panel: AdjustmentPanelView, didResetKey key: AdjustmentKey) {
        viewModel.resetParameter(key)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }
}

// MARK: - FilterPresetViewDelegate

extension PhotoEditorViewController: FilterPresetViewDelegate {
    func filterPresetView(_ view: FilterPresetView, didSelectPreset preset: FilterPreset) {
        viewModel.applyFilter(preset)
        filterPresetView.setActivePreset(preset.id)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }

    func filterPresetViewDidRemoveFilter(_ view: FilterPresetView) {
        viewModel.removeFilter()
        filterPresetView.setActivePreset(nil)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
    }
}

// MARK: - CropOverlayViewDelegate

extension PhotoEditorViewController: CropOverlayViewDelegate {
    func cropOverlayViewDidConfirm(_ view: CropOverlayView, cropRect: CGRect, rotationCount: Int) {
        // Convert crop rect from view coordinates to CIImage pixel coordinates (in rotated space)
        let imageCropRect = convertViewRectToImageRect(cropRect, rotationCount: rotationCount)
        viewModel.applyCrop(imageCropRect, rotation: rotationCount)
        adjustmentPanel.updateValues(from: viewModel.currentParameters)
        exitCropMode()
    }

    /// Convert a rect from the preview view's coordinate space to the rotated CIImage's pixel coordinate space.
    /// The output rect is in the rotated image's coordinate system (after rotation has been applied).
    private func convertViewRectToImageRect(_ viewRect: CGRect, rotationCount: Int) -> CGRect {
        guard let sourceImage = viewModel.sourceImage else { return viewRect }

        let viewSize = previewView.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return viewRect }

        // Get the rotated image dimensions (swap width/height for odd rotation counts)
        let originalExtent = sourceImage.extent
        let rotatedWidth: CGFloat
        let rotatedHeight: CGFloat
        if rotationCount % 2 == 0 {
            rotatedWidth = originalExtent.width
            rotatedHeight = originalExtent.height
        } else {
            rotatedWidth = originalExtent.height
            rotatedHeight = originalExtent.width
        }

        // Calculate the aspect-fit display rect based on rotated dimensions
        let imageAspect = rotatedWidth / rotatedHeight
        let viewAspect = viewSize.width / viewSize.height

        var displayRect: CGRect
        if imageAspect > viewAspect {
            let displayWidth = viewSize.width
            let displayHeight = viewSize.width / imageAspect
            let offsetY = (viewSize.height - displayHeight) / 2
            displayRect = CGRect(x: 0, y: offsetY, width: displayWidth, height: displayHeight)
        } else {
            let displayHeight = viewSize.height
            let displayWidth = viewSize.height * imageAspect
            let offsetX = (viewSize.width - displayWidth) / 2
            displayRect = CGRect(x: offsetX, y: 0, width: displayWidth, height: displayHeight)
        }

        // Scale factor from display to rotated image pixels
        let scaleX = rotatedWidth / displayRect.width
        let scaleY = rotatedHeight / displayRect.height

        // Convert view rect to rotated image pixel coordinates
        let imageX = (viewRect.origin.x - displayRect.origin.x) * scaleX
        // Flip Y axis: UIKit origin is top-left, CIImage origin is bottom-left
        let viewBottomY = viewRect.origin.y + viewRect.height
        let imageY = (displayRect.maxY - viewBottomY) * scaleY
        let imageW = viewRect.width * scaleX
        let imageH = viewRect.height * scaleY

        return CGRect(x: imageX, y: imageY, width: imageW, height: imageH)
    }

    func cropOverlayViewDidCancel(_ view: CropOverlayView) {
        cropViewModel.restoreState()
        exitCropMode()
    }

    func cropOverlayViewDidRotate(_ view: CropOverlayView) {
        cropViewModel.rotate90Clockwise()
        cropOverlayView.rotationCount = cropViewModel.rotationCount

        // Update the background preview to show the rotated (but uncropped) image
        guard let source = viewModel.sourceImage else { return }
        var rotatedParams = viewModel.currentParameters
        rotatedParams.cropRect = nil
        rotatedParams.rotationCount = cropViewModel.rotationCount
        let rotatedPreview = viewModel.filterEngine.generatePreview(
            parameters: rotatedParams,
            source: source,
            targetSize: viewModel.previewSize
        )
        previewView.updateImage(rotatedPreview)

        // Recalculate image display rect for the rotated image and reset crop frame
        let imageDisplayRect = calculateImageDisplayRect(rotationCount: cropViewModel.rotationCount)
        cropOverlayView.configure(
            imageBounds: imageDisplayRect,
            initialCropRect: nil,
            rotationCount: cropViewModel.rotationCount
        )
    }
}
