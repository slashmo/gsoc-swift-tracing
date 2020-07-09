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

    var events: [SpanEvent] { get }
    mutating func addEvent(_ event: SpanEvent)

    var attributes: [String: SpanAttribute] { get }
    subscript(attributeName attributeName: String) -> SpanAttribute? { get set }

    var onEnd: (Span) -> Void { get }
    mutating func end(at timestamp: DispatchTime)
}

extension Span {
    public func addingEvent(_ event: SpanEvent) -> Self {
        var copy = self
        copy.addEvent(event)
        return copy
    }

    public mutating func end() {
        self.end(at: .now())
    }
}

public struct SpanEvent {
    public let name: String
    public let timestamp: DispatchTime

    public init(name: String, at timestamp: DispatchTime = .now()) {
        self.name = name
        self.timestamp = timestamp
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Span Attribute
public enum SpanAttribute {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([SpanAttribute])
    case stringConvertible(CustomStringConvertible)
}

extension SpanAttribute: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension SpanAttribute: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension SpanAttribute: ExpressibleByArrayLiteral {
    public init(arrayLiteral attributes: SpanAttribute...) {
        self = .array(attributes)
    }
}

extension SpanAttribute: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension SpanAttribute: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}
