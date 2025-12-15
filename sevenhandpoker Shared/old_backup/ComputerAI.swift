//
//  ComputerAI.swift
//  Seven Hand Poker
//
//  Converted to Swift from ComputerAI.h/m
//

import Foundation

@MainActor
class ComputerAI {
    // MARK: - Properties

    private var player2Deck: [CardUI] = []
    private var level: Int = 1

    // MARK: - Singleton

    static let sharedInstance = ComputerAI()

    private init() {}

    // MARK: - Public Methods

    func setDeck(_ deck: [CardUI]) {
        player2Deck = deck
    }

    func setLevel(_ newLevel: Int) {
        level = newLevel
    }

    func selectCard(deckPos: Int) {
        guard !player2Deck.isEmpty else { return }

        // AI logic based on level
        switch level {
        case 0: // Easy - random selection
            selectRandom()
        case 1: // Medium - basic strategy
            selectMedium(deckPos: deckPos)
        case 2: // Hard - advanced strategy
            selectHard(deckPos: deckPos)
        default:
            selectMedium(deckPos: deckPos)
        }
    }

    // MARK: - AI Strategies

    private func selectRandom() {
        // Simply select a random card
        if let randomIndex = (0..<player2Deck.count).randomElement() {
            player2Deck[randomIndex].setSelect(true)
        }
    }

    private func selectMedium(deckPos: Int) {
        guard !player2Deck.isEmpty else { return }

        // Sort deck by number for easier analysis
        let sortedIndices = player2Deck.indices.sorted { player2Deck[$0].getNumber() < player2Deck[$1].getNumber() }

        // Try to find pairs or better
        var selected = false

        // Look for pairs
        for i in 0..<(sortedIndices.count - 1) {
            if player2Deck[sortedIndices[i]].getNumber() == player2Deck[sortedIndices[i + 1]].getNumber() {
                player2Deck[sortedIndices[i]].setSelect(true)
                selected = true
                break
            }
        }

        // If no pair found, select highest card
        if !selected {
            if let lastIndex = sortedIndices.last {
                player2Deck[lastIndex].setSelect(true)
            }
        }
    }

    private func selectHard(deckPos: Int) {
        guard !player2Deck.isEmpty else { return }

        // Advanced strategy - look for best combination
        let sortedIndices = player2Deck.indices.sorted { player2Deck[$0].getNumber() < player2Deck[$1].getNumber() }

        // Count occurrences of each number
        var counts: [Int: [Int]] = [:]
        for (index, card) in player2Deck.enumerated() {
            counts[card.getNumber(), default: []].append(index)
        }

        // Look for four of a kind
        for (_, indices) in counts where indices.count >= 4 {
            player2Deck[indices[0]].setSelect(true)
            return
        }

        // Look for three of a kind
        for (_, indices) in counts where indices.count >= 3 {
            player2Deck[indices[0]].setSelect(true)
            return
        }

        // Look for pairs - select higher pair
        var pairs: [(Int, [Int])] = []
        for (number, indices) in counts where indices.count >= 2 {
            pairs.append((number, indices))
        }
        pairs.sort { $0.0 > $1.0 }

        if let highestPair = pairs.first {
            player2Deck[highestPair.1[0]].setSelect(true)
            return
        }

        // Look for flush potential (same color)
        var colorCounts: [Int: [Int]] = [:]
        for (index, card) in player2Deck.enumerated() {
            colorCounts[card.getColor(), default: []].append(index)
        }

        for (_, indices) in colorCounts where indices.count >= 3 {
            player2Deck[indices[0]].setSelect(true)
            return
        }

        // Default: select highest card
        if let lastIndex = sortedIndices.last {
            player2Deck[lastIndex].setSelect(true)
        }
    }

    func getSelectedCards() -> [CardUI] {
        return player2Deck.filter { $0.getSelected() }
    }

    func deselectAll() {
        for card in player2Deck {
            card.setSelect(false)
        }
    }

    func chooseColumn() -> Int {
        // AI chooses which column to place cards
        // For now, simple strategy: fill columns from left to right
        for col in 0..<7 {
            let deckSize = DeckMgr.sharedInstance.getDeckSize(player: 2, col: col)
            if deckSize < 5 {
                return col
            }
        }
        return 0
    }
}
