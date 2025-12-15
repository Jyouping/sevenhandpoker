//
//  ComputerAI.swift
//  Seven Hand Poker
//
//  AI for player 2 (computer opponent)
//

import Foundation

class ComputerAI {
    // MARK: - Properties

    private var level: Int = 1  // 0=Easy, 1=Medium, 2=Hard

    // MARK: - Singleton

    static let shared = ComputerAI()
    
    let humanPlayer: Int = 1

    private init() {}

    // MARK: - Public Methods

    func setLevel(_ newLevel: Int) {
        level = max(0, min(2, newLevel))
    }

    func getLevel() -> Int {
        return level
    }

    /// Select cards from player2's hand based on AI level
    func selectCards() {
        let player2Deck = DeckMgr.shared.player2Hand
        guard !player2Deck.isEmpty else { return }

        // Deselect all first
        DeckMgr.shared.deselectAll(player: 2)

        switch level {
        case 0:
            selectEasy(deck: player2Deck)
        case 1:
            selectMedium(deck: player2Deck)
        case 2:
            selectHard(deck: player2Deck)
        default:
            selectMedium(deck: player2Deck)
        }
    }

    /// Choose which column to place opponent's cards (strategic placement)
    func chooseColumnForOpponent() -> Int {
        // AI decides where to place player1's cards
        // Strategy: place in the worst position for player1

        switch level {
        case 0:
            return chooseColumnRandom()
        case 1:
            return chooseColumnMedium()
        case 2:
            return chooseColumnHard()
        default:
            return chooseColumnMedium()
        }
    }

    // MARK: - Card Selection Strategies

    private func selectEasy(deck: [CardSprite]) {
        // Easy: randomly select 1-2 cards
        let count = Int.random(in: 1...min(2, deck.count))
        let shuffled = deck.shuffled()
        for i in 0..<count {
            shuffled[i].setSelected(true)
        }
    }

    private func selectMedium(deck: [CardSprite]) {
        // Medium: look for pairs, otherwise play high card
        let sortedDeck = deck.sorted { $0.getNumber() < $1.getNumber() }

        // Look for pairs
        for i in 0..<(sortedDeck.count - 1) {
            if sortedDeck[i].getNumber() == sortedDeck[i + 1].getNumber() {
                sortedDeck[i].setSelected(true)
                sortedDeck[i + 1].setSelected(true)
                return
            }
        }

        // No pair found - select highest card
        if let highCard = sortedDeck.last {
            highCard.setSelected(true)
        }
    }

    private func selectHard(deck: [CardSprite]) {
        // Hard: look for best combination

        // Count occurrences of each number
        var numberCounts: [Int: [CardSprite]] = [:]
        for card in deck {
            numberCounts[card.getNumber(), default: []].append(card)
        }

        // Count occurrences of each color (suit)
        var colorCounts: [Int: [CardSprite]] = [:]
        for card in deck {
            colorCounts[card.getColor(), default: []].append(card)
        }

        // Priority 1: Four of a kind
        for (_, cards) in numberCounts where cards.count >= 4 {
            for card in cards.prefix(4) {
                card.setSelected(true)
            }
            return
        }

        // Priority 2: Three of a kind
        for (_, cards) in numberCounts where cards.count >= 3 {
            for card in cards.prefix(3) {
                card.setSelected(true)
            }
            return
        }

        // Priority 3: Two pairs (select higher pair)
        let pairs = numberCounts.filter { $0.value.count >= 2 }
            .sorted { $0.key > $1.key }

        if pairs.count >= 2 {
            // Select top two pairs
            for card in pairs[0].value.prefix(2) {
                card.setSelected(true)
            }
            for card in pairs[1].value.prefix(2) {
                card.setSelected(true)
            }
            return
        }

        // Priority 4: Single pair (higher value)
        if let highestPair = pairs.first {
            for card in highestPair.value.prefix(2) {
                card.setSelected(true)
            }
            return
        }

        // Priority 5: Flush potential (4+ cards of same suit)
        for (_, cards) in colorCounts where cards.count >= 4 {
            // Select up to 5 cards for flush
            let sortedByNumber = cards.sorted { $0.getNumber() > $1.getNumber() }
            for card in sortedByNumber.prefix(5) {
                card.setSelected(true)
            }
            return
        }

        // Priority 6: Straight potential
        if let straightCards = findStraightPotential(deck: deck) {
            for card in straightCards {
                card.setSelected(true)
            }
            return
        }

        // Default: select highest card
        let sortedDeck = deck.sorted { $0.getNumber() > $1.getNumber() }
        if let highCard = sortedDeck.first {
            highCard.setSelected(true)
        }
    }

    private func findStraightPotential(deck: [CardSprite]) -> [CardSprite]? {
        // Look for 3+ consecutive cards
        let sortedDeck = deck.sorted { $0.getNumber() < $1.getNumber() }
        var consecutive: [CardSprite] = []

        for card in sortedDeck {
            if consecutive.isEmpty {
                consecutive.append(card)
            } else if card.getNumber() == consecutive.last!.getNumber() + 1 {
                consecutive.append(card)
            } else if card.getNumber() != consecutive.last!.getNumber() {
                if consecutive.count >= 3 {
                    return consecutive
                }
                consecutive = [card]
            }
        }

        return consecutive.count >= 3 ? consecutive : nil
    }

    // MARK: - Column Selection Strategies

    private func chooseColumnRandom() -> Int {
        // Random available column
        var available: [Int] = []
        for col in 0..<7 {
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) == 0 {
                available.append(col)
            }
        }
        return available.randomElement() ?? 0
    }

    private func chooseColumnMedium() -> Int {
        // Medium: Place opponent's weak cards against our strong positions
        var bestCol = 0
        var foundEmpty = false

        for col in 0..<7 {
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) == 0 {
                bestCol = col
                foundEmpty = true
                break
            }
        }

        return foundEmpty ? bestCol : 0
    }

    private func chooseColumnHard() -> Int {
        let selectedCards = DeckMgr.shared.getSelectedCards(player: 1)
        let opponentCardType = DeckMgr.shared.getBestOfCards(selectedCards)

        var bestCol = 0
        var bestScore = Int.min

        for col in 0..<7 {
            // Skip if we already placed there
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) > 0 {
                continue
            }

            // Check if we have cards in this column
            let ourCards = DeckMgr.shared.getPokerDeck(player: 2, col: col)

            var score = 0

            if ourCards.isEmpty {
                // No cards yet - neutral position
                // Prefer middle columns (more strategic options)
                score = 3 - abs(col - 3)
            } else {
                // We have cards - evaluate matchup
                let ourCardType = DeckMgr.shared.getBestOfCards(ourCards)

                // If opponent's cards are weak, place them where we're strong
                if opponentCardType.rawValue < ourCardType.rawValue {
                    score = ourCardType.rawValue * 2
                } else {
                    // Opponent is strong - avoid our weak spots
                    score = -ourCardType.rawValue
                }
            }

            if score > bestScore {
                bestScore = score
                bestCol = col
            }
        }

        return bestCol
    }
}
