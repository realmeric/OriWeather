import SwiftUI
import XCTest
@testable import OriWeather

final class MarksTests: XCTestCase {
    /// Every mark at sixteen points is something, and it stays in its rect.
    func testEveryMarkIsInsideItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 16, height: 16)
        for mark in WeatherCode.Mark.allCases {
            let path = Marks.path(mark, in: rect)
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
            let bounds = Marks.path(mark, in: rect).boundingRect
            XCTAssertTrue(rect.insetBy(dx: -0.01, dy: -0.01).contains(bounds),
                          "\(mark) leaks past its rect: \(bounds)")
        }
    }
}

final class LookTests: XCTestCase {
    /// `Look.swift` is the only file under `Sources/OriWeather/` with a literal
    /// colour or a literal point size in it. A number in a view is a number
    /// that stops matching the next time Droppy's styling moves (D3).
    func testOnlyLookCarriesNumbersOfItsOwn() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/OriWeather")
        let patterns = [
            #"Color\("#,
            #"size:\s*[0-9]"#,
            #"(width|height|minWidth|maxWidth|minHeight|maxHeight):\s*[0-9]"#,
            #"spacing:\s*[0-9]"#,
            #"\.padding\([^)]*[0-9]"#,
            #"\.opacity\(\s*0?\.[0-9]"#,
            #"cornerRadius:\s*[0-9]"#,
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
