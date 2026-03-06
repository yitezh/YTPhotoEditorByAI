import UIKit

/// Delegate protocol for tab selection changes.
protocol ToolTabBarViewDelegate: AnyObject {
    func toolTabBarView(_ tabBar: ToolTabBarView, didSelectTab tab: ToolTab)
}

/// Horizontal tab bar displaying tool categories (光效、颜色、效果、细节).
/// Uses SF Symbols icons with a highlighted selection state.
class ToolTabBarView: UIView {

    // MARK: - Properties

    weak var delegate: ToolTabBarViewDelegate?

    private let tabs = ToolTab.allCases
    private var buttons: [UIButton] = []
    private(set) var selectedTab: ToolTab = .light

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .center
        sv.spacing = 0
        return sv
    }()

    private let selectionIndicator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0) // #E0E0E0
        v.layer.cornerRadius = 1.5
        return v
    }()

    // MARK: - Colors

    private let normalColor = UIColor(white: 0.5, alpha: 1.0)
    private let selectedColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)

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

        addSubview(stackView)
        addSubview(selectionIndicator)

        for (index, tab) in tabs.enumerated() {
            let button = makeTabButton(tab: tab, tag: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        // Select first tab by default
        updateSelection(animated: false)
    }

    private func makeTabButton(tab: ToolTab, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: tab.iconName, withConfiguration: config)

        button.setImage(image, for: .normal)
        button.setTitle(" \(tab.displayName)", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.tintColor = normalColor
        button.setTitleColor(normalColor, for: .normal)
        button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        return button
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
        updateIndicatorPosition(animated: false)
    }

    // MARK: - Actions

    @objc private func tabTapped(_ sender: UIButton) {
        let tab = tabs[sender.tag]
        guard tab != selectedTab else { return }
        selectedTab = tab
        updateSelection(animated: true)
        delegate?.toolTabBarView(self, didSelectTab: tab)
    }

    /// Programmatically select a tab.
    func selectTab(_ tab: ToolTab, animated: Bool = false) {
        selectedTab = tab
        updateSelection(animated: animated)
    }

    // MARK: - Selection Update

    private func updateSelection(animated: Bool) {
        for (index, button) in buttons.enumerated() {
            let isSelected = tabs[index] == selectedTab
            button.tintColor = isSelected ? selectedColor : normalColor
            button.setTitleColor(isSelected ? selectedColor : normalColor, for: .normal)
        }
        updateIndicatorPosition(animated: animated)
    }

    private func updateIndicatorPosition(animated: Bool) {
        guard let index = tabs.firstIndex(of: selectedTab),
              index < buttons.count else { return }

        let button = buttons[index]
        let buttonFrame = button.convert(button.bounds, to: self)
        let indicatorWidth: CGFloat = buttonFrame.width * 0.5
        let indicatorFrame = CGRect(
            x: buttonFrame.midX - indicatorWidth / 2,
            y: bounds.height - 3,
            width: indicatorWidth,
            height: 3
        )

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.selectionIndicator.frame = indicatorFrame
            }
        } else {
            selectionIndicator.frame = indicatorFrame
        }
    }
}
