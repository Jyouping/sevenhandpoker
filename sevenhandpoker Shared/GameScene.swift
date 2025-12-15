//
//  GameScene.swift
//  Seven Hand Poker
//
//  Main game scene using SpriteKit
//

import SpriteKit

class GameScene: SKScene, CardSpriteDelegate, DeckConfirmationDelegate {

    // MARK: - Properties

    private var deckMgr: DeckMgr!
    private var gameState: GameState = .idle
    private var currentPlayer: PlayerType = .player1

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

    // Card layout
    private let cardScale: CGFloat = 0.95
    private let cardWidth: CGFloat = 42
    private let cardHeight: CGFloat = 60
    private let slotSpacing: CGFloat = 120

    // Player positions
    private let p1HandY: CGFloat = 90
    private let p2HandY: CGFloat = 550
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

        setupBackground()
        setupSlots()
        setupCoins()
        setupButtons()
        setupLabels()
        setupCommonDeck()

        showMessage("Tap DEAL to start")
    }

    // MARK: - Setup Methods

    func setupBackground() {
        backgroundNode = SKSpriteNode(imageNamed: "boardBG")
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        // Scale to fill entire screen
        backgroundNode.size = size
        addChild(backgroundNode)
    }
    
    func setupCommonDeck() {
        commonDeckNode = SKSpriteNode(imageNamed: "cardback")
        commonDeckNode.position = CGPoint(x: size.width / 2 - 500, y: size.height / 2)
        commonDeckNode.zPosition = 5
        let slot = SKSpriteNode(imageNamed: "slot")
        slot.size = CGSize(width: 100, height: 125)
        slot.position = CGPoint(x: commonDeckNode.position.x, y: commonDeckNode.position.y)
        slot.zPosition = 1
        slot.name = "slot_commonDeck"
        addChild(slot)
        slotNodes.append(slot)

        addChild(commonDeckNode)
    }

    
    func setupSlots() {
        // Create 14 slots (7 for each player)
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

    func setupCoins() {
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2

        for i in 0..<7 {
            let x = startX + CGFloat(i) * slotSpacing
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.size = CGSize(width: 80, height: 80)
            coin.position = CGPoint(x: x, y: size.height / 2)
            coin.zPosition = 5
            coin.name = "coin_\(i)"
            addChild(coin)
            coinSprites.append(coin)
        }
    }

    func setupButtons() {
        // Deal button
        dealButton = createButton(text: "DEAL", color: .systemGreen)
        dealButton.position = CGPoint(x: size.width / 2, y: 50)
        dealButton.name = "dealButton"
        addChild(dealButton)

        // Submit button
        submitButton = createButton(text: "SUBMIT", color: .systemBlue)
        submitButton.position = CGPoint(x: size.width / 2 + 150, y: 50)
        submitButton.name = "submitButton"
        submitButton.isHidden = true
        addChild(submitButton)

        // Sort button
        sortButton = createButton(text: "SORT", color: .systemOrange)
        sortButton.position = CGPoint(x: size.width / 2 - 150, y: 50)
        sortButton.name = "sortButton"
        sortButton.isHidden = true
        addChild(sortButton)

        // Place buttons (for choosing column)
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        for i in 0..<7 {
            let btn = createButton(text: "\(i+1)", color: .systemPurple, size: CGSize(width: 60, height: 40))
            btn.position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: size.height / 2)
            btn.name = "placeBtn_\(i)"
            btn.isHidden = true
            btn.zPosition = 50
            addChild(btn)
            placeButtons.append(btn)
        }
    }

    func setupLabels() {
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

    func createButton(text: String, color: UIColor, size: CGSize = CGSize(width: 100, height: 44)) -> SKSpriteNode {
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

    func startNewGame() {
        // Reset everything
        deckMgr.initDeck()
        coinOwners = Array(repeating: nil, count: 7)

        // Remove old cards
        for card in deckMgr.player1Hand { card.removeFromParent() }
        for card in deckMgr.player2Hand { card.removeFromParent() }
        for col in 0..<7 {
            for card in deckMgr.p1Poker[col] { card.removeFromParent() }
            for card in deckMgr.p2Poker[col] { card.removeFromParent() }
        }

        // Reset coins position
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        for i in 0..<7 {
            coinSprites[i].position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: size.height / 2)
            coinSprites[i].alpha = 1.0
        }

        // Deal cards
        dealCards()
    }

    func dealCards() {
        gameState = .dealing
        dealButton.isHidden = true

        var delay: TimeInterval = 0
        let dealInterval: TimeInterval = 0.2

        // Deal 14 cards to each player
        for i in 0..<14 {
            // Player 1 card (face up)
            let p1Card = deckMgr.drawCardSprite(owner: 1, faceUp: true)
            p1Card.setScale(cardScale)
            p1Card.position = commonDeckNode.position
            p1Card.zPosition = CGFloat(CGFloat(10))
            p1Card.delegate = self
            addChild(p1Card)

            let p1TargetX = getCardX(index: i, total: 14)
            let p1Move = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.move(to: CGPoint(x: p1TargetX, y: p1HandY), duration: 0.2),
                SKAction.run{ p1Card.zPosition = CGFloat(10 + i) }
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
                self?.startPlayer1Turn()
            }
        ]))
    }

    func getCardX(index: Int, total: Int) -> CGFloat {
        let spacing: CGFloat = min(60, (size.width - 200) / CGFloat(total))
        let totalWidth = CGFloat(total - 1) * spacing
        let startX = (size.width - totalWidth) / 2
        return startX + CGFloat(index) * spacing
    }

    func startPlayer1Turn() {
        gameState = .player1Turn
        currentPlayer = .player1

        // Enable player1's cards
        for card in deckMgr.player1Hand {
            card.setEnabled(true)
        }

        sortButton.isHidden = false
        submitButton.isHidden = false
        showMessage("Select 1-5 cards")
    }

    func startPlayer2Turn() {
        gameState = .player2Turn
        currentPlayer = .player2

        // Simple AI: select random 1-3 cards
        let hand = deckMgr.player2Hand
        let selectCount = min(hand.count, Int.random(in: 1...3))

        // AI strategy: prefer pairs
        aiSelectCards(count: selectCount)

        // Wait then proceed to placing
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.player2SubmitCards()
            }
        ]))
    }

    func aiSelectCards(count: Int) {
        let hand = deckMgr.player2Hand
        guard !hand.isEmpty else { return }

        // Look for pairs first
        var counts: [Int: [CardSprite]] = [:]
        for card in hand {
            counts[card.getNumber(), default: []].append(card)
        }

        var selected: [CardSprite] = []

        // Select pairs/trips if available
        for (_, cards) in counts.sorted(by: { $0.key > $1.key }) {
            if cards.count >= 2 && selected.count < count {
                for card in cards.prefix(min(cards.count, count - selected.count)) {
                    card.setSelected(true)
                    selected.append(card)
                }
                if selected.count >= count { break }
            }
        }

        // Fill remaining with high cards
        if selected.count < count {
            let remaining = hand.filter { !$0.getSelected() }.sorted { $0.getNumber() > $1.getNumber() }
            for card in remaining.prefix(count - selected.count) {
                card.setSelected(true)
            }
        }
    }

    func player1SubmitCards() {
        let selected = deckMgr.getSelectedCards(player: 1)
        guard selected.count >= 1 && selected.count <= 5 else {
            showMessage("Select 1-5 cards!")
            return
        }

        // Show confirmation view
        showConfirmationView(for: selected)
    }

    func showConfirmationView(for cards: [CardSprite]) {
        // Remove existing confirmation view if any
        confirmationView?.removeFromParent()

        // Create new confirmation view
        let confirmation = DeckConfirmationView(sceneSize: size)
        confirmation.delegate = self

        // Calculate card type
        let cardType = deckMgr.getBestOfCards(cards)
        confirmation.showCards(cards, cardType: cardType)

        addChild(confirmation)
        confirmationView = confirmation

        // Hide buttons while confirmation is showing
        submitButton.isHidden = true
        sortButton.isHidden = true
    }

    // MARK: - DeckConfirmationDelegate

    func confirmationDidConfirm() {
        // Remove confirmation view
        confirmationView?.removeFromParent()
        confirmationView = nil

        // Proceed with submission
        gameState = .player1Placing

        // Disable cards
        for card in deckMgr.player1Hand {
            card.setEnabled(false)
        }

        // Show place buttons for empty columns where player2 hasn't placed
        showPlaceButtons(forPlayer: 2)  // Player2 places player1's cards
        showMessage("CPU choosing position...")

        // AI chooses position
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.aiPlaceCards(forPlayer: 1)
            }
        ]))
    }

    func confirmationDidCancel() {
        // Remove confirmation view
        confirmationView?.removeFromParent()
        confirmationView = nil

        // Show buttons again
        submitButton.isHidden = false
        sortButton.isHidden = false

        // Player can continue selecting
        showMessage("Select 1-5 cards")
    }

    func player2SubmitCards() {
        gameState = .player2Placing
        showPlaceButtons(forPlayer: 1)  // Player1 places player2's cards
        showMessage("Choose where to place CPU's cards")
    }

    func showPlaceButtons(forPlayer placer: Int) {
        for i in 0..<7 {
            // Show button only if the placer hasn't already placed there
            let placerDeckSize = deckMgr.getDeckSize(player: placer, col: i)
            placeButtons[i].isHidden = (placerDeckSize > 0)
        }
    }

    func hidePlaceButtons() {
        for btn in placeButtons {
            btn.isHidden = true
        }
    }

    func aiPlaceCards(forPlayer player: Int) {
        // AI chooses worst column for opponent
        var bestCol = 0

        for i in 0..<7 {
            if deckMgr.getDeckSize(player: 2, col: i) == 0 {
                bestCol = i
                break
            }
        }

        placeCardsToColumn(player: player, col: bestCol)
    }

    func placeCardsToColumn(player: Int, col: Int) {
        hidePlaceButtons()

        let selected = deckMgr.removeSelectedFromHand(player: player)
        let cardsPlaced = selected.count
        print("Place Player \(player). \(cardsPlaced) cards to column \(col)")
        deckMgr.placeCards(selected, toColumn: col, player: player)

        // Animate cards to slot
        let slotX = (size.width - 6 * slotSpacing) / 2 + CGFloat(col) * slotSpacing
        let slotY = player == 1 ? p1PokerY : p2PokerY

        for (i, card) in selected.enumerated() {
            let targetPos = CGPoint(x: slotX + CGFloat(i) * 8, y: slotY + CGFloat(i) * 5)
            card.setFaceUp(false)
            card.moveTo(position: targetPos, duration: 0.3)
            card.zPosition = CGFloat(20 + i)
            if player == 2 {
                card.setFaceUp(false)
            }
        }

        // Draw new cards to replace the ones placed
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                self?.drawNewCards(forPlayer: player, count: 3)
            }
        ]))

        // Check if column is complete
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                self?.checkColumnAndProceed(col: col)
            }
        ]))
    }

    func drawNewCards(forPlayer player: Int, count: Int) {
        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let faceUp = player == 1  // Player 1's cards are face up, player 2's are face down

        rearrangeHand(player: player)
        
        var cardsDrawn = 0
        for i in 0..<count {
            guard deckMgr.canDrawCard() else { break }

            let newCard = deckMgr.drawCardSprite(owner: player, faceUp: faceUp)
            newCard.setScale(cardScale)
            newCard.position = CGPoint(x: getCardX(index: i + hand.count, total: deckMgr.player1Hand.count + 3),
                                       y: player == 1 ? p1HandY : p2HandY)
            newCard.zPosition = CGFloat(10 + hand.count + i + 1)
            newCard.delegate = self
            addChild(newCard)

            cardsDrawn += 1
        }

        // Rearrange hand with new cards
        if cardsDrawn > 0 {
            rearrangeHand(player: player)
        }
    }

    func rearrangeHand(player: Int) {
        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let y = player == 1 ? p1HandY : p2HandY

        for (i, card) in hand.enumerated() {
            let x = getCardX(index: i, total: hand.count)
            card.moveTo(position: CGPoint(x: x, y: card.position.y), duration: 0.2)
        }
    }

    func checkColumnAndProceed(col: Int) {
        // Check if column is now complete (both players placed)
        if deckMgr.isColumnFull(col: col) {
            compareColumn(col)
        } else {
            proceedToNextTurn()
        }
    }

    func compareColumn(_ col: Int) {
        gameState = .comparing

        let winner = deckMgr.compareColumn(col)
        let p1Cards = deckMgr.getPokerDeck(player: 1, col: col)
        let p2Cards = deckMgr.getPokerDeck(player: 2, col: col)

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

        // Check for game over
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.checkGameOver()
            }
        ]))
    }

    func moveCoin(col: Int, toPlayer player: PlayerType) {
        let coin = coinSprites[col]
        let targetY: CGFloat = player == .player1 ? p1HandY + 50 : p2HandY - 50

        coin.run(SKAction.moveTo(y: targetY, duration: 0.3))
        updateScores()
    }

    func updateScores() {
        let p1Score = coinOwners.filter { $0 == .player1 }.count
        let p2Score = coinOwners.filter { $0 == .player2 }.count

        p1ScoreLabel.text = "You: \(p1Score)"
        p2ScoreLabel.text = "CPU: \(p2Score)"
    }

    func checkGameOver() {
        let p1Score = coinOwners.filter { $0 == .player1 }.count
        let p2Score = coinOwners.filter { $0 == .player2 }.count

        // Win condition: 4 coins or 3 consecutive
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

        if p1Score >= 4 || maxP1Consecutive >= 3 {
            gameState = .gameOver
            showMessage("YOU WIN!")
            showDealButton()
            return
        }

        if p2Score >= 4 || maxP2Consecutive >= 3 {
            gameState = .gameOver
            showMessage("CPU WINS!")
            showDealButton()
            return
        }

        // Check if all columns are filled
        var allFilled = true
        for i in 0..<7 {
            if !deckMgr.isColumnFull(col: i) {
                allFilled = false
                break
            }
        }

        if allFilled {
            gameState = .gameOver
            if p1Score > p2Score {
                showMessage("YOU WIN! (\(p1Score) - \(p2Score))")
            } else if p2Score > p1Score {
                showMessage("CPU WINS! (\(p2Score) - \(p1Score))")
            } else {
                showMessage("TIE GAME!")
            }
            showDealButton()
            return
        }

        proceedToNextTurn()
    }

    func proceedToNextTurn() {
        // Check if game should end (no more cards to play)
        let p1HandEmpty = deckMgr.player1Hand.isEmpty
        let p2HandEmpty = deckMgr.player2Hand.isEmpty
        let noMoreCards = !deckMgr.canDrawCard()

        if (p1HandEmpty && p2HandEmpty) || (noMoreCards && p1HandEmpty && p2HandEmpty) {
            // Force check game over
            checkGameOver()
            return
        }

        if currentPlayer == .player1 {
            if !deckMgr.player2Hand.isEmpty {
                startPlayer2Turn()
            } else {
                startPlayer1Turn()
            }
        } else {
            if !deckMgr.player1Hand.isEmpty {
                startPlayer1Turn()
            } else {
                startPlayer2Turn()
            }
        }
    }

    func showDealButton() {
        dealButton.isHidden = false
        submitButton.isHidden = true
        sortButton.isHidden = true
    }

    func showMessage(_ text: String) {
        messageLabel.text = text
        messageLabel.alpha = 1.0
        messageLabel.removeAllActions()
        messageLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
    }

    // MARK: - CardSpriteDelegate

    func cardClicked(_ card: CardSprite) {
        // Update submit button visibility
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
            } else if name == "submitButton" && !submitButton.isHidden && gameState == .player1Turn {
                player1SubmitCards()
            } else if name == "sortButton" && !sortButton.isHidden {
                sortPlayerHand()
            } else if name.hasPrefix("placeBtn_") && gameState == .player2Placing {
                if let col = Int(name.replacingOccurrences(of: "placeBtn_", with: "")) {
                    placeCardsToColumn(player: 2, col: col)
                }
            }
        }
    }

    func sortPlayerHand() {
        lastSortType = (lastSortType + 1) % 2
        deckMgr.sortHand(player: 1, byNumber: lastSortType == 0)
        rearrangeHand(player: 1)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        // Game loop updates if needed
    }
    private func gameStateMachine() {
        
    }
}
