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
import Dispatch

public protocol TracingInstrument: Instrument {
    var currentSpan: Span? { get }

    func startSpan(named operationName: String, baggage: BaggageContext, at timestamp: DispatchTime) -> Span
}

extension TracingInstrument {
    public func startSpan(named operationName: String, baggage: BaggageContext) -> Span {
        self.startSpan(named: operationName, baggage: baggage, at: .now())
    }
}

public protocol Span {
    var operationName: String { get }

    var startTimestamp: DispatchTime { get }
    var endTimestamp: DispatchTime? { get }

    var baggage: BaggageContext { get }

    var onEnd: (Span) -> Void { get }
    func end(at timestamp: DispatchTime)
}

extension Span {
    public func end() {
        self.end(at: .now())
    }
}
