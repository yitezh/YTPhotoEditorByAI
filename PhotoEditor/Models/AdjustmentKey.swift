import Foundation

/// Enum key for each adjustment parameter, with display metadata.
enum AdjustmentKey: String, CaseIterable, Codable {
    case exposure
    case contrast
    case highlights
    case shadows
    case saturation
    case vibrance
    case warmth
    case sharpness

    /// Localized display name for UI
    var displayName: String {
        switch self {
        case .exposure:   return "曝光"
        case .contrast:   return "对比度"
        case .highlights: return "高光"
        case .shadows:    return "阴影"
        case .saturation: return "饱和度"
        case .vibrance:   return "自然饱和度"
        case .warmth:     return "色温"
        case .sharpness:  return "锐度"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .exposure:   return "sun.max"
        case .contrast:   return "circle.lefthalf.filled"
        case .highlights: return "sun.max.fill"
        case .shadows:    return "moon.fill"
        case .saturation: return "drop.fill"
        case .vibrance:   return "paintpalette"
        case .warmth:     return "thermometer.medium"
        case .sharpness:  return "triangle"
        }
    }

    /// Which tool tab this key belongs to
    var tabGroup: ToolTab {
        switch self {
        case .exposure, .contrast, .highlights, .shadows:
            return .light
        case .saturation, .vibrance, .warmth:
            return .color
        case .sharpness:
            return .detail
        }
    }
}
