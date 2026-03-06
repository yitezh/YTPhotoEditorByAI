import UIKit

/// Delegate for filter preset selection events.
protocol FilterPresetViewDelegate: AnyObject {
    /// Called when a filter preset is tapped. If the same preset is already active, this signals removal.
    func filterPresetView(_ view: FilterPresetView, didSelectPreset preset: FilterPreset)
    /// Called when the active filter should be removed (tapped again).
    func filterPresetViewDidRemoveFilter(_ view: FilterPresetView)
}

/// Horizontal scrollable collection of filter preset thumbnails.
/// Tapping a preset applies it; tapping the active preset removes it.
/// The active preset cell is highlighted with a border.
class FilterPresetView: UIView {

    // MARK: - Properties

    weak var delegate: FilterPresetViewDelegate?

    private var presets: [FilterPreset] = []
    private var activePresetId: String?
    private var thumbnailImage: UIImage?

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 72, height: 92)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(FilterPresetCell.self, forCellWithReuseIdentifier: FilterPresetCell.reuseId)
        return cv
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
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }

    // MARK: - Public

    /// Configure with filter presets and a thumbnail source image.
    func configure(presets: [FilterPreset], thumbnailImage: UIImage?) {
        self.presets = presets
        self.thumbnailImage = thumbnailImage
        collectionView.reloadData()
    }

    /// Update the active filter highlight. Pass nil to clear.
    func setActivePreset(_ presetId: String?) {
        activePresetId = presetId
        collectionView.reloadData()
    }

    /// Update the thumbnail used for preset previews.
    func updateThumbnail(_ image: UIImage?) {
        self.thumbnailImage = image
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension FilterPresetView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        presets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterPresetCell.reuseId, for: indexPath) as! FilterPresetCell
        let preset = presets[indexPath.item]
        let isActive = preset.id == activePresetId
        cell.configure(preset: preset, thumbnail: thumbnailImage, isActive: isActive)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension FilterPresetView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let preset = presets[indexPath.item]
        if preset.id == activePresetId {
            // Tapping the active preset removes it
            delegate?.filterPresetViewDidRemoveFilter(self)
        } else {
            delegate?.filterPresetView(self, didSelectPreset: preset)
        }
    }
}
