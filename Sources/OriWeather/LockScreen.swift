import Combine
import DroppyKit
import Foundation

// MARK: - Lock screen

extension OriWeatherDroplet: LockScreenStatusProviding {
    /// The weather in Droppy's status widgets row while the Mac is locked.
    /// The host subscribes once and draws whatever was sent last, so this is a
    /// publisher the glance feeds, never a getter.
    public var lockScreenStatus: AnyPublisher<LockScreenStatusEntry?, Never> {
        lockScreenSubject.eraseToAnyPublisher()
    }
}

/// The row's entry, from a glance.
///
/// The host draws the row itself from a symbol name and text, so this is the
/// one surface where the weather is an SF Symbol and not the droplet's own
/// mark; the symbols are the ones closest to each mark. The user picks the
/// row's style in Droppy, not the droplet, so both are filled: the horizontal
/// strip is the symbol, the degrees and the condition; the rounded one is the
/// degrees inside the ring and a word or two under it, because a long
/// condition under a ring is cut short.
enum LockScreenRow {
    static let id = "ori-weather"

    static func entry(_ glance: Glance) -> LockScreenStatusEntry {
        let reading = glance.reading
        return LockScreenStatusEntry(
            id: id,
            systemImage: symbol(WeatherCode.mark(reading.code), isDay: reading.isDay),
            text: glance.degrees,
            detail: glance.detail,
            roundedCenterText: glance.degrees,
            roundedBottomText: glance.isStale ? glance.detail : short(reading.code),
            progress: nil,
            // A temperature changes twice an hour; the lock surface renders on
            // battery, and there is nothing to say 59 times out of 60.
            ticksEverySecond: false
        )
    }

    /// The SF Symbol nearest each mark, by night the moon's.
    static func symbol(_ mark: WeatherCode.Mark, isDay: Bool) -> String {
        switch mark {
        case .sun: isDay ? "sun.max.fill" : "moon.fill"
        case .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloud: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .storm: "cloud.bolt.fill"
        }
    }

    /// The condition in a word or two, for the caption under the ring.
    static func short(_ code: Int) -> String {
        switch code {
        case 0, 1: "Clear"
        case 2: "Some sun"
        case 3: "Cloudy"
        case 45, 48: "Fog"
        case 51, 53, 55, 56, 57: "Drizzle"
        case 61, 63, 65, 66, 67: "Rain"
        case 71, 73, 75, 77: "Snow"
        case 80, 81, 82: "Showers"
        case 85, 86: "Snow"
        case 95: "Storm"
        case 96, 99: "Hail"
        default: WeatherCode.words(code)
        }
    }
}

/// Whether the Mac is locked with its screen awake, which is when the status
/// widgets row can be seen and the weather in it has to be true.
///
/// macOS says so in two places: the distributed `com.apple.screenIsLocked`
/// and `…Unlocked` notifications for the lock, and the workspace's screens
/// sleeping and waking for the display.
struct LockState: Equatable {
    var isLocked = false
    var isDisplayAwake = true

    var isSeen: Bool { isLocked && isDisplayAwake }

    static let locked = Notification.Name("com.apple.screenIsLocked")
    static let unlocked = Notification.Name("com.apple.screenIsUnlocked")
}
