import AppKit
import SwiftUI

/// The system search field, the one Droppy's own settings search with: the
/// magnifier, the prompt and the clear button. DroppyKit has none yet, so
/// the droplet wraps `NSSearchField` itself.
struct CitySearchField: NSViewRepresentable {
    @Binding var text: String
    let prompt: String

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = prompt
        field.stringValue = text
        field.sendsSearchStringImmediately = true
        field.delegate = context.coordinator
        // The clear button changes the text without a keystroke, and reaches
        // the binding only through the action.
        field.target = context.coordinator
        field.action = #selector(Coordinator.searched(_:))
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.text = $text
        if field.stringValue != text { field.stringValue = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) { self.text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text.wrappedValue = field.stringValue
        }

        @objc func searched(_ field: NSSearchField) {
            if text.wrappedValue != field.stringValue { text.wrappedValue = field.stringValue }
        }
    }
}
