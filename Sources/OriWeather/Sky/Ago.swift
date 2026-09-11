import Foundation

/// How long ago, in the words the card uses in place of the condition when a
/// reading has stopped arriving.
enum Ago {
    static func words(_ then: Date, at now: Date) -> String {
        let seconds = now.timeIntervalSince(then)
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(Int(seconds / 60)) min ago"
        case ..<(24 * 3600): return "\(Int(seconds / 3600)) h ago"
        default: return "\(Int(seconds / (24 * 3600))) d ago"
        }
    }
}
