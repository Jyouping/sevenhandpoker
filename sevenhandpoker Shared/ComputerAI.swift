//
//  ComputerAI.swift
//  Seven Hand Poker
//
//  AI for player 2 (computer opponent)
//  Revamped with strategic thinking, bluffing, and resource management
//

import Foundation

class ComputerAI {
    // MARK: - Properties

    private var level: Int = 1  // 0=Easy, 1=Medium, 2=Hard
    var animatedSelection: Bool = true
    private let selectionDelay: TimeInterval = 0.4
    private var soundMgr: SoundMgr!

    // Probability settings
    private let easyToMediumChance: Double = 0.30  // 30% chance Easy uses Medium
    private let mediumToHardChance: Double = 0.50  // 40% chance Medium uses Hard
    private let bluffChance: Double = 0.30         // 30% chance Hard will bluff
    private let bestHandChance: Double = 0.30 //30% that medium size use best card

    // MARK: - Singleton

    static let shared = ComputerAI(soundMgr: SoundMgr.shared)

    let humanPlayer: Int = 1

    private init(soundMgr: SoundMgr) {
        self.soundMgr = soundMgr
    }

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
        switch level {
        case 0:
            return chooseColumnEasy()
        case 1:
            return chooseColumnMedium()
        case 2:
            return chooseColumnHard()
        default:
            return chooseColumnMedium()
        }
    }

    // MARK: - Helper: Animated Selection

    private func selectCardsAnimated(_ cards: [CardSprite]) {
        if animatedSelection {
            for (index, card) in cards.enumerated() {
                let delay = TimeInterval(index) * selectionDelay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.soundMgr.playSelect()
                    card.setSelected(true)
                }
            }
        } else {
            for card in cards {
                card.setSelected(true)
            }
        }
    }

    // MARK: - Game State Analysis

    private func getGameState() -> GameState {
        var p1Score = 0
        var p2Score = 0
        var p1Consecutive = 0
        var p2Consecutive = 0
        var maxP1Consecutive = 0
        var maxP2Consecutive = 0
        var filledColumns = 0
        var p2WinningColumns: [Int] = []
        var p1WinningColumns: [Int] = []
        var placedColumns = 0

        for col in 0..<7 {
            let p1Cards = DeckMgr.shared.getPokerDeck(player: 1, col: col)
            let p2Cards = DeckMgr.shared.getPokerDeck(player: 2, col: col)
            if !p1Cards.isEmpty || !p2Cards.isEmpty {
                placedColumns += 1
            }
            if !p1Cards.isEmpty && !p2Cards.isEmpty {
                filledColumns += 1
                let winner = DeckMgr.shared.compareColumn(col)

                switch winner {
                case .player1:
                    p1Score += 1
                    p1Consecutive += 1
                    p2Consecutive = 0
                    maxP1Consecutive = max(maxP1Consecutive, p1Consecutive)
                    p1WinningColumns.append(col)
                case .player2:
                    p2Score += 1
                    p2Consecutive += 1
                    p1Consecutive = 0
                    maxP2Consecutive = max(maxP2Consecutive, p2Consecutive)
                    p2WinningColumns.append(col)
                case .even:
                    p1Score += 1
                    p2Score += 1
                    p1Consecutive += 1
                    p2Consecutive += 1
                    maxP1Consecutive = max(maxP1Consecutive, p1Consecutive)
                    maxP2Consecutive = max(maxP2Consecutive, p2Consecutive)
                default:
                    p1Consecutive = 0
                    p2Consecutive = 0
                }
            } else {
                p1Consecutive = 0
                p2Consecutive = 0
            }
        }

        return GameState(
            p1Score: p1Score,
            p2Score: p2Score,
            maxP1Consecutive: maxP1Consecutive,
            maxP2Consecutive: maxP2Consecutive,
            filledColumns: filledColumns,
            placedColumns: placedColumns,
            remainingCards: DeckMgr.shared.getRemainingCards(),
            p1WinningColumns: p1WinningColumns,
            p2WinningColumns: p2WinningColumns
        )
    }

    private struct GameState {
        let p1Score: Int
        let p2Score: Int
        let maxP1Consecutive: Int
        let maxP2Consecutive: Int
        let filledColumns: Int
        let placedColumns: Int
        let remainingCards: Int
        let p1WinningColumns: [Int]
        let p2WinningColumns: [Int]

        var isEarlyGame: Bool { filledColumns <= 2 || placedColumns < 3}
        var isMidGame: Bool { !isEarlyGame && (filledColumns <= 3 || placedColumns < 5)}
        var isLateGame: Bool { !isEarlyGame && !isMidGame }
        var p2IsWinning: Bool { p2Score > p1Score }
        var p2IsLosing: Bool { p2Score < p1Score }
    }

    // MARK: - Card Analysis Helpers

    private func analyzeHand(_ deck: [CardSprite]) -> HandAnalysis {
        var numberCounts: [Int: [CardSprite]] = [:]
        var colorCounts: [Int: [CardSprite]] = [:]

        for card in deck {
            numberCounts[card.getNumber(), default: []].append(card)
            colorCounts[card.getColor(), default: []].append(card)
        }

        let quads = numberCounts.filter { $0.value.count >= 4 }
        let trips = numberCounts.filter { $0.value.count >= 3 }
        let pairs = numberCounts.filter { $0.value.count >= 2 }
        let flushPotential = colorCounts.filter { $0.value.count >= 4 }

        return HandAnalysis(
            numberCounts: numberCounts,
            colorCounts: colorCounts,
            quads: quads,
            trips: trips,
            pairs: pairs,
            flushPotential: flushPotential,
            sortedByNumber: deck.sorted { $0.getNumber() > $1.getNumber() }
        )
    }

    private struct HandAnalysis {
        let numberCounts: [Int: [CardSprite]]
        let colorCounts: [Int: [CardSprite]]
        let quads: [Int: [CardSprite]]
        let trips: [Int: [CardSprite]]
        let pairs: [Int: [CardSprite]]
        let flushPotential: [Int: [CardSprite]]
        let sortedByNumber: [CardSprite]

        var hasQuads: Bool { !quads.isEmpty }
        var hasTrips: Bool { !trips.isEmpty }
        var hasPairs: Bool { !pairs.isEmpty }
        var hasTwoPairs: Bool { pairs.count >= 2 }
        var hasFlushPotential: Bool { !flushPotential.isEmpty }
        var highCard: CardSprite? { sortedByNumber.first }

        var bestQuads: [CardSprite]? {
            quads.max(by: { $0.key < $1.key })?.value
        }

        var bestTrips: [CardSprite]? {
            trips.max(by: { $0.key < $1.key })?.value
        }

        var bestPair: [CardSprite]? {
            pairs.max(by: { $0.key < $1.key })?.value
        }

        var secondBestPair: [CardSprite]? {
            let sortedPairs = pairs.sorted { $0.key > $1.key }
            return sortedPairs.count >= 2 ? sortedPairs[1].value : nil
        }
    }

    // MARK: - ===================== EASY AI =====================

    private func selectEasy(deck: [CardSprite]) {
        // 30% chance to use Medium strategy
        if Double.random(in: 0...1) < easyToMediumChance {
            selectMedium(deck: deck)
            return
        }

        // Basic random selection: 1-3 cards
        let count = Int.random(in: 1...min(3, deck.count))
        let shuffled = deck.shuffled()
        let cardsToSelect = Array(shuffled.prefix(count))
        selectCardsAnimated(cardsToSelect)
    }

    private func chooseColumnEasy() -> Int {
        // 20% chance to use Medium strategy
        if Double.random(in: 0...1) < 0.20 {
            return chooseColumnMedium()
        }

        // Random available column
        var available: [Int] = []
        for col in 0..<7 {
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) == 0 {
                available.append(col)
            }
        }
        return available.randomElement() ?? 0
    }

    // MARK: - ===================== MEDIUM AI =====================

    private func selectMedium(deck: [CardSprite]) {
        // 30% chance to use Hard strategy
        if Double.random(in: 0...1) < mediumToHardChance {
            selectHard(deck: deck)
            return
        }

        let analysis = analyzeHand(deck)

        // Priority: Quads > Trips > Pairs > High Card
        if analysis.hasQuads, let quads = analysis.bestQuads {
            selectCardsAnimated(Array(quads.prefix(4)))
            return
        }

        if analysis.hasTrips, let trips = analysis.bestTrips {
            selectCardsAnimated(Array(trips.prefix(3)))
            return
        }

        if analysis.hasPairs, let pair = analysis.bestPair {
            selectCardsAnimated(Array(pair.prefix(2)))
            return
        }

        // No combination - select highest card
        if let highCard = analysis.highCard {
            selectCardsAnimated([highCard])
        }
    }

    private func chooseColumnMedium() -> Int {
        // 30% chance to use Hard strategy
        if Double.random(in: 0...1) < mediumToHardChance {
            return chooseColumnHard()
        }

        let selectedCards = DeckMgr.shared.getSelectedCards(player: humanPlayer)
        let opponentStrength = DeckMgr.shared.getBestOfCards(selectedCards)

        // Find available columns
        var availableColumns: [Int] = []
        for col in 0..<7 {
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) == 0 {
                availableColumns.append(col)
            }
        }

        guard !availableColumns.isEmpty else { return 0 }

        // Basic strategy: Avoid creating consecutive wins for opponent
        // Check if placing would give opponent 2 consecutive (dangerous!)
        for col in availableColumns {
            // Check neighbors
            let leftDangerous = col > 0 && isColumnWonByPlayer1(col - 1)
            let rightDangerous = col < 6 && isColumnWonByPlayer1(col + 1)

            // If this column would create 2 consecutive for player1, skip it
            if leftDangerous || rightDangerous {
                continue
            }

            // Check if we have cards here and can likely win
            let ourCards = DeckMgr.shared.getPokerDeck(player: 2, col: col)
            if !ourCards.isEmpty {
                let ourStrength = DeckMgr.shared.getBestOfCards(ourCards)
                if opponentStrength.rawValue <= ourStrength.rawValue {
                    return col
                }
            }
        }

        // Fallback: random from available
        return availableColumns.randomElement() ?? 0
    }

    private func isColumnWonByPlayer1(_ col: Int) -> Bool {
        let p1Cards = DeckMgr.shared.getPokerDeck(player: 1, col: col)
        let p2Cards = DeckMgr.shared.getPokerDeck(player: 2, col: col)
        guard !p1Cards.isEmpty && !p2Cards.isEmpty else { return false }
        return DeckMgr.shared.compareColumn(col) == .player1
    }

    // MARK: - ===================== HARD AI =====================

    private func selectHard(deck: [CardSprite]) {
        let analysis = analyzeHand(deck)
        let gameState = getGameState()

        // Decide: Normal play, Bluff, or Resource management
        let shouldBluff = shouldUseBluff(analysis: analysis, gameState: gameState)

        if shouldBluff {
            selectHardBluff(deck: deck, analysis: analysis)
        } else {
            selectHardNormal(deck: deck, analysis: analysis, gameState: gameState)
        }
    }

    private func shouldUseBluff(analysis: HandAnalysis, gameState: GameState) -> Bool {
        // Bluff conditions:
        // 1. Hand is weak (no pairs or only low pairs)
        // 2. Random chance kicks in
        // 3. Not in late game when we need real strength

        let hasWeakHand = !analysis.hasTrips && !analysis.hasQuads && !analysis.hasFlushPotential && !analysis.hasTwoPairs
        let randomBluff = Double.random(in: 0...1) < bluffChance

        // Don't bluff too much in late game
        if gameState.isLateGame && gameState.p2IsLosing {
            return false
        }

        return hasWeakHand && randomBluff
    }

    private func selectHardBluff(deck: [CardSprite], analysis: HandAnalysis) {
        // Bluff strategies - make opponent think we have better cards

        let bluffType = Int.random(in: 0...3)

        switch bluffType {
        case 0:
            // Fake pair: select 2 different cards
            if deck.count >= 2 {
                let shuffled = deck.shuffled()
                var selected: [CardSprite] = [shuffled[0]]
                for card in shuffled.dropFirst() {
                    if card.getNumber() != selected[0].getNumber() {
                        selected.append(card)
                        break
                    }
                }
                if selected.count == 2 {
                    selectCardsAnimated(selected)
                    return
                }
            }

        case 1:
            // Fake three of a kind: select 3 different cards
            if deck.count >= 3 {
                let shuffled = deck.shuffled()
                var selected: [CardSprite] = []
                var usedNumbers: Set<Int> = []
                for card in shuffled {
                    if !usedNumbers.contains(card.getNumber()) {
                        selected.append(card)
                        usedNumbers.insert(card.getNumber())
                        if selected.count == 3 { break }
                    }
                }
                if selected.count == 3 {
                    selectCardsAnimated(selected)
                    return
                }
            }

        case 2:
            // If we have a pair, add 1-2 random cards to fake trips/two-pairs
            if let pair = analysis.bestPair {
                var selected = Array(pair.prefix(2))
                let others = deck.filter { !selected.contains($0) }
                if !others.isEmpty {
                    let extraCount = Int.random(in: 1...min(2, others.count))
                    selected.append(contentsOf: others.shuffled().prefix(extraCount))
                    selectCardsAnimated(selected)
                    return
                }
            }

        case 3:
            // Fake four cards (could be two pairs or four of a kind)
            if deck.count >= 4 {
                let shuffled = deck.shuffled()
                selectCardsAnimated(Array(shuffled.prefix(4)))
                return
            }

        default:
            break
        }

        // Fallback to normal if bluff fails
        selectHardNormal(deck: deck, analysis: analysis, gameState: getGameState())
    }

    private func selectHardNormal(deck: [CardSprite], analysis: HandAnalysis, gameState: GameState) {
        // Strategic card selection based on game state

        // Late game or losing: play strongest hand
        if gameState.isLateGame || gameState.p2IsLosing {
            selectBestHand(analysis: analysis)
            return
        }

        // Early/Mid game: Resource management - don't waste best cards
        if gameState.isEarlyGame {
            if Double.random(in: 0...1) < bestHandChance/2.0 {
                selectBestHand(analysis: analysis)
            } else {
                selectConservative(deck: deck, analysis: analysis)
            }
            return
        }

        // Mid game: balanced approach
        if Double.random(in: 0...1) < bestHandChance {
            selectBestHand(analysis: analysis)
        } else {
            selectBalanced(deck: deck, analysis: analysis)
        }
    }


    private func selectBestHand(analysis: HandAnalysis) {
        // 撲克牌型優先級（從高到低）：
        // 1. 同花順 (Straight Flush)
        // 2. 四條 (Four of a Kind)
        // 3. 葫蘆 (Full House)
        // 4. 同花 (Flush)
        // 5. 順子 (Straight)
        // 6. 三條 (Three of a Kind)
        // 7. 兩對 (Two Pair)
        // 8. 一對 (One Pair)
        // 9. 高牌 (High Card)
        
        // 1. 檢查同花順 (Straight Flush)
        if let straightFlush = findStraightFlush(analysis: analysis) {
            selectCardsAnimated(straightFlush)
            return
        }
        
        // 2. 檢查四條 (Four of a Kind)
        if analysis.hasQuads, let quads = analysis.bestQuads {
            selectCardsAnimated(Array(quads.prefix(4)))
            return
        }
        
        // 3. 檢查葫蘆 (Full House) - 三條 + 一對
        if analysis.hasTrips, let trips = analysis.bestTrips {
            if let pair = analysis.pairs.first(where: { $0.key != trips.first?.getNumber() }) {
                var fullHouse = Array(trips.prefix(3))
                fullHouse.append(contentsOf: pair.value.prefix(2))
                selectCardsAnimated(fullHouse)
                return
            }
        }
        
        // 4. 檢查同花 (Flush) - 至少5張同色
        if let flush = findFlush(analysis: analysis) {
            selectCardsAnimated(flush)
            return
        }
        
        // 5. 檢查順子 (Straight) - 至少5張連續
        if let straight = findStraight(analysis: analysis) {
            selectCardsAnimated(straight)
            return
        }
        
        // 6. 檢查三條 (Three of a Kind)
        if analysis.hasTrips, let trips = analysis.bestTrips {
            selectCardsAnimated(Array(trips.prefix(3)))
            return
        }
        
        // 7. 檢查兩對 (Two Pair)
        if analysis.hasTwoPairs {
            let sortedPairs = analysis.pairs.sorted { $0.key > $1.key }
            var twoPairs: [CardSprite] = []
            twoPairs.append(contentsOf: sortedPairs[0].value.prefix(2))
            twoPairs.append(contentsOf: sortedPairs[1].value.prefix(2))
            selectCardsAnimated(twoPairs)
            return
        }
        
        // 8. 檢查一對 (One Pair)
        if analysis.hasPairs, let pair = analysis.bestPair {
            selectCardsAnimated(Array(pair.prefix(2)))
            return
        }
        
        // 9. 高牌 (High Card)
        if let highCard = analysis.highCard {
            selectCardsAnimated([highCard])
        }
    }

    // MARK: - Helper Functions for Card Combinations

    /// 尋找同花順 (Straight Flush) - 同色且連續的5張牌
    private func findStraightFlush(analysis: HandAnalysis) -> [CardSprite]? {
        // 對每種顏色檢查是否有順子
        for (_, cards) in analysis.colorCounts {
            if cards.count >= 5 {
                if let straight = findStraightInCards(cards) {
                    return straight
                }
            }
        }
        return nil
    }

    /// 尋找同花 (Flush) - 5張以上同色的牌
    private func findFlush(analysis: HandAnalysis) -> [CardSprite]? {
        // 找到最多同色的牌組
        if let bestFlush = analysis.colorCounts.max(by: { $0.value.count < $1.value.count }) {
            if bestFlush.value.count >= 5 {
                // 選擇最大的5張
                let sorted = bestFlush.value.sorted { $0.getNumber() > $1.getNumber() }
                return Array(sorted.prefix(5))
            }
        }
        return nil
    }

    /// 尋找順子 (Straight) - 5張連續的牌
    private func findStraight(analysis: HandAnalysis) -> [CardSprite]? {
        return findStraightInCards(analysis.sortedByNumber)
    }

    /// 在給定的牌中尋找順子
    private func findStraightInCards(_ cards: [CardSprite]) -> [CardSprite]? {
        guard cards.count >= 5 else { return nil }
        
        // 按數字排序並去重
        let sortedCards = cards.sorted { $0.getNumber() > $1.getNumber() }
        var uniqueCards: [CardSprite] = []
        var seenNumbers = Set<Int>()
        
        for card in sortedCards {
            if !seenNumbers.contains(card.getNumber()) {
                uniqueCards.append(card)
                seenNumbers.insert(card.getNumber())
            }
        }
        
        guard uniqueCards.count >= 5 else { return nil }
        
        // 檢查是否有5張連續的牌
        for i in 0...(uniqueCards.count - 5) {
            var consecutive: [CardSprite] = [uniqueCards[i]]
            
            for j in (i + 1)..<uniqueCards.count {
                let lastNumber = consecutive.last!.getNumber()
                let currentNumber = uniqueCards[j].getNumber()
                
                // 檢查是否連續（差1）
                if lastNumber - currentNumber == 1 {
                    consecutive.append(uniqueCards[j])
                    
                    if consecutive.count == 5 {
                        return consecutive
                    }
                } else if lastNumber - currentNumber > 1 {
                    // 不連續，跳出
                    break
                }
            }
        }
        
        // 特殊情況：A-2-3-4-5 (A 可以當作 1 使用)
        // 假設 A 的 number 是 14 或 1，根據你的遊戲規則調整
        if let aceCard = uniqueCards.first(where: { $0.getNumber() == 14 || $0.getNumber() == 1 }) {
            let lowNumbers = uniqueCards.filter { $0.getNumber() >= 2 && $0.getNumber() <= 5 }
            if lowNumbers.count >= 4 {
                let sorted = lowNumbers.sorted { $0.getNumber() < $1.getNumber() }
                // 檢查是否是 2-3-4-5
                if sorted.count >= 4 &&
                   sorted[0].getNumber() == 2 &&
                   sorted[1].getNumber() == 3 &&
                   sorted[2].getNumber() == 4 &&
                   sorted[3].getNumber() == 5 {
                    return [sorted[0], sorted[1], sorted[2], sorted[3], aceCard]
                }
            }
        }
        
        return nil
    }
    private func selectConservative(deck: [CardSprite], analysis: HandAnalysis) {
        // Early game: save strong cards, play medium strength

        // If we have trips, only play pair (save one)
        if analysis.hasTrips, let trips = analysis.bestTrips {
            selectCardsAnimated(Array(trips.prefix(2)))
            return
        }

        // If we have two pairs, only play one pair (save the other)
        if analysis.hasTwoPairs {
            let sortedPairs = analysis.pairs.sorted { $0.key > $1.key }
            // Play the weaker pair, save the stronger one
            selectCardsAnimated(Array(sortedPairs[1].value.prefix(2)))
            return
        }

        // Play pair if available
        if analysis.hasPairs, let pair = analysis.bestPair {
            selectCardsAnimated(Array(pair.prefix(2)))
            return
        }

        // Play medium card (not highest, not lowest)
        let sorted = analysis.sortedByNumber
        if sorted.count >= 3 {
            selectCardsAnimated([sorted[sorted.count / 2]])
        } else if let card = sorted.first {
            selectCardsAnimated([card])
        }
    }

    private func selectBalanced(deck: [CardSprite], analysis: HandAnalysis) {
        // Mid game: play good hands but don't overcommit

        if analysis.hasQuads, let quads = analysis.bestQuads {
            // Quads is too good to save, play it
            selectCardsAnimated(Array(quads.prefix(4)))
            return
        }

        if analysis.hasTrips, let trips = analysis.bestTrips {
            // Play full trips
            selectCardsAnimated(Array(trips.prefix(3)))
            return
        }

        if analysis.hasTwoPairs {
            // Play two pairs
            let sortedPairs = analysis.pairs.sorted { $0.key > $1.key }
            var twoPairs: [CardSprite] = []
            twoPairs.append(contentsOf: sortedPairs[0].value.prefix(2))
            twoPairs.append(contentsOf: sortedPairs[1].value.prefix(2))
            selectCardsAnimated(twoPairs)
            return
        }

        if analysis.hasPairs, let pair = analysis.bestPair {
            selectCardsAnimated(Array(pair.prefix(2)))
            return
        }

        if let highCard = analysis.highCard {
            selectCardsAnimated([highCard])
        }
    }

    // MARK: - Hard Column Placement Strategy

    private func chooseColumnHard() -> Int {
        let selectedCards = DeckMgr.shared.getSelectedCards(player: humanPlayer)
        let opponentStrength = DeckMgr.shared.getBestOfCards(selectedCards)
        let gameState = getGameState()

        // Find available columns
        var availableColumns: [Int] = []
        for col in 0..<7 {
            if DeckMgr.shared.getColumnSize(player: humanPlayer, col: col) == 0 {
                availableColumns.append(col)
            }
        }

        guard !availableColumns.isEmpty else { return 0 }

        // Priority 1: Block opponent's consecutive win threat
        if let blockingCol = findBlockingColumn(availableColumns: availableColumns, gameState: gameState) {
            return blockingCol
        }

        // Priority 2: If opponent is strong, place in column we've already lost (damage control)
        if opponentStrength.rawValue >= CardType.twoPair.rawValue {
            if let sacrificeCol = findSacrificeColumn(availableColumns: availableColumns) {
                return sacrificeCol
            }
        }

        // Priority 3: Place where we're strong (to secure win)
        if let strongCol = findStrongColumn(availableColumns: availableColumns, opponentStrength: opponentStrength) {
            return strongCol
        }

        // Priority 4: Build our consecutive win
        if let consecutiveCol = findConsecutiveBuildColumn(availableColumns: availableColumns, gameState: gameState) {
            return consecutiveCol
        }

        // Fallback: Strategic column placement based on opponent's card count
        let opponentCardCount = selectedCards.count
        
        if opponentCardCount >= 3 {
            // 對手出大牌（超過3張），prefer 放在角落減少損失
            // 優先選擇兩端的列（0 或 6），然後是次外圍（1 或 5）
            let cornerPreference = availableColumns.sorted {
                let dist1 = min($0, 6 - $0)  // 到最近邊緣的距離
                let dist2 = min($1, 6 - $1)
                return dist1 < dist2  // 距離越小（越靠邊）越優先
            }
            return cornerPreference.first ?? availableColumns.first ?? 0
        } else {
            // 對手出小牌（2張或以下），prefer 放在中間保持靈活性
            // 優先選擇中間列（3），然後是附近（2, 4），再外圍（1, 5），最後才是角落（0, 6）
            let middlePreference = availableColumns.sorted {
                abs($0 - 3) < abs($1 - 3)
            }
            return middlePreference.first ?? availableColumns.first ?? 0
        }
    }

    private func findBlockingColumn(availableColumns: [Int], gameState: GameState) -> Int? {
        // Find column that would give player1 2 consecutive wins (dangerous!)

        for col in availableColumns {
            var consecutiveIfPlaced = 0

            // Check left side
            var checkCol = col - 1
            while checkCol >= 0 {
                if isColumnWonByPlayer1(checkCol) || (DeckMgr.shared.getColumnSize(player: 1, col: checkCol) > 0 && DeckMgr.shared.getColumnSize(player: 2, col: checkCol) == 0) {
                    consecutiveIfPlaced += 1
                    checkCol -= 1
                } else {
                    break
                }
            }

            // Check right side
            checkCol = col + 1
            while checkCol < 7 {
                if isColumnWonByPlayer1(checkCol) || (DeckMgr.shared.getColumnSize(player: 1, col: checkCol) > 0 && DeckMgr.shared.getColumnSize(player: 2, col: checkCol) == 0) {
                    consecutiveIfPlaced += 1
                    checkCol += 1
                } else {
                    break
                }
            }

            // If placing here would NOT give opponent consecutive advantage, prefer other columns
            if consecutiveIfPlaced >= 1 {
                // This column is dangerous for opponent's consecutive - avoid it
                // But we WANT to avoid helping them, so this is good to place elsewhere
                continue
            }
        }

        // Actually, we want to place in columns that DON'T help opponent's consecutive
        // Return nil to use other strategies
        return nil
    }

    private func findSacrificeColumn(availableColumns: [Int]) -> Int? {
        // Find column where we've already lost or are weak

        for col in availableColumns {
            let ourCards = DeckMgr.shared.getPokerDeck(player: 2, col: col)

            if ourCards.isEmpty {
                continue // No cards yet, not a sacrifice
            }

            let ourStrength = DeckMgr.shared.getBestOfCards(ourCards)

            // If our strength is low, this is a good sacrifice column
            if ourStrength.rawValue <= CardType.onePair.rawValue {
                return col
            }
        }

        return nil
    }

    private func findStrongColumn(availableColumns: [Int], opponentStrength: CardType) -> Int? {
        // Find column where we're likely to win

        var bestCol: Int?
        var bestDiff = Int.min

        for col in availableColumns {
            let ourCards = DeckMgr.shared.getPokerDeck(player: 2, col: col)

            if ourCards.isEmpty {
                continue
            }

            let ourStrength = DeckMgr.shared.getBestOfCards(ourCards)
            let diff = ourStrength.rawValue - opponentStrength.rawValue

            if diff > bestDiff {
                bestDiff = diff
                bestCol = col
            }
        }

        // Only return if we're actually stronger
        if bestDiff > 0 {
            return bestCol
        }

        return nil
    }

    private func findConsecutiveBuildColumn(availableColumns: [Int], gameState: GameState) -> Int? {
        // Find column that helps build our consecutive wins

        for col in availableColumns {
            // Check if adjacent columns are won by us
            let leftWon = col > 0 && isColumnWonByPlayer2(col - 1)
            let rightWon = col < 6 && isColumnWonByPlayer2(col + 1)

            if leftWon || rightWon {
                // Check if we have cards here and can likely win
                let ourCards = DeckMgr.shared.getPokerDeck(player: 2, col: col)
                if !ourCards.isEmpty {
                    return col
                }
            }
        }

        return nil
    }

    private func isColumnWonByPlayer2(_ col: Int) -> Bool {
        let p1Cards = DeckMgr.shared.getPokerDeck(player: 1, col: col)
        let p2Cards = DeckMgr.shared.getPokerDeck(player: 2, col: col)
        guard !p1Cards.isEmpty && !p2Cards.isEmpty else { return false }
        return DeckMgr.shared.compareColumn(col) == .player2
    }
}
