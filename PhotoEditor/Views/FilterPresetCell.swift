import UIKit

/// Collection view cell displaying a filter preset thumbnail and name.
/// Active preset is highlighted with a colored border.
class FilterPresetCell: UICollectionViewCell {

    static let reuseId = "FilterPresetCell"

    // MARK: - UI

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor(white: 0.7, alpha: 1.0)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    // MARK: - Colors

    private let activeBorderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0) // #E0E0E0
    private let activeTextColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
    private let normalTextColor = UIColor(white: 0.7, alpha: 1.0)

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
        contentView.addSubview(thumbnailView)
        contentView.addSubview(nameLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.bounds.width
        let thumbSize: CGFloat = w
        let thumbHeight: CGFloat = thumbSize
        thumbnailView.frame = CGRect(x: 0, y: 0, width: thumbSize, height: thumbHeight)
        nameLabel.frame = CGRect(x: 0, y: thumbHeight + 4, width: w, height: 16)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        thumbnailView.layer.borderWidth = 0
        nameLabel.text = nil
    }

    // MARK: - Configure

    func configure(preset: FilterPreset, thumbnail: UIImage?, isActive: Bool) {
        nameLabel.text = preset.name
        thumbnailView.image = thumbnail

        if isActive {
            thumbnailView.layer.borderWidth = 2
            thumbnailView.layer.borderColor = activeBorderColor.cgColor
            nameLabel.textColor = activeTextColor
        } else {
            thumbnailView.layer.borderWidth = 0
            thumbnailView.layer.borderColor = nil
            nameLabel.textColor = normalTextColor
        }
    }
}
