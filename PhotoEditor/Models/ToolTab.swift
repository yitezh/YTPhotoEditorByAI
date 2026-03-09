import Foundation

/// Tool tab categories for organizing adjustment controls.
enum ToolTab: String, CaseIterable {
    case light    // 光效: exposure, contrast, highlights, shadows
    case color    // 颜色: saturation, vibrance, warmth
    case effects  // 效果: reserved for future extensions
    case detail   // 细节: sharpness
    case crop     // 裁剪: crop and rotate

    /// Display name for the tab
    var displayName: String {
        switch self {
        case .light:   return "光效"
        case .color:   return "颜色"
        case .effects: return "效果"
        case .detail:  return "细节"
        case .crop:    return "裁剪"
        }
    }

    /// SF Symbol icon name for the tab
    var iconName: String {
        switch self {
        case .light:   return "sun.max"
        case .color:   return "paintpalette"
        case .effects: return "sparkles"
        case .detail:  return "triangle"
        case .crop:    return "crop"
        }
    }

    /// Returns the AdjustmentKeys that belong to this tab
    var adjustmentKeys: [AdjustmentKey] {
        AdjustmentKey.allCases.filter { $0.tabGroup == self }
    }
}
