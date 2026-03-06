import UIKit

/// Displays the photo preview with aspect-fit scaling.
/// Receives UIImage updates from the ViewModel layer.
class ImagePreviewView: UIView {

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        return iv
    }()

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
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    // MARK: - Public

    /// Update the displayed preview image.
    func updateImage(_ image: UIImage?) {
        imageView.image = image
    }

    /// The current displayed image.
    var currentImage: UIImage? {
        imageView.image
    }
}
