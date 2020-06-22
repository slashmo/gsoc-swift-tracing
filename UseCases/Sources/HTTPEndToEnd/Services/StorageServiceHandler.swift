import Baggage
import BaggageLogging
import Instrumentation
import Logging
import NIO
import NIOHTTP1

final class StorageServiceHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    let logger = Logger(label: "StorageService")

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .head(let requestHead) = self.unwrapInboundIn(data) else { return }

        var baggage = BaggageContext()
        baggage[BaggageContext.BaseLoggerKey.self] = logger
        baggage.logger.info("Handling storage service request")

        let responseHead = HTTPResponseHead(version: requestHead.version, status: .ok)
        context.eventLoop.execute {
            context.channel.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.channel.write(self.wrapOutboundOut(.end(nil)), promise: nil)
            context.channel.flush()
        }
    }
}
