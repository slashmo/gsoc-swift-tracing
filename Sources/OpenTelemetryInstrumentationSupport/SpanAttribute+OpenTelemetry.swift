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

import TracingInstrumentation

public protocol SpanAttributeKey {
    static var name: String { get }

    associatedtype Value: SpanAttributeConvertible
}

extension Span {
    public mutating func setAttribute<Key: SpanAttributeKey>(_ value: Key.Value, forKey: Key.Type) {
        // TODO: - Change to setAttribute once #92 was merged
        self.attributes[Key.name] = value.toSpanAttribute()
    }
}

extension SpanAttribute {
    public enum HTTP {
        public enum Method: SpanAttributeKey {
            public static let name = "http.method"
            public typealias Value = String
        }

        public enum StatusCode: SpanAttributeKey {
            public static let name = "http.status_code"
            public typealias Value = Int
        }
    }
}
