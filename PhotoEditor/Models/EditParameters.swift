import Foundation
import CoreGraphics

/// Core data structure holding all editing parameters.
/// Conforms to Codable for JSON serialization and Equatable for comparison.
struct EditParameters: Codable, Equatable {
    var exposure: Float = 0       // -100 ~ +100
    var contrast: Float = 0       // -100 ~ +100
    var highlights: Float = 0     // -100 ~ +100
    var shadows: Float = 0        // -100 ~ +100
    var saturation: Float = 0     // -100 ~ +100
    var vibrance: Float = 0       // -100 ~ +100
    var warmth: Float = 0         // -100 ~ +100
    var sharpness: Float = 0      // -100 ~ +100
    var texture: Float = 0        // -100 ~ +100
    var clarity: Float = 0        // -100 ~ +100
    var dehaze: Float = 0         // -100 ~ +100

    var cropRect: CodableCGRect?  // nil means no crop applied
    var rotationCount: Int = 0    // 0-3, number of 90° clockwise rotations

    static let `default` = EditParameters()

    /// Whether all adjustment parameters are at their default values
    var isDefault: Bool {
        return self == EditParameters.default
    }
}

/// Wrapper to make CGRect Codable
struct CodableCGRect: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}
