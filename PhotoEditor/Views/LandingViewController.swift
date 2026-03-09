import UIKit

/// Landing screen shown at app launch. Displays a "Select Photo" button
/// that triggers the photo picker. On successful selection, navigates
/// to the PhotoEditorViewController.
class LandingViewController: UIViewController {

    // MARK: - Dependencies

    private let photoLoader = PhotoLoader()

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Photo Editor"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.setTitle("  选择照片", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        button.layer.cornerRadius = 12
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1.0)
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(titleLabel)
        view.addSubview(selectButton)
        view.addSubview(loadingIndicator)

        selectButton.addTarget(self, action: #selector(selectPhotoTapped), for: .touchUpInside)
        bindPhotoLoader()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let centerY = view.bounds.height * 0.4

        titleLabel.frame = CGRect(x: 20, y: centerY - 60, width: w - 40, height: 36)

        let btnWidth: CGFloat = 200
        let btnHeight: CGFloat = 50
        selectButton.frame = CGRect(
            x: (w - btnWidth) / 2,
            y: titleLabel.frame.maxY + 40,
            width: btnWidth,
            height: btnHeight
        )

        loadingIndicator.center = CGPoint(x: w / 2, y: selectButton.frame.maxY + 40)
    }

    // MARK: - Actions

    @objc private func selectPhotoTapped() {
        photoLoader.presentPicker(from: self)
    }

    // MARK: - Photo Loader Binding

    private func bindPhotoLoader() {
        photoLoader.onStateChanged = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .idle:
                self.loadingIndicator.stopAnimating()
                self.selectButton.isEnabled = true

            case .loading:
                self.loadingIndicator.startAnimating()
                self.selectButton.isEnabled = false

            case .loaded(let ciImage, let uiImage):
                self.loadingIndicator.stopAnimating()
                self.selectButton.isEnabled = true
                self.navigateToEditor(ciImage: ciImage, uiImage: uiImage)

            case .failed(let error):
                self.loadingIndicator.stopAnimating()
                self.selectButton.isEnabled = true
                self.showError(error)
            }
        }
    }

    // MARK: - Navigation

    private func navigateToEditor(ciImage: CIImage, uiImage: UIImage) {
        let viewModel = PhotoEditorViewModel()
        let editorVC = PhotoEditorViewController(viewModel: viewModel)
        editorVC.setFilterPresets(FilterPreset.builtins)
        // Set source image before push; editor will defer rendering until layout is ready
        editorVC.setSourceImage(uiImage)

        navigationController?.pushViewController(editorVC, animated: true)
    }

    // MARK: - Error Handling

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "加载失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.selectPhotoTapped()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
