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
import BaggageLogging
@testable import Instrumentation
import TracingInstrumentation
import XCTest

final class TracedLockTests: XCTestCase {
    func test_tracesLockedTime() {
        let tracer = TracedLockPrintlnTracer()
        InstrumentationSystem.bootstrapInternal(tracer)

        let lock = TracedLock(name: "my-cool-lock")

        func launchTask(_ name: String) {
            DispatchQueue.global().async {
                var context = BaggageContext()
                context[TaskIDKey.self] = name

                lock.lock(context: context)
                lock.unlock(context: context)
            }
        }
        launchTask("one")
        launchTask("two")
        launchTask("three")
        launchTask("four")

        Thread.sleep(forTimeInterval: 1)
    }
}

// ==== ------------------------------------------------------------------------
// MARK: test keys

enum TaskIDKey: BaggageContextKey {
    typealias Value = String
    static let name: String? = "LockedOperationNameKey"
}

// ==== ------------------------------------------------------------------------
// MARK: PrintLn Tracer

private final class TracedLockPrintlnTracer: TracingInstrument {
    func startSpan(
        named operationName: String,
        context: BaggageContext,
        ofKind kind: SpanKind,
        at timestamp: Timestamp?
    ) -> Span {
        TracedLockPrintlnSpan(
            operationName: operationName,
            startTimestamp: timestamp ?? .now(),
            kind: kind,
            context: context
        )
    }

    func inject<Carrier, Injector>(_ baggage: BaggageContext, into carrier: inout Carrier, using injector: Injector)
        where
        Injector: InjectorProtocol,
        Carrier == Injector.Carrier {}

    func extract<Carrier, Extractor>(_ carrier: Carrier, into baggage: inout BaggageContext, using extractor: Extractor)
        where
        Extractor: ExtractorProtocol,
        Carrier == Extractor.Carrier {}

    struct TracedLockPrintlnSpan: Span {
        let operationName: String
        let kind: SpanKind

        var status: SpanStatus? {
            didSet {
                self.isRecording = self.status != nil
            }
        }

        let startTimestamp: Timestamp
        private(set) var endTimestamp: Timestamp?

        let baggage: BaggageContext

        private var links = [SpanLink]()

        private var events = [SpanEvent]() {
            didSet {
                self.isRecording = !self.events.isEmpty
            }
        }

        private var attributes: SpanAttributes = [:] {
            didSet {
                self.isRecording = !self.attributes.isEmpty
            }
        }

        public mutating func setAttribute(_ value: String, forKey key: String) {
            self.attributes[key] = .string(value)
        }

        public mutating func setAttribute(_ value: [String], forKey key: String) {
            self.attributes[key] = .array(value.map(SpanAttribute.string))
        }

        public mutating func setAttribute(_ value: Int, forKey key: String) {
            self.attributes[key] = .int(value)
        }

        public mutating func setAttribute(_ value: [Int], forKey key: String) {
            self.attributes[key] = .array(value.map(SpanAttribute.int))
        }

        public mutating func setAttribute(_ value: Double, forKey key: String) {
            self.attributes[key] = .double(value)
        }

        public mutating func setAttribute(_ value: [Double], forKey key: String) {
            self.attributes[key] = .array(value.map(SpanAttribute.double))
        }

        public mutating func setAttribute(_ value: Bool, forKey key: String) {
            self.attributes[key] = .bool(value)
        }

        public mutating func setAttribute(_ value: [Bool], forKey key: String) {
            self.attributes[key] = .array(value.map(SpanAttribute.bool))
        }

        private(set) var isRecording = false

        init(
            operationName: String,
            startTimestamp: Timestamp,
            kind: SpanKind,
            context baggage: BaggageContext
        ) {
            self.operationName = operationName
            self.startTimestamp = startTimestamp
            self.baggage = baggage
            self.kind = kind

            print("  span [\(self.operationName): \(self.baggage[TaskIDKey.self] ?? "no-name")] @ \(self.startTimestamp): start")
        }

        mutating func addLink(_ link: SpanLink) {
            self.links.append(link)
        }

        mutating func addEvent(_ event: SpanEvent) {
            self.events.append(event)
        }

        mutating func end(at timestamp: Timestamp) {
            self.endTimestamp = timestamp
            print("     span [\(self.operationName): \(self.baggage[TaskIDKey.self] ?? "no-name")] @ \(timestamp): end")
        }
    }
}
