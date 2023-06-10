// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "PiholeNetworking",
	platforms: [.iOS("16"),
				.macOS("13"),
				.watchOS("9"),
				.tvOS("16")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PiholeNetworking",
            targets: ["PiholeNetworking"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PiholeNetworking",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(
                    ["-Xfrontend", "-strict-concurrency=complete"]
                )
            ]
        ),
        .testTarget(
            name: "PiholeNetworkingTests",
            dependencies: ["PiholeNetworking"]),
    ]
)
