//
//  DeckMgr.swift
//  Seven Hand Poker
//
//  Converted to Swift from DeckMgr.h/m
//

import UIKit

@MainActor
class DeckMgr {
    // MARK: - Properties

    private var deck: [Card] = []
    private var player1Card: [Card] = []
    private var player2Card: [Card] = []
    private var shuffledNum: [Int] = []

    var player1Deck: [CardUI] = []
    var player2Deck: [CardUI] = []

    var p1Poker: [[CardUI]] = Array(repeating: [], count: 7)
    var p2Poker: [[CardUI]] = Array(repeating: [], count: 7)

    private var deckPos: Int = 0
    private var seedNumber: Int = 0

    weak var clickDelegate: CardUIDelegate?

    // MARK: - Singleton

    static let sharedInstance = DeckMgr()

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
        seedNumber = Int(arc4random_uniform(10000))
        shuffleNum()
        deckPos = 0

        player1Card.removeAll()
        player2Card.removeAll()

        for i in 0..<6 {
            p1Poker[i].removeAll()
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

    func drawACard() -> Card {
        let card = deck[shuffledNum[deckPos]]
        deckPos += 1
        return card
    }

    func drawACardUI(player: Int) -> CardUI {
        let card = drawACard()

        let cardUI: CardUI
        if player == 1 {
            cardUI = CardUI(color: card.color, number: card.number, face: 1, x: 240, y: 200, owner: player)
            player1Card.append(card)
        } else {
            cardUI = CardUI(color: card.color, number: card.number, face: 0, x: 240, y: 110, owner: player)
            player2Card.append(card)
        }

        cardUI.clickDelegate = clickDelegate
        return cardUI
    }

    // MARK: - Sorting

    func sortDeck(deck: inout [CardUI], type: Int) {
        switch type {
        case 0:
            deck.sort { $0.getNumber() < $1.getNumber() }
        case 1:
            deck.sort { $0.getColor() < $1.getColor() }
        default:
            break
        }
    }

    // MARK: - Card Comparison

    func getBestOfCards(_ cards: [CardUI]) -> Int {
        guard cards.count >= 5 else { return 0 }

        // Sort by number
        let sortedCards = cards.sorted { $0.getNumber() < $1.getNumber() }

        // Check for flush
        let isFlush = cards.allSatisfy { $0.getColor() == cards[0].getColor() }

        // Check for straight
        var isStraight = true
        var numbers = sortedCards.map { $0.getNumber() }

        // Handle ace-low straight (A-2-3-4-5)
        if numbers == [0, 1, 2, 3, 12] {
            numbers = [-1, 0, 1, 2, 3] // Treat A as -1 for this straight
            isStraight = true
        } else {
            for i in 1..<5 {
                if numbers[i] != numbers[i-1] + 1 {
                    isStraight = false
                    break
                }
            }
            // Handle A-10-J-Q-K straight
            if !isStraight && numbers == [8, 9, 10, 11, 12] {
                isStraight = true
            }
        }

        // Count occurrences of each number
        var counts: [Int: Int] = [:]
        for card in cards {
            counts[card.getNumber(), default: 0] += 1
        }
        let countValues = Array(counts.values).sorted().reversed()

        // Determine hand rank
        if isFlush && isStraight {
            return CardType.flushStrait.rawValue
        }
        if countValues.first == 4 {
            return CardType.quart.rawValue
        }
        if countValues.starts(with: [3, 2]) {
            return CardType.fullHouse.rawValue
        }
        if isFlush {
            return CardType.flushNormal.rawValue
        }
        if isStraight {
            return CardType.straight.rawValue
        }
        if countValues.first == 3 {
            return CardType.trebleton.rawValue
        }
        if countValues.starts(with: [2, 2]) {
            return CardType.twoPair.rawValue
        }
        if countValues.first == 2 {
            return CardType.onePair.rawValue
        }

        return CardType.highCard.rawValue
    }

    func compare5Deck(p1: [CardUI], p2: [CardUI]) -> PlayerType {
        let rank1 = getBestOfCards(p1)
        let rank2 = getBestOfCards(p2)

        if rank1 > rank2 {
            return .player1
        } else if rank1 < rank2 {
            return .player2
        }

        // Same rank - compare by highest cards
        let sorted1 = p1.sorted { $0.getNumber() > $1.getNumber() }
        let sorted2 = p2.sorted { $0.getNumber() > $1.getNumber() }

        for i in 0..<5 {
            if sorted1[i].getNumber() > sorted2[i].getNumber() {
                return .player1
            } else if sorted1[i].getNumber() < sorted2[i].getNumber() {
                return .player2
            }
        }

        // Compare by suit if numbers are equal
        for i in 0..<5 {
            if sorted1[i].getColor() < sorted2[i].getColor() {
                return .player1
            } else if sorted1[i].getColor() > sorted2[i].getColor() {
                return .player2
            }
        }

        return .even
    }

    // MARK: - Poker Deck Management

    func putToPoker(player: Int, col: Int, from deck: inout [CardUI]) {
        for card in deck where card.getSelected() {
            card.setSelect(false)
            if player == 1 {
                p1Poker[col].append(card)
            } else {
                p2Poker[col].append(card)
            }
        }
        deck.removeAll { $0.getSelected() }
    }

    func getDeckSize(player: Int, col: Int) -> Int {
        if player == 1 {
            return p1Poker[col].count
        } else {
            return p2Poker[col].count
        }
    }

    func getPokerDeck(player: Int, col: Int) -> [CardUI] {
        if player == 1 {
            return p1Poker[col]
        } else {
            return p2Poker[col]
        }
    }

    func clearPokerDecks() {
        for i in 0..<7 {
            p1Poker[i].removeAll()
            p2Poker[i].removeAll()
        }
    }

    // MARK: - Card Type Description

    func getCardTypeString(_ type: CardType) -> String {
        switch type {
        case .highCard:
            return "High Card"
        case .onePair:
            return "One Pair"
        case .twoPair:
            return "Two Pair"
        case .trebleton:
            return "Three of a Kind"
        case .straight:
            return "Straight"
        case .flushNormal:
            return "Flush"
        case .fullHouse:
            return "Full House"
        case .quart:
            return "Four of a Kind"
        case .flushStrait:
            return "Straight Flush"
        }
    }
}
