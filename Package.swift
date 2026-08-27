// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-http-responder",
    platforms: [
        .macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27),
    ],
    products: [
        .library(name: "HTTP Responder", targets: ["HTTP Responder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-client.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-http-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-http-router.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-http.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-coder-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-either-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Responder",
            dependencies: [
                .product(name: "Client", package: "swift-client"),
                .product(name: "Coder Primitive", package: "swift-coder-primitives"),
                .product(name: "HTTP Coder", package: "swift-http-coder"),
                .product(name: "HTTP Router", package: "swift-http-router"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "Either Primitives", package: "swift-either-primitives"),
            ]
        ),
        .testTarget(
            name: "HTTP Responder Tests",
            dependencies: [
                "HTTP Responder",
                .product(name: "Coder Primitive", package: "swift-coder-primitives"),
                .product(name: "HTTP", package: "swift-http"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(), .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"), .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"), .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
