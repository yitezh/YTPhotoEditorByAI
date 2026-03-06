import Foundation

// MARK: - Built-in Filter Presets

extension FilterPreset {

    /// All built-in filter presets (10 styles).
    static let builtins: [FilterPreset] = [
        vivid, warm, cool, blackAndWhite, vintage,
        soft, dramatic, sunset, forest, urban
    ]

    // MARK: - 鲜艳 (Vivid)
    static let vivid = FilterPreset(
        id: "vivid",
        name: "鲜艳",
        icon: "sparkles",
        parameters: EditParameters(
            exposure: 10,
            contrast: 20,
            saturation: 40,
            vibrance: 30,
            sharpness: 10
        )
    )

    // MARK: - 暖色 (Warm)
    static let warm = FilterPreset(
        id: "warm",
        name: "暖色",
        icon: "sun.max.fill",
        parameters: EditParameters(
            exposure: 8,
            contrast: 10,
            shadows: 15,
            saturation: 15,
            vibrance: 10,
            warmth: 45
        )
    )

    // MARK: - 冷色 (Cool)
    static let cool = FilterPreset(
        id: "cool",
        name: "冷色",
        icon: "snowflake",
        parameters: EditParameters(
            contrast: 10,
            highlights: 10,
            saturation: -10,
            vibrance: 15,
            warmth: -40,
            sharpness: 5
        )
    )

    // MARK: - 黑白 (Black & White)
    static let blackAndWhite = FilterPreset(
        id: "blackAndWhite",
        name: "黑白",
        icon: "circle.lefthalf.filled",
        parameters: EditParameters(
            contrast: 25,
            highlights: 10,
            shadows: -10,
            saturation: -100,
            sharpness: 15
        )
    )

    // MARK: - 复古 (Vintage)
    static let vintage = FilterPreset(
        id: "vintage",
        name: "复古",
        icon: "camera.filters",
        parameters: EditParameters(
            exposure: 5,
            contrast: -15,
            highlights: -20,
            shadows: 20,
            saturation: -25,
            vibrance: -10,
            warmth: 25,
            sharpness: -10
        )
    )

    // MARK: - 柔和 (Soft)
    static let soft = FilterPreset(
        id: "soft",
        name: "柔和",
        icon: "cloud.fill",
        parameters: EditParameters(
            exposure: 10,
            contrast: -20,
            highlights: -15,
            shadows: 25,
            saturation: -10,
            vibrance: 10,
            warmth: 10,
            sharpness: -15
        )
    )

    // MARK: - 戏剧 (Dramatic)
    static let dramatic = FilterPreset(
        id: "dramatic",
        name: "戏剧",
        icon: "theatermasks.fill",
        parameters: EditParameters(
            exposure: -5,
            contrast: 40,
            highlights: -25,
            shadows: -30,
            saturation: -15,
            vibrance: 20,
            sharpness: 20
        )
    )

    // MARK: - 日落 (Sunset)
    static let sunset = FilterPreset(
        id: "sunset",
        name: "日落",
        icon: "sunset.fill",
        parameters: EditParameters(
            exposure: 8,
            contrast: 15,
            highlights: -10,
            shadows: 15,
            saturation: 25,
            vibrance: 20,
            warmth: 55
        )
    )

    // MARK: - 森林 (Forest)
    static let forest = FilterPreset(
        id: "forest",
        name: "森林",
        icon: "leaf.fill",
        parameters: EditParameters(
            exposure: -5,
            contrast: 15,
            highlights: -10,
            shadows: 10,
            saturation: 20,
            vibrance: 30,
            warmth: -15,
            sharpness: 10
        )
    )

    // MARK: - 城市 (Urban)
    static let urban = FilterPreset(
        id: "urban",
        name: "城市",
        icon: "building.2.fill",
        parameters: EditParameters(
            contrast: 30,
            highlights: 15,
            shadows: -20,
            saturation: -20,
            vibrance: 10,
            warmth: -10,
            sharpness: 20
        )
    )
}
