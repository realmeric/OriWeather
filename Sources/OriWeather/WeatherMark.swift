import DroppyKit
import SwiftUI

/// The weather's mark in its tint. By night the sun is drawn in the secondary
/// white, as OriNotch draws it.
struct WeatherMark: View {
    let code: Int
    let isDay: Bool

    var body: some View {
        switch WeatherCode.mark(code) {
        case .sun:
            Marks.Sun().fill(isDay ? Look.warm : AdaptiveColors.notchSurfaceSecondaryText)
        case .cloud:
            Marks.Cloud().fill(AdaptiveColors.notchSurfaceSecondaryText)
        case .rain:
            Marks.Rain().fill(Look.rain)
        case .snow:
            Marks.Snow().fill(AdaptiveColors.notchSurfacePrimaryText)
        case .fog:
            Marks.Fog().fill(AdaptiveColors.notchSurfaceTertiaryText)
        case .storm:
            Marks.Bolt().fill(Look.warm)
        }
    }
}
