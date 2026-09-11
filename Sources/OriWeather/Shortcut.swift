import DroppyKit
import Foundation

/// The one shortcut: the weather on the wings, or off them. The user rebinds
/// it in Droppy's Settings, Shortcuts; the default is only a suggestion the
/// host drops if something else already has it.
enum WingShortcut {
    static let id = "wings"
    static let title = "Show or hide the weather on the wings"
    /// Control-Option-W, as a Carbon mask: W is virtual key 13, control is
    /// 1 << 12 and option 1 << 11.
    static let suggestion = DropletKeyboardShortcut(keyCode: 13, modifiers: 1 << 12 | 1 << 11)

    /// "⌃⌥W", in the order macOS writes modifiers.
    static func words(_ shortcut: DropletKeyboardShortcut) -> String {
        let marks: [(UInt, String)] = [(1 << 12, "⌃"), (1 << 11, "⌥"), (1 << 9, "⇧"), (1 << 8, "⌘")]
        let modifiers = marks.filter { shortcut.modifiers & $0.0 != 0 }.map(\.1).joined()
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
