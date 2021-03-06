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
@testable import Instrumentation
import Tracing
import XCTest

final class TracedLockTests: XCTestCase {
    override class func tearDown() {
        super.tearDown()
        InstrumentationSystem.bootstrapInternal(nil)
    }

    func test_tracesLockedTime() {
        let tracer = TracedLockPrintlnTracer()
        InstrumentationSystem.bootstrapInternal(tracer)

        let lock = TracedLock(name: "my-cool-lock")

        func launchTask(_ name: String) {
            DispatchQueue.global().async {
                var baggage = Baggage.topLevel
                baggage[TaskIDKey.self] = name

                lock.lock(baggage: baggage)
                lock.unlock(baggage: baggage)
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

enum TaskIDKey: Baggage.Key {
    typealias Value = String
    static let name: String? = "LockedOperationNameKey"
}

// ==== ------------------------------------------------------------------------
// MARK: PrintLn Tracer

private final class TracedLockPrintlnTracer: Tracer {
    func startSpan(
        named operationName: String,
        baggage: Baggage,
        ofKind kind: SpanKind,
        at timestamp: Timestamp
    ) -> Span {
        return TracedLockPrintlnSpan(
            operationName: operationName,
            startTimestamp: timestamp,
            kind: kind,
            baggage: baggage
        )
    }

    public func forceFlush() {}

    func inject<Carrier, Injector>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Injector
    )
        where
        Injector: InjectorProtocol,
        Carrier == Injector.Carrier {}

    func extract<Carrier, Extractor>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extractor
    )
        where
        Extractor: ExtractorProtocol,
        Carrier == Extractor.Carrier {}

    final class TracedLockPrintlnSpan: Span {
        private let operationName: String
        private let kind: SpanKind

        private var status: SpanStatus?

        private let startTimestamp: Timestamp
        private(set) var endTimestamp: Timestamp?

        let baggage: Baggage

        private var links = [SpanLink]()

        private var events = [SpanEvent]() {
            didSet {
                self.isRecording = !self.events.isEmpty
            }
        }

        var attributes: SpanAttributes = [:] {
            didSet {
                self.isRecording = !self.attributes.isEmpty
            }
        }

        private(set) var isRecording = false

        init(
            operationName: String,
            startTimestamp: Timestamp,
            kind: SpanKind,
            baggage: Baggage
        ) {
            self.operationName = operationName
            self.startTimestamp = startTimestamp
            self.baggage = baggage
            self.kind = kind

            print("  span [\(self.operationName): \(self.baggage[TaskIDKey.self] ?? "no-name")] @ \(self.startTimestamp): start")
        }

        func setStatus(_ status: SpanStatus) {
            self.status = status
            self.isRecording = true
        }

        func addLink(_ link: SpanLink) {
            self.links.append(link)
        }

        func addEvent(_ event: SpanEvent) {
            self.events.append(event)
        }

        func recordError(_ error: Error) {}

        func end(at timestamp: Timestamp) {
            self.endTimestamp = timestamp
            print("     span [\(self.operationName): \(self.baggage[TaskIDKey.self] ?? "no-name")] @ \(timestamp): end")
        }
    }
}
