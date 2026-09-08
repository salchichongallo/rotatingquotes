//
//  Quote.swift
//  widget
//

import Foundation

struct Quote: Identifiable, Hashable {
    let id: Int
    let text: String
    let author: String?

    init(id: Int, text: String, author: String? = nil) {
        self.id = id
        self.text = text
        self.author = author
    }
}

/// Deterministic PRNG (SplitMix64) so a given seed always yields the same shuffle.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum QuoteLibrary {
    static let rotationInterval: TimeInterval = 5 * 60

    static let all: [Quote] = [
        Quote(id: 0, text: "I leave you the best of myself"),
        Quote(id: 1, text: "The future belongs to those who learn more skills and combine them in creative ways"),
        Quote(id: 2, text: "Is there a way that I can win doing this even if I fail?"),
        Quote(id: 3, text: "You do not rise to the level of your goals, you fall to the level of your systems", author: "James Clear"),
        Quote(id: 4, text: "The obstacle is the way", author: "Marcus Aurelius"),
        Quote(id: 5, text: "Simplicity is the ultimate sophistication", author: "Leonardo da Vinci"),
        Quote(id: 6, text: "What you do every day matters more than what you do once in a while"),
        Quote(id: 7, text: "Compare yourself to who you were yesterday, not to who someone else is today"),
        Quote(id: 8, text: "The best time to plant a tree was twenty years ago. The second best time is now"),
        Quote(id: 9, text: "Amateurs wait for inspiration. Professionals get to work"),
        Quote(id: 10, text: "Make it work, make it right, make it fast", author: "Kent Beck"),
    ]

    /// Start of the 5-minute slot that contains `date`.
    static func slotStart(for date: Date) -> Date {
        let slot = floor(date.timeIntervalSince1970 / rotationInterval)
        return Date(timeIntervalSince1970: slot * rotationInterval)
    }

    static func nextSlot(after date: Date) -> Date {
        slotStart(for: date).addingTimeInterval(rotationInterval)
    }

    /// Picks the quote for `date`. Each cycle of `all.count` slots shows every quote
    /// exactly once, in an order that is random per cycle but reproducible.
    static func quote(at date: Date) -> Quote {
        guard !all.isEmpty else {
            return Quote(id: 0, text: "")
        }

        let count = all.count
        let slot = Int(floor(date.timeIntervalSince1970 / rotationInterval))
        let cycleIndex = Int(floor(Double(slot) / Double(count)))
        let position = ((slot % count) + count) % count

        return all[order(forCycle: cycleIndex)[position]]
    }

    private static func shuffledIndices(forCycle cycle: Int) -> [Int] {
        var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(cycle)))
        return Array(0 ..< all.count).shuffled(using: &generator)
    }

    private static func order(forCycle cycle: Int) -> [Int] {
        var order = shuffledIndices(forCycle: cycle)

        // Keep the same quote from spanning a cycle boundary. The adjustment only touches
        // the first two slots, so the previous cycle's last index is its unadjusted one.
        if all.count > 2,
           let previousLast = shuffledIndices(forCycle: cycle - 1).last,
           order[0] == previousLast {
            order.swapAt(0, 1)
        }

        return order
    }
}
