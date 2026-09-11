import DroppyKit
import SwiftUI
import XCTest
@testable import OriWeather

final class MarksTests: XCTestCase {
    /// Every mark at sixteen points is something, and it stays in its rect.
    func testEveryMarkIsInsideItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 16, height: 16)
        for mark in WeatherCode.Mark.allCases {
            let path = Marks.path(mark, in: rect).union(Marks.path(mark, in: rect, isDay: false))
            XCTAssertFalse(path.isEmpty, "\(mark) drew nothing")
            let bounds = path.boundingRect
            XCTAssertGreaterThan(bounds.width * bounds.height, 16, "\(mark) is a dot")
            XCTAssertTrue(rect.insetBy(dx: -0.01, dy: -0.01).contains(bounds),
                          "\(mark) leaks past its rect: \(bounds)")
        }
    }

    /// The same at the wing's 13 pt, which is where a leak is clipped.
    func testEveryMarkIsInsideItsRectAtTheWingsSize() {
        let rect = CGRect(x: 0, y: 0, width: 13, height: 13)
        for mark in WeatherCode.Mark.allCases {
            let bounds = Marks.path(mark, in: rect).union(Marks.path(mark, in: rect, isDay: false)).boundingRect
            XCTAssertTrue(rect.insetBy(dx: -0.01, dy: -0.01).contains(bounds),
                          "\(mark) leaks past its rect: \(bounds)")
        }
    }
}

final class LookTests: XCTestCase {
    /// `Look.swift` is the only file under `Sources/OriWeather/` with a literal
    /// colour or a literal point size in it. A number in a view is a number
    /// that stops matching the next time Droppy's styling moves (D3). Zero is
    /// nobody's number.
    func testOnlyLookCarriesNumbersOfItsOwn() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OriWeather")
        let patterns = [
            #"Color\("#,
            #"size:\s*(?!0\b)[0-9]"#,
            #"(width|height|minWidth|maxWidth|minHeight|maxHeight):\s*(?!0\b)[0-9]"#,
            #"spacing:\s*(?!0\b)[0-9]"#,
            #"\.padding\([^)]*[0-9]"#,
            #"\.opacity\(\s*0?\.[0-9]"#,
            #"cornerRadius:\s*(?!0\b)[0-9]"#,
        ].map { try! NSRegularExpression(pattern: $0) }

        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" && $0.lastPathComponent != "Look.swift" }
        XCTAssertFalse(files.isEmpty)
        var offenders: [String] = []
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            for (number, line) in lines.enumerated() {
                let code = line.components(separatedBy: "//").first ?? line
                let range = NSRange(code.startIndex..., in: code)
                if patterns.contains(where: { $0.firstMatch(in: code, range: range) != nil }) {
                    offenders.append("\(file.lastPathComponent):\(number + 1): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }
        }
        XCTAssertEqual(offenders, [], "a number of this droplet's own outside Look.swift")
    }
}

final class InkTests: XCTestCase {
    /// On the shelf the host's Widget Text colour wins, then the adaptive
    /// text when the shelf is transparent, then the notch's own ladder.
    func testTheShelfWritesInWhateverTheHostAsksFor() {
        XCTAssertEqual(WeatherInk.shelf(textColor: .red, adaptive: true).primary, .red)
        XCTAssertEqual(WeatherInk.shelf(textColor: nil, adaptive: true).primary,
                       AdaptiveColors.primaryTextAuto)
        XCTAssertEqual(WeatherInk.shelf(textColor: nil, adaptive: false).primary,
                       AdaptiveColors.notchSurfacePrimaryText)
    }
}

/// Every mark the droplet draws, in its tint, on the notch's black: large, and
/// at the wing's own size under it, with the WMO codes and words each stands
/// for. Written to shots/extra/marks.png for eyes.
@MainActor
final class MarksSheetTests: XCTestCase {
    private struct Entry: Identifiable {
        let id: String
        let code: Int
        let isDay: Bool
        let words: String
    }

    private let entries = [
        Entry(id: "sun", code: 0, isDay: true, words: "Clear, mainly clear\n0, 1"),
        Entry(id: "night", code: 0, isDay: false, words: "Clear at night\n0, 1"),
        Entry(id: "partly", code: 2, isDay: true, words: "Partly cloudy\n2"),
        Entry(id: "partly-night", code: 2, isDay: false, words: "Partly cloudy at night\n2"),
        Entry(id: "cloud", code: 3, isDay: true, words: "Overcast\n3"),
        Entry(id: "fog", code: 45, isDay: true, words: "Fog\n45, 48"),
        Entry(id: "rain", code: 61, isDay: true, words: "Drizzle, rain, showers\n51–67, 80–82"),
        Entry(id: "snow", code: 71, isDay: true, words: "Snow, snow showers\n71–77, 85, 86"),
        Entry(id: "storm", code: 95, isDay: true, words: "Thunderstorm, hail\n95–99"),
    ]

    func testTheMarksSheet() throws {
        let sheet = HStack(alignment: .top, spacing: 28) {
            ForEach(entries) { entry in
                VStack(spacing: 14) {
                    WeatherMark(code: entry.code, isDay: entry.isDay)
                        .frame(width: 56, height: 56)
                    WeatherMark(code: entry.code, isDay: entry.isDay)
                        .frame(width: DroppyLiveActivityMetrics.iconSize, height: DroppyLiveActivityMetrics.iconSize)
                    Text(entry.words)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AdaptiveColors.notchSurfaceSecondaryText)
                        .frame(width: 110)
                }
            }
        }
        .padding(32)
        .background(Color.black)
        try Shots.write(sheet, name: "marks")
    }
}
