//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Tracing open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift Tracing project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Baggage
import Instrumentation
import OpenTelemetryInstrumentationSupport
import TracingInstrumentation
import XCTest

final class SpanAttributeOpenTelemetryTests: XCTestCase {
    func testSemanticAttributes() {
        InstrumentationSystem.bootstrap(FakeTracer())
        var span = InstrumentationSystem.tracingInstrument.startSpan(named: "test", context: BaggageContext())
        span.setAttribute(418, forKey: SpanAttribute.HTTP.StatusCode.self)
        guard case .int(let statusCode) = span.attributes[SpanAttribute.HTTP.StatusCode.name] else {
            XCTFail("Expected status code in span attributes, got \(span.attributes)")
            return
        }
        XCTAssertEqual(statusCode, 418)
    }
}

private struct FakeTracer: TracingInstrument {
    public func startSpan(
        named operationName: String,
        context: BaggageContext,
        ofKind kind: SpanKind,
        at timestamp: Timestamp?
    ) -> Span {
        FakeSpan()
    }

    public func inject<Carrier, Injector>(_ context: BaggageContext, into carrier: inout Carrier, using injector: Injector)
        where
        Injector: InjectorProtocol,
        Carrier == Injector.Carrier {}

    public func extract<Carrier, Extractor>(_ carrier: Carrier, into baggage: inout BaggageContext, using extractor: Extractor)
        where
        Extractor: ExtractorProtocol,
        Carrier == Extractor.Carrier {}

    struct FakeSpan: Span {
        public var operationName: String = ""
        public var status: SpanStatus?
        public let kind: SpanKind = .internal
        private var _attributes: SpanAttributes = [:]

        public var startTimestamp: Timestamp {
            .now()
        }

        public var endTimestamp: Timestamp?

        public var baggage: BaggageContext {
            .init()
        }

        public mutating func addLink(_ link: SpanLink) {}

        public mutating func addEvent(_ event: SpanEvent) {}

        public var attributes: SpanAttributes {
            get {
                self._attributes
            }
            set {
                self._attributes = newValue
            }
        }

        public let isRecording = false

        public mutating func end(at timestamp: Timestamp) {
            // ignore
        }
    }
}
