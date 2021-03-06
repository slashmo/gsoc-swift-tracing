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

/// A "no op" implementation of an `Instrument`.
public struct NoOpInstrument: Instrument {
    public init() {}

    public func inject<Carrier, Injector>(
        _ baggage: Baggage,
        into carrier: inout Carrier,
        using injector: Injector
    )
        where
        Injector: InjectorProtocol,
        Carrier == Injector.Carrier {}

    public func extract<Carrier, Extractor>(
        _ carrier: Carrier,
        into baggage: inout Baggage,
        using extractor: Extractor
    )
        where
        Extractor: ExtractorProtocol,
        Carrier == Extractor.Carrier {}
}
