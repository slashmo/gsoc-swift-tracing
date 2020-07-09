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

    // TODO: naming is defined in the spec, but we may want to consider finish instead as it sounds more like a verb
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

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Span Event

public struct SpanEvent {
    public let name: String

    /// One or more Attributes with the same restrictions as defined for Span Attributes.
    public let attributes: [String: SpanAttribute]

    public let timestamp: DispatchTime

    public init(name: String, attributes: [String: SpanAttribute] = [:], at timestamp: DispatchTime = .now()) {
        self.name = name
        self.attributes = attributes
        self.timestamp = timestamp
    }
}

extension SpanEvent: ExpressibleByStringLiteral {
    public init(stringLiteral name: String) {
        self.init(name: name)
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Span Attribute

public enum SpanAttribute {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    // TODO: This could be misused to create a heterogenuous array of attributes, which is not allowed in OT:
    // https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/api.md#set-attributes
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

extension SpanAttribute: ExpressibleByArrayLiteral {
    public init(arrayLiteral attributes: SpanAttribute...) {
        self = .array(attributes)
    }
}
