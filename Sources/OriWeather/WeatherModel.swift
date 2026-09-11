import Combine
import Foundation

/// The weather the wing and the card show.
///
/// OriNotch's model without its location half: a fetcher, a city, a clock.
/// Off costs nothing: a model that was built and never started has no timer and
/// has asked nobody anything. On, one reading per interval, and the last one
/// stays when the network does not.
///
/// It knows nothing about seats or shelves. The droplet decides when it runs,
/// and says why when it asks for a refresh.
@MainActor
final class WeatherModel: ObservableObject {
    /// Why somebody asked for a reading. The clock and a new city always read;
    /// a seat or a shelf reads only if what is on screen is older than the
    /// interval, so ten display wakes in a minute are zero fetches (D6).
    enum Reason: String {
        case clock
        case city
        case seat
        case shelf
        /// Activation, which reads once so there is something to publish.
        case launch
    }

    @Published private(set) var reading: WeatherReading?
    /// The last read failed, so what is on screen is older than it looks.
    @Published private(set) var isStale = false
    /// The moment of the last attempt, which is what an old reading's age is
    /// measured against. Moves on every attempt, successful or not, and never
    /// between them: the age only has to be right when it is drawn, and a clock
    /// that ticks for a figure that changes twice an hour is a clock that does
    /// not need to exist.
    @Published private(set) var now: Date

    /// Where the weather is read. A different city is a different sky, so the
    /// old reading goes and a new one is asked for at once if the clock runs.
    var city: City? {
        didSet {
            guard city != oldValue else { return }
            reading = nil
            isStale = false
            lastAttempt = nil
            asking = nil
            if isRunning {
                reschedule()
                refresh(because: .city)
            }
        }
    }

    /// Seconds between readings: the preference `intervalMinutes` times 60.
    var every: TimeInterval {
        didSet {
            guard every != oldValue, isRunning else { return }
            reschedule()
        }
    }

    /// Lines worth a reader's time: the clock starting and stopping, a read
    /// that failed. The droplet points this at the host's log.
    var log: ((String) -> Void)?

    var isRunning: Bool { tick != nil }

    private let fetcher: any WeatherFetching
    private let clock: () -> Date
    private var tick: Timer?
    private var lastAttempt: Date?
    /// The attempt in flight, if any. One at a time: a request already out
    /// absorbs any that arrive behind it.
    private var asking: UUID?

    init(fetcher: any WeatherFetching,
         city: City? = nil,
         every: TimeInterval = 30 * 60,
         clock: @escaping () -> Date = Date.init) {
        self.fetcher = fetcher
        self.city = city
        self.every = every
        self.clock = clock
        self.now = clock()
    }

    deinit {
        MainActor.assumeIsolated { tick?.invalidate() }
    }

    /// Registers the clock and reads at once, unless the reading on screen is
    /// younger than the interval.
    func start(because reason: Reason = .seat) {
        guard tick == nil else { return }
        reschedule()
        log?("clock started (\(reason.rawValue)), every \(Int(every / 60)) min")
        refresh(because: reason)
    }

    func stop() {
        guard let tick else { return }
        tick.invalidate()
        self.tick = nil
        log?("clock stopped")
    }

    /// One attempt, or nothing. `when` is injectable so a test can say what
    /// time it is without waiting for it.
    func refresh(at when: Date? = nil, because reason: Reason = .seat) {
        let when = when ?? clock()
        guard let city, asking == nil else { return }
        switch reason {
        case .clock, .city:
            break
        case .seat, .shelf, .launch:
            if let lastAttempt, when.timeIntervalSince(lastAttempt) < every { return }
        }
        now = when
        lastAttempt = when
        let token = UUID()
        asking = token
        let fetcher = self.fetcher
        let place = city.place
        Task { [weak self] in
            let result: Result<WeatherReading, Error>
            do {
                result = .success(try await fetcher.read(at: place))
            } catch {
                result = .failure(error)
            }
            self?.settle(result, token: token)
        }
    }

    private func settle(_ result: Result<WeatherReading, Error>, token: UUID) {
        // An answer to a question nobody is asking any more (the city changed
        // while it was out) belongs to nobody.
        guard token == asking else { return }
        asking = nil
        switch result {
        case .success(let reading):
            self.reading = reading
            isStale = false
        case .failure(let error):
            // The last reading stays: a temperature from an hour ago with its
            // age on it is worth more than an empty card. Nothing ever read is
            // nothing, not stale.
            isStale = reading != nil
            log?("the weather did not come: \(error.localizedDescription)")
        }
    }

    /// The next tick lands when the reading on screen turns as old as the
    /// interval, not an interval after whoever started the clock, so regaining
    /// a seat does not push the next reading further away.
    private func reschedule() {
        tick?.invalidate()
        let due = lastAttempt.map { $0.addingTimeInterval(every).timeIntervalSince(clock()) } ?? every
        let timer = Timer(fire: Date().addingTimeInterval(max(due, 1)), interval: every,
                          repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh(because: .clock) }
        }
        timer.tolerance = min(60, every / 10)
        RunLoop.main.add(timer, forMode: .common)
        tick = timer
    }
}
