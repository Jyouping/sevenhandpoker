//
//  GameScene.swift
//  Seven Hand Poker
//
//  Main game scene using SpriteKit with State Machine pattern
//

import SpriteKit

// MARK: - Game State Machine

enum GamePhase {
    case idle               // Waiting to start
    case dealing            // Dealing cards
    case player1Selecting   // Player1 selecting cards
    case player1Confirming  // Player1 confirming selection
    case player1Waiting     // Waiting for AI to place player1's cards
    case player2Selecting   // AI selecting cards
    case player2Placing     // Player1 placing player2's cards
    case comparing          // Comparing cards in a column
    case checkingWin        // Checking win condition
    case gameOver           // Game ended
}

class GameScene: SKScene, CardSpriteDelegate, DeckConfirmationDelegate {

    // MARK: - Properties

    private var deckMgr: DeckMgr!
    private var computerAI: ComputerAI!

    // State Machine
    private var currentPhase: GamePhase = .idle {
        didSet {
            handlePhaseChange(from: oldValue, to: currentPhase)
        }
    }
    private var pendingColumn: Int = -1  // Column waiting to be compared

    // Coin ownership: nil = unclaimed, player1/player2 = owned
    private var coinOwners: [PlayerType?] = Array(repeating: nil, count: 7)
    private var coinSprites: [SKSpriteNode] = []

    // UI Elements
    private var backgroundNode: SKSpriteNode!
    private var commonDeckNode: SKSpriteNode!
    private var slotNodes: [SKSpriteNode] = []
    private var placeButtons: [SKSpriteNode] = []

    // Confirmation view
    private var confirmationView: DeckConfirmationView?

    // Buttons
    private var submitButton: SKSpriteNode!
    private var sortButton: SKSpriteNode!
    private var dealButton: SKSpriteNode!

    // Labels
    private var messageLabel: SKLabelNode!
    private var p1ScoreLabel: SKLabelNode!
    private var p2ScoreLabel: SKLabelNode!

    // Card layout constants
    private let cardScale: CGFloat = 0.95
    private let slotSpacing: CGFloat = 120

    // Player positions
    private let p1HandY: CGFloat = 80
    private let p2HandY: CGFloat = 560
    private let p1PokerY: CGFloat = 220
    private let p2PokerY: CGFloat = 420

    private var lastSortType: Int = 0

    // MARK: - Scene Setup

    class func newGameScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 1400, height: 640))
        scene.scaleMode = .aspectFit
        return scene
    }

    override func didMove(to view: SKView) {
        deckMgr = DeckMgr.shared
        computerAI = ComputerAI.shared

        setupBackground()
        setupSlots()
        setupCoins()
        setupButtons()
        setupLabels()
        setupCommonDeck()

        currentPhase = .idle
    }

    // MARK: - State Machine Handler

    private func handlePhaseChange(from oldPhase: GamePhase, to newPhase: GamePhase) {
        print("Phase: \(oldPhase) -> \(newPhase)")

        switch newPhase {
        case .idle:
            onEnterIdle()
        case .dealing:
            onEnterDealing()
        case .player1Selecting:
            onEnterPlayer1Selecting()
        case .player1Confirming:
            break // Handled by showConfirmationView
        case .player1Waiting:
            onEnterPlayer1Waiting()
        case .player2Selecting:
            onEnterPlayer2Selecting()
        case .player2Placing:
            onEnterPlayer2Placing()
        case .comparing:
            onEnterComparing()
        case .checkingWin:
            onEnterCheckingWin()
        case .gameOver:
            onEnterGameOver()
        }
    }

    // MARK: - State Entry Handlers

    private func onEnterIdle() {
        showMessage("Tap DEAL to start")
        dealButton.isHidden = false
        submitButton.isHidden = true
        sortButton.isHidden = true
        hidePlaceButtons()
    }

    private func onEnterDealing() {
        dealButton.isHidden = true
        dealCards()
    }

    private func onEnterPlayer1Selecting() {
        // Enable player1's cards for selection
        for card in deckMgr.player1Hand {
            card.setEnabled(true)
        }

        sortButton.isHidden = false
        submitButton.isHidden = false
        showMessage("Select 1-5 cards")
    }

    private func onEnterPlayer1Waiting() {
        // Disable player1's cards
        for card in deckMgr.player1Hand {
            card.setEnabled(false)
        }

        showMessage("CPU choosing position...")

        // AI places player1's cards
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.aiPlacePlayer1Cards()
            }
        ]))
    }

    private func onEnterPlayer2Selecting() {
        // AI selects cards
        computerAI.selectCards()

        let selected = deckMgr.getSelectedCards(player: 2)

        showMessage("CPU plays \(selected.count) card(s)")

        // Wait then proceed to player placing
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Flip cards back
                for card in selected {
                    card.setFaceUp(false)
                }
                self.currentPhase = .player2Placing
            }
        ]))
    }

    private func onEnterPlayer2Placing() {
        showPlaceButtons(forPlayer: 2)
        showMessage("Choose where to place CPU's cards")
    }

    private func onEnterComparing() {
        guard pendingColumn >= 0 else {
            proceedToNextTurn()
            return
        }

        compareColumn(pendingColumn)
    }

    private func onEnterCheckingWin() {
        checkWinCondition()
    }

    private func onEnterGameOver() {
        dealButton.isHidden = false
        submitButton.isHidden = true
        sortButton.isHidden = true
        hidePlaceButtons()
    }

    // MARK: - Setup Methods

    private func setupBackground() {
        backgroundNode = SKSpriteNode(imageNamed: "boardBG")
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        backgroundNode.size = size
        addChild(backgroundNode)
    }

    private func setupCommonDeck() {
        commonDeckNode = SKSpriteNode(imageNamed: "cardback")
        commonDeckNode.position = CGPoint(x: size.width / 2 - 500, y: size.height / 2)
        commonDeckNode.zPosition = 5

        let slot = SKSpriteNode(imageNamed: "slot")
        slot.size = CGSize(width: 100, height: 125)
        slot.position = commonDeckNode.position
        slot.zPosition = 1
        slot.name = "slot_commonDeck"
        addChild(slot)
        slotNodes.append(slot)

        addChild(commonDeckNode)
    }

    private func setupSlots() {
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2

        for i in 0..<14 {
            let col = i % 7
            let row = i / 7  // 0 = player2 (top), 1 = player1 (bottom)

            let x = startX + CGFloat(col) * slotSpacing
            let y = row == 0 ? p2PokerY : p1PokerY

            let slot = SKSpriteNode(imageNamed: "slot")
            slot.size = CGSize(width: 90, height: 120)
            slot.position = CGPoint(x: x, y: y)
            slot.zPosition = 1
            slot.name = "slot_\(i)"
            addChild(slot)
            slotNodes.append(slot)
        }
    }

    private func setupCoins() {
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2

        for i in 0..<7 {
            let x = startX + CGFloat(i) * slotSpacing
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.size = CGSize(width: 80, height: 80)
            coin.position = CGPoint(x: x, y: size.height / 2)
            coin.zPosition = 50
            coin.name = "coin_\(i)"
            addChild(coin)
            coinSprites.append(coin)
        }
    }

    private func setupButtons() {
        // Deal button
        dealButton = createButton(text: "DEAL", color: .systemGreen)
        dealButton.position = CGPoint(x: size.width / 2, y: 50)
        dealButton.name = "dealButton"
        dealButton.zPosition = 100
        addChild(dealButton)

        // Submit button
        submitButton = createButton(text: "SUBMIT", color: .systemBlue)
        submitButton.position = CGPoint(x: size.width / 2 + 150, y: 50)
        submitButton.name = "submitButton"
        submitButton.isHidden = true
        submitButton.zPosition = 100
        addChild(submitButton)

        // Sort button
        sortButton = createButton(text: "SORT", color: .systemOrange)
        sortButton.position = CGPoint(x: size.width / 2 - 150, y: 50)
        sortButton.name = "sortButton"
        sortButton.isHidden = true
        sortButton.zPosition = 100
        addChild(sortButton)

        // Place buttons
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        for i in 0..<7 {
            let btn = SKSpriteNode(imageNamed: "placement_btn")
            btn.size = CGSize(width: 80, height: 100)
            btn.position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: p2PokerY)
            btn.name = "placeBtn_\(i)"
            btn.isHidden = true
            btn.zPosition = 100
            addChild(btn)
            placeButtons.append(btn)
        }
    }

    private func setupLabels() {
        messageLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        messageLabel.fontSize = 24
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.zPosition = 100
        addChild(messageLabel)

        p1ScoreLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        p1ScoreLabel.fontSize = 20
        p1ScoreLabel.fontColor = .yellow
        p1ScoreLabel.position = CGPoint(x: 80, y: p1HandY)
        p1ScoreLabel.zPosition = 10
        p1ScoreLabel.text = "You: 0"
        addChild(p1ScoreLabel)

        p2ScoreLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        p2ScoreLabel.fontSize = 20
        p2ScoreLabel.fontColor = .cyan
        p2ScoreLabel.position = CGPoint(x: 80, y: p2HandY)
        p2ScoreLabel.zPosition = 10
        p2ScoreLabel.text = "CPU: 0"
        addChild(p2ScoreLabel)
    }

    private func createButton(text: String, color: UIColor, size: CGSize = CGSize(width: 100, height: 44)) -> SKSpriteNode {
        let button = SKSpriteNode(color: color, size: size)
        button.zPosition = 20

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = "label"
        button.addChild(label)

        return button
    }

    // MARK: - Game Flow

    private func startNewGame() {
        // Reset deck manager
        deckMgr.initDeck()
        coinOwners = Array(repeating: nil, count: 7)

        // Remove old cards
        for card in deckMgr.player1Hand { card.removeFromParent() }
        for card in deckMgr.player2Hand { card.removeFromParent() }
        for col in 0..<7 {
            for card in deckMgr.p1Poker[col] { card.removeFromParent() }
            for card in deckMgr.p2Poker[col] { card.removeFromParent() }
        }

        // Reset coins
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        for i in 0..<7 {
            coinSprites[i].position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: size.height / 2)
            coinSprites[i].alpha = 1.0
        }

        updateScores()
        currentPhase = .dealing
    }

    private func dealCards() {
        var delay: TimeInterval = 0
        let dealInterval: TimeInterval = 0.2

        // Deal 14 cards to each player
        for i in 0..<14 {
            // Player 1 card (face up)
            let p1Card = deckMgr.drawCardSprite(owner: 1, faceUp: true)
            p1Card.setScale(cardScale)
            p1Card.position = commonDeckNode.position
            p1Card.zPosition = CGFloat(10)
            p1Card.delegate = self
            addChild(p1Card)

            let p1TargetX = getCardX(index: i, total: 14)
            let p1Move = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.move(to: CGPoint(x: p1TargetX, y: p1HandY), duration: 0.2),
                SKAction.run { p1Card.zPosition = CGFloat(10 + i) }
            ])
            p1Card.run(p1Move)

            // Player 2 card (face down)
            let p2Card = deckMgr.drawCardSprite(owner: 2, faceUp: false)
            p2Card.setScale(cardScale)
            p2Card.position = commonDeckNode.position
            p2Card.zPosition = CGFloat(10 + i)
            p2Card.delegate = self
            addChild(p2Card)

            let p2TargetX = getCardX(index: i, total: 14)
            let p2Move = SKAction.sequence([
                SKAction.wait(forDuration: delay + 0.05),
                SKAction.move(to: CGPoint(x: p2TargetX, y: p2HandY), duration: 0.2)
            ])
            p2Card.run(p2Move)

            delay += dealInterval
        }

        // After dealing, start player1's turn
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay + 0.5),
            SKAction.run { [weak self] in
                self?.currentPhase = .player1Selecting
            }
        ]))
    }

    //get card x based on its index
    //todo: fix spacing
    private func getCardX(index: Int, total: Int) -> CGFloat {
        let spacing: CGFloat = min(50, (size.width - 150) / CGFloat(total))
        let totalWidth = CGFloat(total - 1) * spacing
        let startX = (size.width - totalWidth) / 2
        return startX + CGFloat(index) * spacing
    }

    // MARK: - Player 1 Actions

    private func player1Submit() {
        let selected = deckMgr.getSelectedCards(player: 1)
        guard selected.count >= 1 && selected.count <= 5 else {
            showMessage("Select 1-5 cards!")
            return
        }

        currentPhase = .player1Confirming
        showConfirmationView(for: selected)
    }

    private func showConfirmationView(for cards: [CardSprite]) {
        confirmationView?.removeFromParent()

        let confirmation = DeckConfirmationView(sceneSize: size)
        confirmation.delegate = self

        let cardType = deckMgr.getBestOfCards(cards)
        confirmation.showCards(cards, cardType: cardType)

        addChild(confirmation)
        confirmationView = confirmation

        submitButton.isHidden = true
        sortButton.isHidden = true
    }

    // MARK: - DeckConfirmationDelegate

    func confirmationDidConfirm() {
        confirmationView?.removeFromParent()
        confirmationView = nil

        currentPhase = .player1Waiting
    }

    func confirmationDidCancel() {
        confirmationView?.removeFromParent()
        confirmationView = nil

        // Return to selecting
        submitButton.isHidden = false
        sortButton.isHidden = false
        currentPhase = .player1Selecting
    }

    // MARK: - AI Actions

    private func aiPlacePlayer1Cards() {
        let col = computerAI.chooseColumnForOpponent()
        placeCardsToColumn(player: 1, col: col)
    }

    // MARK: - Card Placement

    private func showPlaceButtons(forPlayer placer: Int) {
        for i in 0..<7 {
            let placerDeckSize = deckMgr.getColumnSize(player: placer, col: i)
            placeButtons[i].isHidden = (placerDeckSize > 0)
        }
    }

    private func hidePlaceButtons() {
        for btn in placeButtons {
            btn.isHidden = true
        }
    }

    private func placeCardsToColumn(player: Int, col: Int) {
        hidePlaceButtons()

        let selected = deckMgr.removeSelectedFromHand(player: player)
        let cardsPlaced = selected.count
        print("Placing \(cardsPlaced) cards for Player \(player) to column \(col)")

        deckMgr.placeCards(selected, toColumn: col, player: player)
        print("Column col: \(col), size \(deckMgr.getColumnSize(player: player, col: col))")

        // Animate cards to slot
        let slotX = (size.width - 6 * slotSpacing) / 2 + CGFloat(col) * slotSpacing
        let slotY = player == 1 ? p1PokerY : p2PokerY

        for (i, card) in selected.enumerated() {
            let deltaY: Double = player == 1 ? -9 : 9
            let targetPos = CGPoint(x: slotX + CGFloat(i) * 3, y: slotY + CGFloat(i) * deltaY)
            card.setFaceUp(false)
            card.moveTo(position: targetPos, duration: 0.3)
            card.zPosition = CGFloat(20 + i)
        }

        // Draw new cards
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                self?.drawNewCards(forPlayer: player, count: 3)
            }
        ]))

        // Check column completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                if self.deckMgr.isColumnFull(col: col) {
                    self.pendingColumn = col
                    self.currentPhase = .comparing
                } else {
                    self.proceedToNextTurn()
                }
            }
        ]))
    }

    private func drawNewCards(forPlayer player: Int, count: Int) {
        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let faceUp = player == 1
        let y = player == 1 ? p1HandY : p2HandY

        rearrangeHand(player: player)

        var cardsDrawn = 0
        for i in 0..<count {
            guard deckMgr.canDrawCard() else { break }

            let newCard = deckMgr.drawCardSprite(owner: player, faceUp: faceUp)
            newCard.setScale(cardScale)
            newCard.position = commonDeckNode.position
            newCard.zPosition = CGFloat(10 + hand.count + i)
            newCard.delegate = self
            addChild(newCard)

            cardsDrawn += 1
        }

        if cardsDrawn > 0 {
            rearrangeHand(player: player)
        }
    }

    private func rearrangeHand(player: Int) {
        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let y = player == 1 ? p1HandY : p2HandY

        for (i, card) in hand.enumerated() {
            let x = getCardX(index: i, total: hand.count)
            card.moveTo(position: CGPoint(x: x, y: y), duration: 0.2)
            card.zPosition = CGFloat(10 + i)
        }
    }

    // MARK: - Comparison & Win Check

    private func compareColumn(_ col: Int) {
        let winner = deckMgr.compareColumn(col)
        let p1Cards = deckMgr.getPokerDeck(player: 1, col: col)
        let p2Cards = deckMgr.getPokerDeck(player: 2, col: col)

        // Reveal all cards in column
        for card in p1Cards { card.setFaceUp(true) }
        for card in p2Cards { card.setFaceUp(true) }

        let p1Type = deckMgr.getBestOfCards(p1Cards)
        let p2Type = deckMgr.getBestOfCards(p2Cards)

        var message = ""
        switch winner {
        case .player1:
            message = "You win! (\(p1Type.displayName) vs \(p2Type.displayName))"
            coinOwners[col] = .player1
            moveCoin(col: col, toPlayer: .player1)
        case .player2:
            message = "CPU wins! (\(p2Type.displayName) vs \(p1Type.displayName))"
            coinOwners[col] = .player2
            moveCoin(col: col, toPlayer: .player2)
        case .even:
            message = "Tie! (\(p1Type.displayName))"
        default:
            break
        }

        showMessage(message)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.pendingColumn = -1
                self?.currentPhase = .checkingWin
            }
        ]))
    }

    private func moveCoin(col: Int, toPlayer player: PlayerType) {
        let coin = coinSprites[col]
        let targetY: CGFloat = player == .player1 ? p1PokerY : p2PokerY
        coin.run(SKAction.moveTo(y: targetY, duration: 0.3))
        updateScores()
    }

    private func updateScores() {
        let p1Score = coinOwners.filter { $0 == .player1 }.count
        let p2Score = coinOwners.filter { $0 == .player2 }.count

        p1ScoreLabel.text = "You: \(p1Score)"
        p2ScoreLabel.text = "CPU: \(p2Score)"
    }

    private func checkWinCondition() {
        let p1Score = coinOwners.filter { $0 == .player1 }.count
        let p2Score = coinOwners.filter { $0 == .player2 }.count

        // Check consecutive wins
        var p1Consecutive = 0, p2Consecutive = 0
        var maxP1Consecutive = 0, maxP2Consecutive = 0

        for owner in coinOwners {
            if owner == .player1 {
                p1Consecutive += 1
                p2Consecutive = 0
                maxP1Consecutive = max(maxP1Consecutive, p1Consecutive)
            } else if owner == .player2 {
                p2Consecutive += 1
                p1Consecutive = 0
                maxP2Consecutive = max(maxP2Consecutive, p2Consecutive)
            } else {
                p1Consecutive = 0
                p2Consecutive = 0
            }
        }

        // Win conditions: 4 coins or 3 consecutive
        if p1Score >= 4 || maxP1Consecutive >= 3 {
            showMessage("YOU WIN!")
            currentPhase = .gameOver
            return
        }

        if p2Score >= 4 || maxP2Consecutive >= 3 {
            showMessage("CPU WINS!")
            currentPhase = .gameOver
            return
        }

        // Check if all columns filled
        var allFilled = true
        for i in 0..<7 {
            if !deckMgr.isColumnFull(col: i) {
                allFilled = false
                break
            }
        }

        if allFilled {
            if p1Score > p2Score {
                showMessage("YOU WIN! (\(p1Score) - \(p2Score))")
            } else if p2Score > p1Score {
                showMessage("CPU WINS! (\(p2Score) - \(p1Score))")
            } else {
                showMessage("TIE GAME!")
            }
            currentPhase = .gameOver
            return
        }

        proceedToNextTurn()
    }

    private func proceedToNextTurn() {
        let p1HandEmpty = deckMgr.player1Hand.isEmpty
        let p2HandEmpty = deckMgr.player2Hand.isEmpty

        if p1HandEmpty && p2HandEmpty {
            currentPhase = .checkingWin
            return
        }

        // Alternate turns based on current phase
        if currentPhase == .player1Waiting || currentPhase == .comparing || currentPhase == .checkingWin {
            if !p2HandEmpty {
                currentPhase = .player2Selecting
            } else if !p1HandEmpty {
                currentPhase = .player1Selecting
            } else {
                currentPhase = .checkingWin
            }
        } else if currentPhase == .player2Placing {
            if !p1HandEmpty {
                currentPhase = .player1Selecting
            } else if !p2HandEmpty {
                currentPhase = .player2Selecting
            } else {
                currentPhase = .checkingWin
            }
        } else {
            // Default: player1's turn
            currentPhase = .player1Selecting
        }
    }

    // MARK: - UI Helpers

    private func showMessage(_ text: String) {
        messageLabel.text = text
        messageLabel.alpha = 1.0
        messageLabel.removeAllActions()
        messageLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
    }

    private func sortPlayerHand() {
        lastSortType = (lastSortType + 1) % 2
        deckMgr.sortHand(player: 1, byNumber: lastSortType == 0)
        rearrangeHand(player: 1)
    }

    // MARK: - CardSpriteDelegate

    func cardClicked(_ card: CardSprite) {
        guard currentPhase == .player1Selecting else { return }
        let selectedCount = deckMgr.getSelectedCards(player: 1).count
        submitButton.isHidden = (selectedCount == 0 || selectedCount > 5)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            guard let name = node.name ?? node.parent?.name else { continue }

            if name == "dealButton" && !dealButton.isHidden {
                startNewGame()
            } else if name == "submitButton" && !submitButton.isHidden && currentPhase == .player1Selecting {
                player1Submit()
            } else if name == "sortButton" && !sortButton.isHidden {
                sortPlayerHand()
            } else if name.hasPrefix("placeBtn_") && currentPhase == .player2Placing {
                if let col = Int(name.replacingOccurrences(of: "placeBtn_", with: "")) {
                    placeCardsToColumn(player: 2, col: col)
                }
            }
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        // Game loop updates if needed
    }
}
