import Foundation
import Observation

@Observable final class MatchClock {
    var remaining = [180.0, 180.0]
    var active: Int?
    var moves = [0, 0]
    var started = false
    private var pausedSide = 0
    private let uptime: () -> Double
    private var stamp: Double
    init(uptime: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime }) {
        self.uptime = uptime
        self.stamp = uptime()
    }
    var expired: Int? { remaining.firstIndex(where: { $0 <= 0 }) }
    func update() {
        let now = uptime()
        if let active { remaining[active] = max(0, remaining[active] - (now - stamp)) }
        stamp = now
        if expired != nil { active = nil }
    }
    func press(_ side: Int) {
        update()
        guard expired == nil else { return }
        if !started { started = true; active = side; return }
        guard active == side else { return }
        moves[side] += 1; active = 1 - side
    }
    func pause() { update(); if let active { pausedSide = active }; active = nil }
    func resume() { update(); if expired == nil { active = pausedSide; started = true } }
    func reset() { active = nil; remaining = [180,180]; moves = [0,0]; started = false }
}

