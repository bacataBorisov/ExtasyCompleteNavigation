import SwiftUI

/// Port / starboard colours aligned with **`AnemometerView`** sectors and map laylines:
/// - **PORT**: red → **purple**
/// - **STBD**: green → **teal**
enum TacticalPalette {
    static let portEnd = Color.purple
    static let portStart = Color.red.opacity(0.88)
    static let starboardEnd = Color.teal
    static let starboardStart = Color.green.opacity(0.88)
    static let transition = Color.orange

    /// Matches **`AnemometerView`** sector fills (0.7 opacity stops).
    static let portSectorGradient: [Color] = [Color.red.opacity(0.7), portEnd.opacity(0.7)]
    static let starboardSectorGradient: [Color] = [Color.green.opacity(0.7), starboardEnd.opacity(0.7)]

    /// Monochrome label for a row titled `PORT` or `STBD` (VMC, etc.).
    static func tackLabelColor(for label: String) -> Color {
        let u = label.uppercased()
        if u == "PORT" { return portEnd }
        if u == "STBD" { return starboardEnd }
        return Color("display_font")
    }

    /// Colours for the continuous racing performance fill (low → high %).
    static var racingFillGradientColors: [Color] {
        [portEnd.opacity(0.92), portStart, transition, starboardStart, starboardEnd.opacity(0.96)]
    }

    /// Background gradient for `TackAlignmentBar` (port / low error → starboard / high).
    static var tackBarGradientStops: [Gradient.Stop] {
        [
            .init(color: portEnd.opacity(0.22), location: 0),
            .init(color: portStart.opacity(0.28), location: 0.18),
            .init(color: transition.opacity(0.32), location: 0.5),
            .init(color: starboardStart.opacity(0.38), location: 0.78),
            .init(color: starboardEnd.opacity(0.28), location: 1)
        ]
    }

    /// Segmented bar: port-side (low %) → starboard-side (high %).
    static func segmentColor(index: Int) -> Color {
        switch index {
        case 0...2: return portEnd.opacity(0.9)
        case 3...4: return portStart
        case 5...7: return transition.opacity(0.92)
        case 8...9: return starboardStart
        default: return starboardEnd.opacity(0.9)
        }
    }
}
