import UIKit

/// Delegate for crop overlay user actions.
protocol CropOverlayViewDelegate: AnyObject {
    /// Called when the user confirms the crop.
    func cropOverlayViewDidConfirm(_ view: CropOverlayView, cropRect: CGRect, rotationCount: Int)
    /// Called when the user cancels the crop.
    func cropOverlayViewDidCancel(_ view: CropOverlayView)
    /// Called when the user taps the rotate button.
    func cropOverlayViewDidRotate(_ view: CropOverlayView)
}

/// Full-screen overlay for interactive cropping.
/// Features: draggable crop frame, semi-transparent mask outside crop area,
/// aspect ratio selector, rotate button, confirm/cancel buttons.
class CropOverlayView: UIView {

    // MARK: - Properties

    weak var delegate: CropOverlayViewDelegate?

    /// The current crop rectangle in this view's coordinate space.
    private(set) var cropRect: CGRect = .zero

    /// The image display area within this view (set externally).
    private var imageBounds: CGRect = .zero

    /// Current rotation count from the CropViewModel.
    var rotationCount: Int = 0

    /// Minimum crop dimension
    private let minCropSize: CGFloat = 60

    /// Handle size for corner/edge dragging
    private let handleSize: CGFloat = 44

    // MARK: - Drag State

    private enum DragEdge {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case move
        case none
    }
    private var activeDrag: DragEdge = .none
    private var dragStartPoint: CGPoint = .zero
    private var dragStartRect: CGRect = .zero

    // MARK: - Aspect Ratio

    private var selectedAspectRatio: AspectRatio = .free

    // MARK: - UI Components

    private let maskLayer = CAShapeLayer()

    private let cropBorderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.borderWidth = 1.5
        v.isUserInteractionEnabled = false
        return v
    }()

    // Grid lines (rule of thirds)
    private let gridLayer = CAShapeLayer()

    // Corner handles
    private var cornerHandles: [UIView] = []

    // Bottom toolbar
    private let toolbarView = UIView()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let rotateButton = UIButton(type: .system)

    // Aspect ratio bar
    private let aspectRatioBar = UIScrollView()
    private var aspectRatioButtons: [UIButton] = []

    // MARK: - Colors

    private let maskColor = UIColor.black.withAlphaComponent(0.6)
    private let accentColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        // Semi-transparent mask
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = maskColor.cgColor
        layer.addSublayer(maskLayer)

        // Crop border
        addSubview(cropBorderView)

        // Grid lines
        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = nil
        cropBorderView.layer.addSublayer(gridLayer)

        // Corner handles
        for _ in 0..<4 {
            let handle = UIView()
            handle.backgroundColor = .white
            handle.isUserInteractionEnabled = false
            addSubview(handle)
            cornerHandles.append(handle)
        }

        setupToolbar()
        setupAspectRatioBar()
        setupGestures()
    }

    private func setupToolbar() {
        toolbarView.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 0.95)
        addSubview(toolbarView)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)

        cancelButton.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig), for: .normal)
        cancelButton.tintColor = accentColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        confirmButton.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig), for: .normal)
        confirmButton.tintColor = accentColor
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        rotateButton.setImage(UIImage(systemName: "rotate.right", withConfiguration: symbolConfig), for: .normal)
        rotateButton.tintColor = accentColor
        rotateButton.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)

        toolbarView.addSubview(cancelButton)
        toolbarView.addSubview(confirmButton)
        toolbarView.addSubview(rotateButton)
    }

    private func setupAspectRatioBar() {
        aspectRatioBar.backgroundColor = .clear
        aspectRatioBar.showsHorizontalScrollIndicator = false
        addSubview(aspectRatioBar)

        let ratios = AspectRatio.allCases
        for (index, ratio) in ratios.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(ratio.displayName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.tintColor = ratio == .free ? accentColor : UIColor(white: 0.5, alpha: 1.0)
            button.tag = index
            button.addTarget(self, action: #selector(aspectRatioTapped(_:)), for: .touchUpInside)
            aspectRatioBar.addSubview(button)
            aspectRatioButtons.append(button)
        }
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height
        let safeBottom = safeAreaInsets.bottom

        // Toolbar at bottom
        let toolbarHeight: CGFloat = 50
        toolbarView.frame = CGRect(x: 0, y: h - toolbarHeight - safeBottom, width: w, height: toolbarHeight + safeBottom)

        let btnSize: CGFloat = 50
        cancelButton.frame = CGRect(x: 16, y: 0, width: btnSize, height: toolbarHeight)
        rotateButton.frame = CGRect(x: (w - btnSize) / 2, y: 0, width: btnSize, height: toolbarHeight)
        confirmButton.frame = CGRect(x: w - btnSize - 16, y: 0, width: btnSize, height: toolbarHeight)

        // Aspect ratio bar above toolbar
        let ratioBarHeight: CGFloat = 36
        aspectRatioBar.frame = CGRect(x: 0, y: toolbarView.frame.minY - ratioBarHeight, width: w, height: ratioBarHeight)
        layoutAspectRatioButtons()

        updateMask()
        updateCropBorder()
        updateCornerHandles()
        updateGridLines()
    }

    private func layoutAspectRatioButtons() {
        let buttonWidth: CGFloat = 56
        let spacing: CGFloat = 8
        let totalWidth = CGFloat(aspectRatioButtons.count) * buttonWidth + CGFloat(aspectRatioButtons.count - 1) * spacing
        let startX = max(12, (aspectRatioBar.bounds.width - totalWidth) / 2)

        for (index, button) in aspectRatioButtons.enumerated() {
            button.frame = CGRect(
                x: startX + CGFloat(index) * (buttonWidth + spacing),
                y: 0,
                width: buttonWidth,
                height: aspectRatioBar.bounds.height
            )
        }
        aspectRatioBar.contentSize = CGSize(
            width: startX + totalWidth + 12,
            height: aspectRatioBar.bounds.height
        )
    }

    // MARK: - Public

    /// Configure the overlay with the image display bounds and initial crop rect.
    func configure(imageBounds: CGRect, initialCropRect: CGRect?, rotationCount: Int) {
        self.imageBounds = imageBounds
        self.rotationCount = rotationCount
        self.cropRect = initialCropRect ?? imageBounds
        setNeedsLayout()
    }

    /// Update the selected aspect ratio from external state.
    func setAspectRatio(_ ratio: AspectRatio) {
        selectedAspectRatio = ratio
        updateAspectRatioHighlight()
    }

    // MARK: - Mask

    private func updateMask() {
        let fullPath = UIBezierPath(rect: bounds)
        let cropPath = UIBezierPath(rect: cropRect)
        fullPath.append(cropPath)
        maskLayer.path = fullPath.cgPath
    }

    // MARK: - Crop Border & Grid

    private func updateCropBorder() {
        cropBorderView.frame = cropRect
    }

    private func updateGridLines() {
        let w = cropRect.width
        let h = cropRect.height
        let path = UIBezierPath()

        // Vertical thirds
        for i in 1...2 {
            let x = w * CGFloat(i) / 3.0
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
        }
        // Horizontal thirds
        for i in 1...2 {
            let y = h * CGFloat(i) / 3.0
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: w, y: y))
        }
        gridLayer.path = path.cgPath
        gridLayer.frame = cropBorderView.bounds
    }

    // MARK: - Corner Handles

    private func updateCornerHandles() {
        let handleLength: CGFloat = 20
        let handleThickness: CGFloat = 3
        let r = cropRect

        // We draw L-shaped corners using simple rectangles
        // For simplicity, each "handle" is a small square at the corner
        let positions: [CGPoint] = [
            CGPoint(x: r.minX, y: r.minY),     // top-left
            CGPoint(x: r.maxX, y: r.minY),     // top-right
            CGPoint(x: r.minX, y: r.maxY),     // bottom-left
            CGPoint(x: r.maxX, y: r.maxY)      // bottom-right
        ]

        for (index, pos) in positions.enumerated() {
            let handle = cornerHandles[index]
            let offsetX: CGFloat = (index % 2 == 0) ? -handleThickness / 2 : -handleLength + handleThickness / 2
            let offsetY: CGFloat = (index < 2) ? -handleThickness / 2 : -handleLength + handleThickness / 2
            handle.frame = CGRect(x: pos.x + offsetX, y: pos.y + offsetY, width: handleLength, height: handleLength)
            handle.backgroundColor = .clear

            // Remove old sublayers
            handle.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

            // Horizontal bar
            let hBar = CALayer()
            let hY: CGFloat = (index < 2) ? 0 : handleLength - handleThickness
            let hX: CGFloat = (index % 2 == 0) ? 0 : handleLength - handleLength
            hBar.frame = CGRect(x: hX, y: hY, width: handleLength, height: handleThickness)
            hBar.backgroundColor = UIColor.white.cgColor
            handle.layer.addSublayer(hBar)

            // Vertical bar
            let vBar = CALayer()
            let vX: CGFloat = (index % 2 == 0) ? 0 : handleLength - handleThickness
            let vY: CGFloat = (index < 2) ? 0 : 0
            vBar.frame = CGRect(x: vX, y: vY, width: handleThickness, height: handleLength)
            vBar.backgroundColor = UIColor.white.cgColor
            handle.layer.addSublayer(vBar)
        }
    }

    // MARK: - Aspect Ratio Highlight

    private func updateAspectRatioHighlight() {
        let ratios = AspectRatio.allCases
        for (index, button) in aspectRatioButtons.enumerated() {
            let isSelected = ratios[index] == selectedAspectRatio
            button.tintColor = isSelected ? accentColor : UIColor(white: 0.5, alpha: 1.0)
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.cropOverlayViewDidCancel(self)
    }

    @objc private func confirmTapped() {
        delegate?.cropOverlayViewDidConfirm(self, cropRect: cropRect, rotationCount: rotationCount)
    }

    @objc private func rotateTapped() {
        delegate?.cropOverlayViewDidRotate(self)
    }

    @objc private func aspectRatioTapped(_ sender: UIButton) {
        let ratios = AspectRatio.allCases
        let ratio = ratios[sender.tag]
        selectedAspectRatio = ratio
        updateAspectRatioHighlight()
        applyAspectRatioConstraint()
    }

    // MARK: - Aspect Ratio Constraint

    private func applyAspectRatioConstraint() {
        guard let targetRatio = selectedAspectRatio.ratioValue else { return }

        let centerX = cropRect.midX
        let centerY = cropRect.midY
        var newWidth = cropRect.width
        var newHeight = cropRect.height

        let currentRatio = newWidth / newHeight
        if currentRatio > targetRatio {
            newWidth = newHeight * targetRatio
        } else {
            newHeight = newWidth / targetRatio
        }

        // Clamp to image bounds
        newWidth = min(newWidth, imageBounds.width)
        newHeight = min(newHeight, imageBounds.height)

        var originX = centerX - newWidth / 2
        var originY = centerY - newHeight / 2

        originX = max(imageBounds.minX, min(originX, imageBounds.maxX - newWidth))
        originY = max(imageBounds.minY, min(originY, imageBounds.maxY - newHeight))

        cropRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)

        UIView.animate(withDuration: 0.2) {
            self.updateMask()
            self.updateCropBorder()
            self.updateCornerHandles()
            self.updateGridLines()
        }
    }

    // MARK: - Pan Gesture (Drag Crop Frame)

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)

        switch gesture.state {
        case .began:
            activeDrag = detectDragEdge(at: point)
            dragStartPoint = point
            dragStartRect = cropRect

        case .changed:
            let dx = point.x - dragStartPoint.x
            let dy = point.y - dragStartPoint.y
            applyCropDrag(dx: dx, dy: dy)
            updateMask()
            updateCropBorder()
            updateCornerHandles()
            updateGridLines()

        case .ended, .cancelled:
            activeDrag = .none

        default:
            break
        }
    }

    private func detectDragEdge(at point: CGPoint) -> DragEdge {
        let r = cropRect
        let margin = handleSize / 2

        let nearLeft = abs(point.x - r.minX) < margin
        let nearRight = abs(point.x - r.maxX) < margin
        let nearTop = abs(point.y - r.minY) < margin
        let nearBottom = abs(point.y - r.maxY) < margin

        // Corners first
        if nearTop && nearLeft { return .topLeft }
        if nearTop && nearRight { return .topRight }
        if nearBottom && nearLeft { return .bottomLeft }
        if nearBottom && nearRight { return .bottomRight }

        // Edges
        if nearTop { return .top }
        if nearBottom { return .bottom }
        if nearLeft { return .left }
        if nearRight { return .right }

        // Inside = move
        if r.contains(point) { return .move }

        return .none
    }

    private func applyCropDrag(dx: CGFloat, dy: CGFloat) {
        var r = dragStartRect

        switch activeDrag {
        case .move:
            r.origin.x += dx
            r.origin.y += dy
            // Clamp to image bounds
            r.origin.x = max(imageBounds.minX, min(r.origin.x, imageBounds.maxX - r.width))
            r.origin.y = max(imageBounds.minY, min(r.origin.y, imageBounds.maxY - r.height))

        case .topLeft:
            r = adjustEdge(rect: r, dMinX: dx, dMinY: dy, dMaxX: 0, dMaxY: 0)
        case .topRight:
            r = adjustEdge(rect: r, dMinX: 0, dMinY: dy, dMaxX: dx, dMaxY: 0)
        case .bottomLeft:
            r = adjustEdge(rect: r, dMinX: dx, dMinY: 0, dMaxX: 0, dMaxY: dy)
        case .bottomRight:
            r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: dx, dMaxY: dy)
        case .top:
            r = adjustEdge(rect: r, dMinX: 0, dMinY: dy, dMaxX: 0, dMaxY: 0)
        case .bottom:
            r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: 0, dMaxY: dy)
        case .left:
            r = adjustEdge(rect: r, dMinX: dx, dMinY: 0, dMaxX: 0, dMaxY: 0)
        case .right:
            r = adjustEdge(rect: r, dMinX: 0, dMinY: 0, dMaxX: dx, dMaxY: 0)
        case .none:
            return
        }

        cropRect = r

        // Re-apply aspect ratio constraint if not free
        if selectedAspectRatio != .free {
            applyAspectRatioConstraint()
        }
    }

    /// Adjust a rect by deltas on each edge, clamping to image bounds and minimum size.
    private func adjustEdge(rect: CGRect, dMinX: CGFloat, dMinY: CGFloat, dMaxX: CGFloat, dMaxY: CGFloat) -> CGRect {
        var minX = rect.minX + dMinX
        var minY = rect.minY + dMinY
        var maxX = rect.maxX + dMaxX
        var maxY = rect.maxY + dMaxY

        // Clamp to image bounds
        minX = max(imageBounds.minX, minX)
        minY = max(imageBounds.minY, minY)
        maxX = min(imageBounds.maxX, maxX)
        maxY = min(imageBounds.maxY, maxY)

        // Enforce minimum size
        if maxX - minX < minCropSize {
            if dMinX != 0 { minX = maxX - minCropSize }
            else { maxX = minX + minCropSize }
        }
        if maxY - minY < minCropSize {
            if dMinY != 0 { minY = maxY - minCropSize }
            else { maxY = minY + minCropSize }
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Hit Test

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Allow interaction with the entire overlay
        return bounds.contains(point)
    }
}
