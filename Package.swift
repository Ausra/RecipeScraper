// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RecipeScraper",
    platforms: [.macOS(.v10_15), .iOS(.v17), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RecipeScraper",
            targets: ["RecipeScraper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/Ausra/JSONLDDecoder.git", from: "1.0.8")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RecipeScraper",
            dependencies: [
                "SwiftSoup",
                "JSONLDDecoder"
            ]
        ),
        .testTarget(
            name: "RecipeScraperTests",
            dependencies: ["RecipeScraper"]
        )
    ]
)
