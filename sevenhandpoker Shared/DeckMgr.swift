//
//  DeckMgr.swift
//  Seven Hand Poker
//
//  Deck manager based on old_backup
//

import Foundation

class DeckMgr {
    // MARK: - Properties

    private var deck: [Card] = []
    private var shuffledNum: [Int] = []
    private var deckPos: Int = 0
    private var seedNumber: Int = 0

    // Player hands (CardSprites held by each player)
    var player1Hand: [CardSprite] = []
    var player2Hand: [CardSprite] = []

    // Poker slots: 7 columns, each can hold up to 5 cards per player
    var p1Poker: [[CardSprite]] = Array(repeating: [], count: 7)
    var p2Poker: [[CardSprite]] = Array(repeating: [], count: 7)

    // MARK: - Singleton

    static let shared = DeckMgr()

    private init() {
        initDeck()
    }

    // MARK: - Deck Initialization

    func initDeck() {
        deck.removeAll()
        for i in 1...52 {
            let card = Card(number: i)
            deck.append(card)
        }
        seedNumber = Int.random(in: 0..<10000)
        shuffleNum()
        deckPos = 0

        //remove card also clean up UI components
        for card in player1Hand { card.removeFromParent() }
        player1Hand.removeAll()
        for card in player2Hand { card.removeFromParent() }
        player2Hand.removeAll()

        for i in 0..<7 {
            for card in p1Poker[i] { card.removeFromParent() }
            p1Poker[i].removeAll()
            for card in p2Poker[i] { card.removeFromParent() }
            p2Poker[i].removeAll()
        }
    }

    func setSeed(_ number: Int) {
        seedNumber = number
        shuffleNum()
    }

    func getSeed() -> Int {
        return seedNumber
    }

    private func shuffleNum() {
        shuffledNum = Array(0..<52)
        srand48(seedNumber)
        for i in stride(from: 51, through: 1, by: -1) {
            let j = Int(drand48() * Double(i + 1))
            shuffledNum.swapAt(i, j)
        }
    }

    // MARK: - Card Drawing

    func drawCard() -> Card {
        let card = deck[shuffledNum[deckPos]]
        deckPos += 1
        return card
    }

    func drawCardSprite(owner: Int, faceUp: Bool) -> CardSprite {
        let card = drawCard()
        let sprite = CardSprite(card: card, owner: owner, faceUp: faceUp)

        if owner == 1 {
            player1Hand.append(sprite)
        } else {
            player2Hand.append(sprite)
        }

        return sprite
    }

    func canDrawCard() -> Bool {
        return deckPos < 52
    }

    func getRemainingCards() -> Int {
        return 52 - deckPos
    }

    // MARK: - Hand Management

    func getSelectedCards(player: Int) -> [CardSprite] {
        let hand = player == 1 ? player1Hand : player2Hand
        return hand.filter { $0.getSelected() }
    }

    func deselectAll(player: Int) {
        let hand = player == 1 ? player1Hand : player2Hand
        for card in hand {
            card.setSelected(false)
        }
    }

    func removeSelectedFromHand(player: Int) -> [CardSprite] {
        let selected = getSelectedCards(player: player)

        if player == 1 {
            player1Hand.removeAll { $0.getSelected() }
        } else {
            player2Hand.removeAll { $0.getSelected() }
        }

        return selected
    }

    // MARK: - Poker Slot Management

    func placeCards(_ cards: [CardSprite], toColumn col: Int, player: Int) {
        for card in cards {
            card.pokerCol = col
            if player == 1 {
                p1Poker[col].append(card)
            } else {
                p2Poker[col].append(card)
            }
        }
    }

    func getColumnSize(player: Int, col: Int) -> Int {
        if player == 1 {
            return p1Poker[col].count
        } else {
            return p2Poker[col].count
        }
    }

    func getPokerDeck(player: Int, col: Int) -> [CardSprite] {
        if player == 1 {
            return p1Poker[col]
        } else {
            return p2Poker[col]
        }
    }

    func isColumnFull(col: Int) -> Bool {
        return p1Poker[col].count > 0 && p2Poker[col].count > 0
    }

    // MARK: - Sorting

    func sortHand(player: Int, byNumber: Bool) {
        if player == 1 {
            if byNumber {
                player1Hand.sort { $0.getNumber() < $1.getNumber() }
            } else {
                player1Hand.sort { $0.getColor() < $1.getColor() }
            }
        } else {
            if byNumber {
                player2Hand.sort { $0.getNumber() < $1.getNumber() }
            } else {
                player2Hand.sort { $0.getColor() < $1.getColor() }
            }
        }
    }

    // MARK: - Card Comparison

    func getBestOfCards(_ cards: [CardSprite]) -> CardType {
        guard cards.count >= 1 else { return .highCard }

        if cards.count < 5 {
            // Less than 5 cards - check for pairs, trips, quads
            var counts: [Int: Int] = [:]
            for card in cards {
                counts[card.getNumber(), default: 0] += 1
            }
            let maxCount = counts.values.max() ?? 1

            if maxCount >= 4 { return .fourOfAKind }
            if maxCount >= 3 { return .threeOfAKind }
            if maxCount >= 2 {
                let pairCount = counts.values.filter { $0 >= 2 }.count
                return pairCount >= 2 ? .twoPair : .onePair
            }
            return .highCard
        }

        // 5 cards - full hand evaluation
        let sortedCards = cards.sorted { $0.getNumber() < $1.getNumber() }

        // Check flush
        let isFlush = cards.allSatisfy { $0.getColor() == cards[0].getColor() }

        // Check straight
        let numbers = sortedCards.map { $0.getNumber() }
        var isStraight = true

        // Handle ace-low straight (A-2-3-4-5): numbers would be [0,1,2,3,12]
        if Set(numbers) == Set([0, 1, 2, 3, 12]) {
            isStraight = true
        } else {
            for i in 1..<5 {
                if numbers[i] != numbers[i-1] + 1 {
                    isStraight = false
                    break
                }
            }
        }

        // Count occurrences
        var counts: [Int: Int] = [:]
        for card in cards {
            counts[card.getNumber(), default: 0] += 1
        }
        let sortedCounts = counts.values.sorted(by: >)

        // Determine hand rank
        if isFlush && isStraight { return .straightFlush }
        if sortedCounts.first == 4 { return .fourOfAKind }
        if sortedCounts.count >= 2 && sortedCounts[0] == 3 && sortedCounts[1] == 2 { return .fullHouse }
        if isFlush { return .flush }
        if isStraight { return .straight }
        if sortedCounts.first == 3 { return .threeOfAKind }
        if sortedCounts.count >= 2 && sortedCounts[0] == 2 && sortedCounts[1] == 2 { return .twoPair }
        if sortedCounts.first == 2 { return .onePair }

        return .highCard
    }

    func compareDecks(p1Cards: [CardSprite], p2Cards: [CardSprite]) -> PlayerType {
        let rank1 = getBestOfCards(p1Cards)
        let rank2 = getBestOfCards(p2Cards)

        if rank1.rawValue > rank2.rawValue {
            return .player1
        } else if rank1.rawValue < rank2.rawValue {
            return .player2
        }

        // Same rank - compare by highest cards
        let sorted1 = p1Cards.sorted { $0.getNumber() > $1.getNumber() }
        let sorted2 = p2Cards.sorted { $0.getNumber() > $1.getNumber() }

        let maxCount = max(sorted1.count, sorted2.count)
        for i in 0..<maxCount {
            let n1 = i < sorted1.count ? sorted1[i].getNumber() : -1
            let n2 = i < sorted2.count ? sorted2[i].getNumber() : -1

            if n1 > n2 { return .player1 }
            if n1 < n2 { return .player2 }
        }

        // Compare by suit if numbers are equal (spade > heart > diamond > club)
        for i in 0..<maxCount {
            let c1 = i < sorted1.count ? sorted1[i].getColor() : 4
            let c2 = i < sorted2.count ? sorted2[i].getColor() : 4

            if c1 < c2 { return .player1 }
            if c1 > c2 { return .player2 }
        }

        return .even
    }

    func compareColumn(_ col: Int) -> PlayerType {
        let p1Cards = p1Poker[col]
        let p2Cards = p2Poker[col]

        guard !p1Cards.isEmpty && !p2Cards.isEmpty else {
            return .none
        }

        return compareDecks(p1Cards: p1Cards, p2Cards: p2Cards)
    }
}
