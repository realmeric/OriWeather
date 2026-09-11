import Combine
import DroppyKit
import Foundation

/// The city row's search: what has been typed, and what the geocoder found.
///
/// The geocoder is asked once the typing has paused for 400 ms, so a name
/// typed in one go is one request, not one per keystroke. Choosing a match
/// asks it nothing: the match already carries its coordinate.
@MainActor
final class CitySearch: ObservableObject {
    /// How long the typing has to pause before the geocoder is asked.
    static let pause: Duration = .milliseconds(400)

    @Published var query = "" {
        didSet { if query != oldValue { schedule() } }
    }
    @Published private(set) var matches: [City] = []
    @Published private(set) var isSearching = false

    private let geocoder: any Geocoding
    private let log: (String) -> Void
    private var pending: Task<Void, Never>?

    init(geocoder: any Geocoding, log: @escaping (String) -> Void = { _ in }) {
        self.geocoder = geocoder
        self.log = log
    }

    /// Clears the field and forgets the matches, which is what choosing one
    /// does.
    func reset() {
        query = ""
        pending?.cancel()
        pending = nil
        matches = []
        isSearching = false
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }

    private func schedule() {
        pending?.cancel()
        let name = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2 else {
            matches = []
            isSearching = false
            return
        }
        isSearching = true
        let geocoder = self.geocoder
        pending = Task { [weak self] in
            try? await Task.sleep(for: Self.pause)
            guard !Task.isCancelled else { return }
            self?.log("asked the geocoder for \"\(name)\"")
            let found = (try? await geocoder.cities(named: name)) ?? []
            guard !Task.isCancelled, let self else { return }
            self.matches = found
            self.isSearching = false
        }
    }
}

/// A geocoder for the harness and the demo sky: whatever is typed, the demo
/// city, and never a request.
struct DemoGeocoder: Geocoding {
    func cities(named name: String) async throws -> [City] { [Demo.city] }
}

/// Where the demo sky says the Mac is: the demo city, and never a request.
struct DemoLocator: Locating {
    func locate() async throws -> City { Demo.city }
}
