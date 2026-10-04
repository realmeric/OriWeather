// swift-tools-version: 6.2
import PackageDescription

// The droplet's tests, as a package beside it: the Store's folder holds the
// droplet's package and nothing else, so the test target cannot live there.
// `swift test --package-path Tests` from the repository's root runs them.
let package = Package(
    name: "OriWeatherTests",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(name: "OriWeather", path: ".."),
        .package(url: "https://gitlab.com/droppyformac1/droppykit.git", from: "1.9.0")
    ],
    targets: [
        .testTarget(
            name: "OriWeatherTests",
            dependencies: [
                .product(name: "OriWeather", package: "OriWeather"),
                .product(name: "DroppyKitHarness", package: "droppykit")
            ],
            path: "OriWeatherTests"
        )
    ]
)
