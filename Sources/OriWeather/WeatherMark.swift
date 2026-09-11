import DroppyKit
import SwiftUI

/// The three whites everything is written in: Droppy's notch ladder on the
/// wing and the card, and on the shelf whatever the host asks for.
struct WeatherInk {
    let primary: Color
    let secondary: Color
    let tertiary: Color

    /// The notch's own ladder, for surfaces that are always dark.
    static let notch = WeatherInk(primary: AdaptiveColors.notchSurfacePrimaryText,
                                  secondary: AdaptiveColors.notchSurfaceSecondaryText,
                                  tertiary: AdaptiveColors.notchSurfaceTertiaryText)

    /// The shelf's: the user's Widget Text colour when the host hands one
    /// down, the system's adaptive text when the shelf is drawn over a
    /// transparent material, and the notch ladder otherwise.
    static func shelf(textColor: Color?, adaptive: Bool) -> WeatherInk {
        if let textColor {
            return WeatherInk(primary: textColor,
                              secondary: textColor.opacity(DroppyOpacity.primary),
                              tertiary: textColor.opacity(DroppyOpacity.secondary))
        }
        if adaptive {
            return WeatherInk(primary: AdaptiveColors.primaryTextAuto,
                              secondary: AdaptiveColors.secondaryTextAuto,
                              tertiary: AdaptiveColors.secondaryTextAuto.opacity(DroppyOpacity.primary))
        }
        return .notch
    }
}

private struct WeatherInkKey: EnvironmentKey {
    static let defaultValue = WeatherInk.notch
}

extension EnvironmentValues {
    var weatherInk: WeatherInk {
        get { self[WeatherInkKey.self] }
        set { self[WeatherInkKey.self] = newValue }
    }
}

/// The weather's mark in its tint. By night the sun is drawn in the secondary
/// white, as OriNotch draws it; the whites are whichever ink the surface uses.
struct WeatherMark: View {
    let code: Int
    let isDay: Bool
    @Environment(\.weatherInk) private var ink

    var body: some View {
        switch WeatherCode.mark(code) {
        case .sun:
            Marks.Sun().fill(isDay ? Look.warm : ink.secondary)
        case .cloud:
            Marks.Cloud().fill(ink.secondary)
        case .rain:
            Marks.Rain().fill(Look.rain)
        case .snow:
            Marks.Snow().fill(ink.primary)
        case .fog:
            Marks.Fog().fill(ink.tertiary)
        case .storm:
            Marks.Bolt().fill(Look.warm)
        }
    }
}
