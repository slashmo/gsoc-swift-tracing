import Foundation
import Baggage
import Instrumentation

final class TracedLock {
    let name: String
    let underlyingLock: NSLock

    var activeSpan: Span?

    init(name: String) {
        self.name = name
        self.underlyingLock = NSLock()
    }

    func lock(context: BaggageContext) {
        // time here
        self.underlyingLock.lock()
        self.activeSpan = InstrumentationSystem.tracer.startSpan(named: self.name, context: context)
    }

    func unlock(context: BaggageContext) {
        self.activeSpan?.end()
        self.activeSpan = nil
        self.underlyingLock.unlock()
    }

    func withLock(context: BaggageContext, _ closure: () -> Void) {
        self.lock(context: context)
        defer { self.unlock(context: context) }
        closure()
    }
}
