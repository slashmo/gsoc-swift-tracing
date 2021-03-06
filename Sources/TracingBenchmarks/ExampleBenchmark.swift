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

import TracingBenchmarkTools

public let ExampleBenchmarks: [BenchmarkInfo] = [
    BenchmarkInfo(
        name: "ExampleBenchmarks.bench_example",
        runFunction: { _ in try! bench_example(50000) },
        tags: [],
        setUpFunction: { setUp() },
        tearDownFunction: tearDown
    ),
]

private func setUp() {
    // ...
}

private func tearDown() {
    // ...
}

// completely silly "benchmark" function
func bench_example(_ count: Int) throws {
    var sum = 0
    for _ in 1 ... count {
        sum += 1
    }
}
