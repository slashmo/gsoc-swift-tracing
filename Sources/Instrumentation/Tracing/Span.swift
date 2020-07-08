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

public protocol Span {
    var operationName: String { get }

    var startTimestamp: DispatchTime { get }
    var endTimestamp: DispatchTime? { get }

    var baggage: BaggageContext { get }

    var events: [Event] { get }
    func addEvent(_ event: Event) -> Self

    var onEnd: (Span) -> Void { get }
    func end(at timestamp: DispatchTime)
}

extension Span {
    public func end() {
        self.end(at: .now())
    }
}

public struct Event {
    public let name: String
    public let timestamp: DispatchTime

    public init(name: String, at timestamp: DispatchTime = .now()) {
        self.name = name
        self.timestamp = timestamp
    }
}
