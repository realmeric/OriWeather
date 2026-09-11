import SwiftUI

/// Every number and colour of this droplet's own, in one place.
///
/// Everything else a view needs comes from Droppy's tokens
/// (`DroppyLiveActivityMetrics`, `DroppySpacing`, `DroppyRadius`,
/// `AdaptiveColors`), which follow Droppy when its styling moves. A number that
/// is not here and not a token is a smell, and `LookTests` says so (D3).
enum Look {
    // MARK: Tints

    /// The sun by day and the bolt: OriNotch's warm yellow.
    static let warm = Color(red: 1.0, green: 0.83, blue: 0.35)
    /// Rain: OriNotch's blue.
    static let rain = Color(red: 0.0, green: 0.48, blue: 1.0)

    // MARK: Figures

    /// An old reading is dimmed rather than hidden: a temperature from an hour
    /// ago with its age on it is worth more than an empty card.
    static let staleOpacity = 0.55

    /// The mark on the hover card, which the host has no token for.
    static let cardMark: CGFloat = 20
    /// The degrees on the hover card, beside a mark of the same height.
    static let cardFigure: CGFloat = 20

    // MARK: The shelf

    /// The widget's two widths. Both are required: the host refuses a
    /// descriptor that leaves either to a fallback.
    static let shelfSoloWidth: CGFloat = 340
    static let shelfPairedWidth: CGFloat = 170
    /// The widget's height, which its content has naturally.
    static let shelfHeight: CGFloat = 112
    /// The mark and the degrees on the shelf, where there is room for both to
    /// be read from across the desk.
    static let shelfMark: CGFloat = 28
    static let shelfFigure: CGFloat = 30
}
