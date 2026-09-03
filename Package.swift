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
        .package(url: "https://github.com/swift-compositions/swift-call.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-client.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-http-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-http.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-9110.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-optic.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Responder",
            dependencies: [
                .product(name: "Call", package: "swift-call"),
                .product(name: "Client", package: "swift-client"),
                .product(name: "HTTP Coder", package: "swift-http-coder"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Serializer", package: "swift-serializer"),
            ]
        ),
        .testTarget(
            name: "HTTP Responder Tests",
            dependencies: [
                "HTTP Responder",
                .product(name: "Call", package: "swift-call"),
                .product(name: "Client", package: "swift-client"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "HTTP Coder", package: "swift-http-coder"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Optic", package: "swift-optic"),
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
