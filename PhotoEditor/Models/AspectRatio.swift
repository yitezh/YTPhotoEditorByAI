import CoreGraphics

/// Preset aspect ratios for the crop tool.
enum AspectRatio: CaseIterable {
    case free
    case square      // 1:1
    case fourThree   // 4:3
    case threeTwo    // 3:2
    case sixteenNine // 16:9

    /// Display name for UI
    var displayName: String {
        switch self {
        case .free:         return "自由"
        case .square:       return "1:1"
        case .fourThree:    return "4:3"
        case .threeTwo:     return "3:2"
        case .sixteenNine:  return "16:9"
        }
    }

    /// The width/height ratio value, nil for free mode
    var ratioValue: CGFloat? {
        switch self {
        case .free:         return nil
        case .square:       return 1.0
        case .fourThree:    return 4.0 / 3.0
        case .threeTwo:     return 3.0 / 2.0
        case .sixteenNine:  return 16.0 / 9.0
        }
    }
}
