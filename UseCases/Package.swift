// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "use-cases",
    products: [
        .executable(name: "ManualContextPropagation", targets: ["ManualContextPropagation"]),
        .executable(name: "ManualAsyncHTTPClient", targets: ["ManualAsyncHTTPClient"]),
        .executable(name: "HTTPEndToEnd", targets: ["HTTPEndToEnd"]),
        .executable(name: "InstrumentsAppTracing", targets: ["InstrumentsAppTracing"]),
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.1.1"),
        .package(url: "https://github.com/slashmo/swift-nio.git", .branch("feature/baggage-context")),
        .package(
            url: "https://github.com/slashmo/gsoc-swift-baggage-context.git",
            from: "0.5.0"
        ),
    ],
    targets: [
        .target(name: "ManualContextPropagation", dependencies: [
            "Instrumentation",
            "Baggage",
        ]),
        .target(name: "ManualAsyncHTTPClient", dependencies: [
            "Instrumentation",
            "NIOInstrumentation",
            "AsyncHTTPClient",
            "NIO",
            "Baggage",
        ]),
        .target(name: "HTTPEndToEnd", dependencies: [
            "Tracing",
            "NIOInstrumentation",
            "AsyncHTTPClient",
            "NIO",
            "Baggage",
        ]),
        .target(name: "InstrumentsAppTracing", dependencies: [
            "Instrumentation",
            "Tracing",
        ]),
    ]
)
