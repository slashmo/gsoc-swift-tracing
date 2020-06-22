import AsyncHTTPClient
import Baggage
import BaggageLogging
import Instrumentation
import NIO
import NIOHTTP1

struct InstrumentedHTTPClient {
    private let client = HTTPClient(eventLoopGroupProvider: .createNew)
    private let instrument: Instrument<HTTPHeaders, HTTPHeaders>

    init<I>(instrument: I, eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider)
        where
        I: InstrumentProtocol,
        I.InjectInto == HTTPHeaders,
        I.ExtractFrom == HTTPHeaders {
        self.instrument = Instrument(instrument)
    }

    func execute(request: HTTPClient.Request, baggage: BaggageContext) -> EventLoopFuture<HTTPClient.Response> {
        var request = request
        self.instrument.inject(from: baggage, into: &request.headers)
        baggage.logger.info("AsyncHTTPClient: Execute request")
        return self.client.execute(request: request)
    }
}
