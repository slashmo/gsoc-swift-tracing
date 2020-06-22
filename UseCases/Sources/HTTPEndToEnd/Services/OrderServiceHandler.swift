import AsyncHTTPClient
import Baggage
import BaggageLogging
import Instrumentation
import Logging
import NIO
import NIOHTTP1

final class OrderServiceHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let instrument: Instrument<HTTPHeaders, HTTPHeaders>

    init<I>(instrument: I)
        where I: InstrumentProtocol,
        I.InjectInto == HTTPHeaders,
        I.ExtractFrom == HTTPHeaders {
        self.instrument = Instrument(instrument)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .head(let requestHead) = self.unwrapInboundIn(data) else { return }

        var baggage = BaggageContext()
        let logger = Logger(label: "OrderService")
        baggage[BaggageContext.BaseLoggerKey.self] = logger

        self.instrument.extract(from: requestHead.headers, into: &baggage)

        baggage.logger.info("Handling order service request")

        let client = InstrumentedHTTPClient(
            instrument: self.instrument,
            eventLoopGroupProvider: .shared(context.eventLoop)
        )
        let request = try! HTTPClient.Request(url: "http://localhost:8081")
        client.execute(request: request, baggage: baggage).whenComplete { _ in
            let responseHead = HTTPResponseHead(version: requestHead.version, status: .ok)
            context.eventLoop.execute {
                context.channel.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
                context.channel.write(self.wrapOutboundOut(.end(nil)), promise: nil)
                context.channel.flush()
            }
        }

        // TODO: Shut down client before deinit
    }
}
