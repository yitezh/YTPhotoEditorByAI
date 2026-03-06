import Foundation

/// A named filter preset containing a predefined set of adjustment parameters.
struct FilterPreset: Identifiable {
    let id: String
    let name: String
    let icon: String           // SF Symbol name
    let parameters: EditParameters
}
