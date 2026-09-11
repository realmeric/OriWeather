import SwiftUI

/// Every number and colour of this droplet's own, in one place.
///
/// Everything else a view needs comes from Droppy's tokens
/// (`DroppyLiveActivityMetrics`, `DroppySpacing`, `DroppyRadius`,
/// `AdaptiveColors`), which follow Droppy when its styling moves. A number that
/// is not here and not a token is a smell, and `LookTests` says so (D3).
enum Look {
    // MARK: Tints

    /// The sun by day and the bolt: a warm yellow.
    static let warm = Color(red: 1.0, green: 0.83, blue: 0.35)
    /// Rain: a clear blue.
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
    /// The solo width is the floor Droppy 15.3 hands a solo card as an island
    /// (352 on a notch), so the widget is laid out at the width it gets.
    static let shelfSoloWidth: CGFloat = 370
    static let shelfPairedWidth: CGFloat = 170
    /// The widget's height: the header, the reading and the hours ahead,
    /// and nothing more.
    static let shelfHeight: CGFloat = 152
    /// Alone on the shelf: the mark and the degrees large enough to read
    /// from across the desk.
    static let shelfMark: CGFloat = 34
    static let shelfFigure: CGFloat = 34
    /// Beside another widget, a size down.
    static let pairedMark: CGFloat = 28
    static let pairedFigure: CGFloat = 30
    /// The condition and the city beside the figure.
    static let shelfLabel: CGFloat = 13
    /// The hours ahead: the hour, its mark, its degrees.
    static let hourLabel: CGFloat = 11
    static let hourMark: CGFloat = 16
}
