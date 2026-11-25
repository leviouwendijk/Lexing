// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Lexing",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Lexing",
            targets: ["Lexing"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-lco/Primitives.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Position.git", branch: "master"),
        .package(url: "https://github.com/swift-langs/Grammar.git", branch: "master"),
        .package(url: "https://github.com/swift-lco/Errors.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Lexing",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Position", package: "Position"),
                .product(name: "Grammar", package: "Grammar"),
                .product(name: "Errors", package: "Errors"),
            ]
        ),
    ]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []

        settings.append(
            .treatAllWarnings(as: .error)
        )

        settings.append(
            .unsafeFlags(
                [
                    "-continue-building-after-errors"
                ]
            )
        )

        target.swiftSettings = settings

    case .plugin, .system, .binary:
        break

    @unknown default:
        break
    }
}
