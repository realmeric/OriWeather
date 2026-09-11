import AppKit
import DroppyKit
import Foundation

/// The one shortcut: the weather on the wings, or off them. The user rebinds
/// it in Droppy's Settings, Shortcuts; the default is only a suggestion the
/// host drops if something else already has it.
enum WingShortcut {
    static let id = "wings"
    static let title = "Show or hide the weather on the wings"

    /// Control-Option-Command-W, three modifiers so no app's own shortcut is
    /// in the way. The modifiers are AppKit's `NSEvent.ModifierFlags`,
    /// whatever the SDK's comment says: `DropletKeyboardShortcut.modifiers` is
    /// "Carbon-style", but Droppy 15.3 (the Playground) read Carbon's control
    /// and option bits as no modifiers at all and bound a bare W, which ate
    /// the key everywhere. The field is a `UInt`, as AppKit's flags are.
    static let suggestion = DropletKeyboardShortcut(
        keyCode: 13,
        modifiers: NSEvent.ModifierFlags([.control, .option, .command]).rawValue
    )

    /// The modifiers a binding asks for, in AppKit's terms.
    static func flags(_ shortcut: DropletKeyboardShortcut) -> NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: shortcut.modifiers).intersection([.control, .option, .shift, .command])
    }

    /// Whether a press is the shortcut and not a bare key the host bound by
    /// mistake: the binding has at least one modifier and every one of them
    /// is held. A binding without modifiers never flips anything, so a host
    /// that misreads the mask costs a key, not the user's pin.
    static func isGenuine(_ shortcut: DropletKeyboardShortcut?, held: NSEvent.ModifierFlags) -> Bool {
        guard let shortcut else { return false }
        let wanted = flags(shortcut)
        return !wanted.isEmpty && held.intersection([.control, .option, .shift, .command]).isSuperset(of: wanted)
    }

    /// "⌃⌥⌘W", in the order macOS writes modifiers.
    static func words(_ shortcut: DropletKeyboardShortcut) -> String {
        let held = flags(shortcut)
        let marks: [(NSEvent.ModifierFlags, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        let modifiers = marks.filter { held.contains($0.0) }.map(\.1).joined()
        return modifiers + (keys[shortcut.keyCode] ?? "key \(shortcut.keyCode)")
    }

    /// The ANSI keyboard's virtual key codes, letters, digits and the few
    /// others a shortcut is likely to use.
    private static let keys: [UInt16: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
        40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
        32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
        49: "Space", 36: "Return", 48: "Tab", 53: "Esc",
    ]
}
