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
    func startSpan(named operationName: String, setupBaggage: (inout BaggageContext) -> Void) -> Span
}

public struct Span {
    public let operationName: String
    public let startTimestamp: DispatchTime
    public let baggage: BaggageContext

    private var onFinish: (Span) -> Void

    public func finish() {
        self.onFinish(self)
    }

    public init(
        operationName: String,
        startingAt startTimestamp: DispatchTime,
        baggage: BaggageContext,
        onFinish: @escaping (Span) -> Void
    ) {
        self.operationName = operationName
        self.startTimestamp = startTimestamp
        self.baggage = baggage
        self.onFinish = onFinish
    }
}
