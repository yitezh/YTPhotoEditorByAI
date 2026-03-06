import Foundation

/// Supported export formats for saving edited photos.
enum ExportFormat {
    case jpeg
    case png

    /// File extension string
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png:  return "png"
        }
    }

    /// UTType identifier string
    var utType: String {
        switch self {
        case .jpeg: return "public.jpeg"
        case .png:  return "public.png"
        }
    }
}
