//
//  TipManager.swift
//  Seven Hand Poker
//
//  Manages game tips shown during idle state
//

import Foundation

class TipManager {
    static let shared = TipManager()

    // Probability of showing a tip (0.0 to 1.0)
    private let tipChance: Double = 0.3

    // Track shown tips to avoid repetition
    private var recentlyShownTips: [Int] = []
    private let maxRecentTips = 5

    private let tips: [String] = [
        "You can change AI difficulty\nin the menu settings.",
        "Use fake card combos\nto bluff your opponent!",
        "Ace (A) is the largest card.",
        "Three of a kind beats\ntwo pairs.",
        "Full house beats\nthree of a kind.",
        "Flush beats a straight.",
        "Try to win 4 columns\nin a row for bonus points!",
        "Watch your opponent's patterns\nto predict their moves.",
        "Sometimes it's better to\nlose a column strategically.",
        "Save your strong cards\nfor crucial moments.",
        "A straight requires 5 cards\nwith consecutive values.",
        "Pairs are stronger\nthan high cards alone.",
        "The CPU gets smarter\non higher difficulties!",
        "Tap cards to select them\nfor your move.",
        "You can play 1 to 5 cards\neach turn."
    ]

    private init() {}

    // Returns a tip if random chance succeeds, nil otherwise
    func shouldShowTip() -> String? {
        guard Double.random(in: 0...1) < tipChance else {
            return nil
        }
        return getRandomTip()
    }

    // Force get a random tip (always returns a tip)
    func getRandomTip() -> String {
        // Get available indices (not recently shown)
        var availableIndices = Array(0..<tips.count).filter { !recentlyShownTips.contains($0) }

        // If all tips have been shown recently, reset
        if availableIndices.isEmpty {
            recentlyShownTips.removeAll()
            availableIndices = Array(0..<tips.count)
        }

        // Pick a random tip from available ones
        let selectedIndex = availableIndices.randomElement()!

        // Track this tip as recently shown
        recentlyShownTips.append(selectedIndex)
        if recentlyShownTips.count > maxRecentTips {
            recentlyShownTips.removeFirst()
        }

        return tips[selectedIndex]
    }
}
