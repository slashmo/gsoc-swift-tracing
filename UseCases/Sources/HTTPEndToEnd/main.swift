import AsyncHTTPClient
import Baggage
import Foundation
import Instrumentation
import Logging
import NIO
import NIOHTTP1

import NIO

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let threadPool = NIOThreadPool(numberOfThreads: 6)
threadPool.start()

let orderServiceBootstrap = ServerBootstrap(group: eventLoopGroup)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(OrderServiceHandler(instrument: FakeTracer()))
        }
    }
    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)

let storageServiceBootstrap = ServerBootstrap(group: eventLoopGroup)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(StorageServiceHandler())
        }
    }
    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)

let logger = Logger(label: "FruitStore")

let orderServiceChannel = try orderServiceBootstrap.bind(host: "localhost", port: 8080).wait()
logger.info("Order service listening on ::1:8080")

let storageServiceChannel = try storageServiceBootstrap.bind(host: "localhost", port: 8081).wait()
logger.info("Storage service listening on ::1:8081")

let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
httpClient.get(url: "http://localhost:8080").whenComplete { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error)
    }
}

sleep(20)

try httpClient.syncShutdown()
try eventLoopGroup.syncShutdownGracefully()
try threadPool.syncShutdownGracefully()

// MARK: - Fake Tracer

private struct FakeTracer: InstrumentProtocol {
    enum TraceID: BaggageContextKey {
        typealias Value = String
    }

    static let headerName = "fake-trace-id"

    func inject(from baggage: BaggageContext, into headers: inout HTTPHeaders) {
        guard let traceID = baggage[TraceID.self] else { return }
        headers.replaceOrAdd(name: Self.headerName, value: traceID)
    }

    func extract(from headers: HTTPHeaders, into baggage: inout BaggageContext) {
        let traceID = headers.first(where: { $0.0 == Self.headerName })?.1 ?? UUID().uuidString
        baggage[TraceID.self] = traceID
    }
}
