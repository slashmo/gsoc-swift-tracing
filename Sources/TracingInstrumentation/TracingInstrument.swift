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

/// An `Instrument` with added functionality for distributed tracing. Is uses the span-based tracing model and is
/// based on the OpenTracing/OpenTelemetry spec.
public protocol TracingInstrument: Instrument {
    /// Start a new `Span` within the given `BaggageContext` at a given timestamp.
    /// - Parameters:
    ///   - operationName: The name of the operation being traced. This may be a handler function, database call, ...
    ///   - context: The carrier of a `BaggageContext` within to start the new `Span`.
    ///   - kind: The `SpanKind` of the new `Span`.
    ///   - timestamp: The `DispatchTime` at which to start the new `Span`. Passing `nil` leaves the timestamp capture to the underlying tracing instrument.
    func startSpan(
        named operationName: String,
        context: BaggageContextCarrier,
        ofKind kind: SpanKind,
        at timestamp: Timestamp?
    ) -> Span

    /// Export all ended spans to the configured backend that have not yet been exported.
    ///
    /// This function should only be called in cases where it is absolutely necessary,
    /// such as when using some FaaS providers that may suspend the process after an invocation, but before the backend exports the completed spans.
    ///
    /// This function should not block indefinitely, implementations should offer a configurable timeout for flush operations.
    func forceFlush()

    /// Shuts down the `TracingInstrument`. This is an opportunity for the tracer to do any cleanup required.
    ///
    /// This function should be called only once for each `TracingInstrument` instance. After the call to shutdown subsequent calls to
    /// `forceFlush` are not allowed.
    ///
    /// This function should not block indefinitely, implementations may offer a configurable timeout for flush operations.
    func shutdown()
}

extension TracingInstrument {
    /// Start a new `Span` within the given `BaggageContext`. This passes `nil` as the timestamp to the tracer, which
    /// usually means it should default to the current timestamp.
    /// - Parameters:
    ///   - operationName: The name of the operation being traced. This may be a handler function, database call, ...
    ///   - context: The carrier of a `BaggageContext` within to start the new `Span`.
    ///   - kind: The `SpanKind` of the `Span` to be created. Defaults to `.internal`.
    ///   - timestamp: The `DispatchTime` at which to start the new `Span`. Defaults to `nil`, meaning the timestamp capture is left up to the underlying tracing instrument.
    public func startSpan(
        named operationName: String,
        context: BaggageContextCarrier,
        at timestamp: Timestamp? = nil
    ) -> Span {
        self.startSpan(named: operationName, context: context, ofKind: .internal, at: nil)
    }
}
