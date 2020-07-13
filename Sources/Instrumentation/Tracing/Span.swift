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

/// A `Span` type that follows the OpenTracing/OpenTelemetry spec. The span itself should not be
/// initializable via its public interface. `Span` creation should instead go through `tracer.startSpan`
/// where `tracer` conforms to `TracingInstrument`.
public protocol Span {
    /// The operation name is a human-readable string which concisely identifies the work represented by the `Span`.
    ///
    /// For guideline on how to name `Span`s, please take a look at the
    /// [OpenTelemetry specification](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/api.md#span).
    var operationName: String { get }

    /// The precise `DispatchTime` of when the `Span` was started.
    var startTimestamp: DispatchTime { get }

    /// The precise `DispatchTime` of when the `Span` has ended.
    var endTimestamp: DispatchTime? { get }

    /// The read-only `BaggageContext` of this `Span`, set when starting this `Span`.
    var baggage: BaggageContext { get }

    /// The read-only collection of events which happened within this `Span`.
    ///
    /// `SpanEvent`s might be added via the `addEvent` or `addingEvent` `Span` methods.
    var events: [SpanEvent] { get }

    /// Add a `SpanEvent` in place.
    /// - Parameter event: The `SpanEvent` to add to this `Span`.
    mutating func addEvent(_ event: SpanEvent)

    // TODO: Wrap in a struct to hide collection implementation details.

    /// The attributes describing this `Span`.
    var attributes: [String: SpanAttribute] { get }

    /// Accesses the `SpanAttribute` with the given name for reading and writing.
    /// - Parameter attributeName: The name of the attribute used to identify the attribute.
    /// - Returns:The `SpanAttribute` identified by the given name, or `nil` if it's not present.
    subscript(attributeName attributeName: String) -> SpanAttribute? { get set }

    /// Returns true if this `Span` is recording information like events, attributes, status, etc.
    var isRecording: Bool { get }

    // TODO: naming is defined in the spec, but we may want to consider finish instead as it sounds more like a verb

    /// End this `Span` at the given timestamp.
    /// - Parameter timestamp: The `DispatchTime` at which the span ended.
    mutating func end(at timestamp: DispatchTime)
}

extension Span {
    /// Create a copy of this `Span` with the given event added to the existing set of events.
    /// - Parameter event: The new `SpanEvent` to be added to the returned copy.
    /// - Returns: A copy of this `Span` with the given event added to the existing set of events.
    public func addingEvent(_ event: SpanEvent) -> Self {
        var copy = self
        copy.addEvent(event)
        return copy
    }

    /// End this `Span` at the current timestamp.
    public mutating func end() {
        self.end(at: .now())
    }
}

// ==== ----------------------------------------------------------------------------------------------------------------
// MARK: Span Event

/// An event that occured during a `Span`.
public struct SpanEvent {
    /// The human-readable name of this `SpanEvent`.
    public let name: String

    // TODO: Same as for `Span.attributes`. Wrap in struct to hide implementation details.

    /// One or more `SpanAttribute`s with the same restrictions as defined for `Span` attributes.
    public let attributes: [String: SpanAttribute]

    /// The `DispatchTime` at which this event occured.
    public let timestamp: DispatchTime

    /// Create a new `SpanEvent`.
    /// - Parameters:
    ///   - name: The human-readable name of this event.
    ///   - attributes: The `SpanAttributes` describing this event. Defaults to no attributes.
    ///   - timestamp: The `DispatchTime` at which this event occured. Defaults to `.now()`.
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

/// The value of an attribute used to describe a `Span` or `SpanEvent`.
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
