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
    case player1Placing     // Player1 placing player2's cards
    case comparing          // Comparing cards in a column
    case checkingWin        // Checking win condition
    case gameOver           // Game ended
}

class GameScene: SKScene, CardSpriteDelegate, DeckConfirmationDelegate, HeadFigureDelegate, CompareColumnDelegate, GameWinLoseDelegate, DialogBoxDelegate {

    // MARK: - Properties

    private var deckMgr: DeckMgr!
    private var computerAI: ComputerAI!
    private var toturialManager: InstructionMgr!
    private var soundMgr: SoundMgr!

    // State Machine
    private var currentPhase: GamePhase = .idle {
        didSet {
            handlePhaseChange(from: oldValue, to: currentPhase)
        }
    }
    private var pendingColumn: Int = -1  // Column waiting to be compared
    private var pendingCompareWinner: PlayerType? = nil  // Winner waiting for confirmation
    private var lastPlacingPlayer: Int = 0  // Track who placed cards last (1 or 2)
    private var startPlayer: Int = 1
    private var tutorialMode: Bool = false  //enable tutorial mode
    private var tutorialSubIndex: Int = 0

    // Coin ownership: nil = unclaimed, player1/player2 = owned
    private var coinOwners: [PlayerType?] = Array(repeating: nil, count: 7)
    private var coinSprites: [AnimatedCoin] = []
    private var tieCoins: [AnimatedCoin] = []  // Extra coins created for ties

    // Coin animation settings
    private let coinAnimMinInterval: TimeInterval = 5.0
    private let coinAnimMaxInterval: TimeInterval = 15.0

    // UI Elements
    private var backgroundNode: SKSpriteNode!
    private var commonDeckNode: SKSpriteNode!
    private var slotNodes: [SKSpriteNode] = []
    private var placeButtons: [SKSpriteNode] = []
    private var p1PokerButtons: [SKSpriteNode] = []  // Transparent buttons for viewing p1 poker cards
    private var p2PokerButtons: [SKSpriteNode] = []  // Transparent buttons for viewing p2 poker cards
    // headNode[0] => player1, headNode[1] => player2
    private var headNodes: [HeadFigure] = []

    // Confirmation view
    private var confirmationView: DeckConfirmationView?
    private var compareColumnView: CompareColumnView?
    private var gameWinLoseView: GameWinLoseView?
    
    //Note: there are complex logic regarding tutorialDialog, you need to search tutorial == 1
    private var tutorialDialog: DialogBoxView?
    private var tipDialog: DialogBoxView?

    // Buttons
    private var submitButton: SKSpriteNode!
    private var sortButton: SKSpriteNode!
    private var dealButton: SKSpriteNode!
    private var quitButton: SKSpriteNode!


    // Labels
    private var messageLabel: SKLabelNode!

    // Card layout constants
    private let cardScale: CGFloat = 0.95
    private let slotSpacing: CGFloat = 120

    // Player positions
    private let p1HandY: CGFloat = 80
    private let p2HandY: CGFloat = 560
    private let p1PokerY: CGFloat = 220
    private let p2PokerY: CGFloat = 420

    private var lastSortType: Int = 0

    // Ad tracking
    private var playerActionCount: Int = 0

    // Game tracking
    private var gameStartTime: Date?

    // MARK: - Scene Setup

    class func newGameScene(startPlayer: Int = 1, isTutorial: Bool = false) -> GameScene {
        let scene = GameScene(size: CGSize(width: 1400, height: 640))
        scene.scaleMode = .aspectFit
        scene.startPlayer = startPlayer
        // First time user will execute tutorial mode
        // scene.tutorialMode = !UserLocalDataMgr.shared.getTutorialPlayed() ? true: isTutorial
        scene.tutorialMode = isTutorial
        return scene
    }

    override func didMove(to view: SKView) {
        deckMgr = DeckMgr.shared
        computerAI = ComputerAI.shared
        toturialManager = InstructionMgr.shared

        // Setup sound manager with this scene
        soundMgr = SoundMgr.shared
        SoundMgr.shared.setScene(self)

        // Track screen view and game start
        TrackingManager.shared.trackScreen(tutorialMode ? "GameTutorial" : "Game")
        let difficulty = ComputerAI.shared.getLevel()
        TrackingManager.shared.trackGameStart(difficulty: difficulty, isTutorial: tutorialMode)
        gameStartTime = Date()

        setupBackground()
        setupSlots()
        setupCoins()
        setupButtons()
        setupLabels()
        setupCommonDeck()
        setupHeads()
        setupAIs()
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
            if (tutorialMode) {
                // Remove existing dialog before creating new one
                tutorialDialog?.removeFromParent()
                tutorialDialog = nil

                tutorialDialog = toturialManager.getIntructionDialog(scene: self, i: tutorialSubIndex)
                if let dialogboxNode = tutorialDialog {
                    addChild(dialogboxNode)
                }
            }
            onEnterPlayer1Selecting()
        case .player1Confirming:
            break // Handled by showConfirmationView
        case .player1Waiting:
            onEnterPlayer1Waiting()
        case .player2Selecting:
            onEnterPlayer2Selecting()
        case .player1Placing:
            onEnterPlayer1Placing()
        case .comparing:
            onEnterComparing()
        case .checkingWin:
            onEnterCheckingWin()
        case .gameOver:
            onEnterGameOver()
        }
    }
    
    private func setupHeads() {
        for i in 0..<2 {
            let headNode = HeadFigure(player: i + 1)
            headNode.zPosition = 100
            if (i == 0) {
                // Player 1 head - set delegate for click handling
                headNode.delegate = self
                headNode.position = CGPoint(x: 200 - HeadFigure.slide_in_width, y: 100)
            } else {
                headNode.position = CGPoint(x: 1200 + HeadFigure.slide_in_width, y: 550)
            }
            headNodes.append(headNode)
            addChild(headNode)
        }
    }
    
    private func setupAIs() {
        let level = UserLocalDataMgr.shared.getAiDifficulty()
        ComputerAI.shared.setLevel(level)
        print("Set AI level \(level)")
    }

    // MARK: - State Entry Handlers

    private func onEnterIdle() {
        showMessage("Tap DEAL to start")
        dealButton.isHidden = true
        submitButton.isHidden = true
        sortButton.isHidden = true
        hidePlaceButtons()

        // Check if we should show a tip (not in tutorial mode)
        if !tutorialMode, let tip = TipManager.shared.shouldShowTip() {
            showTipDialog(tip)
        } else {
            startGameAfterDelay()
        }
    }

    private func showTipDialog(_ tip: String) {
        // Remove existing tip dialog if any
        tipDialog?.removeFromParent()

        tipDialog = DialogBoxView(sceneSize: size, style: .center, text: tip)
        tipDialog?.delegate = self
        addChild(tipDialog!)
    }

    private func startGameAfterDelay() {
        //wait for 0.5 seconds and trigger deal
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                startNewGame()
            }
        ]))
    }

    private func onEnterDealing() {
        dealButton.isHidden = true
        dealCards()
        //TODO: add start Player
        headNodes[0].changeAnimationState(HeadFigure.AnimationState.myTurn)
        headNodes[1].changeAnimationState(HeadFigure.AnimationState.hidden)
    }

    private func onEnterPlayer1Selecting() {
        // Track player action for ads
        trackPlayerActionAndShowAd()

        // Enable player1's cards for selection
        for card in deckMgr.player1Hand {
            card.setEnabled(true)
        }

        sortButton.isHidden = false
        showMessage("Select 1-5 cards")
    }

    private func onEnterPlayer1Waiting() {
        // Disable player1's cards
        for card in deckMgr.player1Hand {
            card.setEnabled(false)
        }
        

        showMessage("CPU choosing position...")
        hidePokerButtons()
        headNodes[0].stopSpinAnimation()
        submitButton.isHidden = true

        headNodes[0].changeAnimationState(HeadFigure.AnimationState.hidden)
        headNodes[1].changeAnimationState(HeadFigure.AnimationState.myTurn)
        
        // AI places player1's cards
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.aiPlacePlayer1Cards()
            }
        ]))
    }

    private func onEnterPlayer2Selecting() {
        // AI selects cards (with animation if animatedSelection is true)
        computerAI.selectCards()

        let selected = deckMgr.getSelectedCards(player: 2)

        showMessage("CPU plays \(selected.count) card(s)")

        headNodes[0].changeAnimationState(HeadFigure.AnimationState.hidden)
        headNodes[1].changeAnimationState(HeadFigure.AnimationState.myTurn)

        // Wait then proceed to player placing
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Flip cards back
                for card in selected {
                    card.setFaceUp(false)
                }
                self.currentPhase = .player1Placing
            }
        ]))
    }

    private func onEnterPlayer1Placing() {
        // Track player action for ads
        trackPlayerActionAndShowAd()

        showPlaceButtons(forPlayer: 2)
        showMessage("Choose where to place CPU's cards")
        headNodes[0].changeAnimationState(HeadFigure.AnimationState.myTurn)
        headNodes[1].changeAnimationState(HeadFigure.AnimationState.hidden)
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
        hidePokerButtons()
    }

    // MARK: - Ad Management

    private func trackPlayerActionAndShowAd() {
        playerActionCount += 1
        print("Player Action count \(playerActionCount)")
        if ((playerActionCount > 0) && (playerActionCount % AdConfig.userActionsPerAd == 0)) {
            print("Show ads...")
            InterstitialAdManager.shared.showAd()
        }
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
            let coin = AnimatedCoin()
            coin.size = CGSize(width: 80, height: 80)
            coin.position = CGPoint(x: x, y: size.height / 2)
            coin.zPosition = 50
            coin.name = "coin_\(i)"
            addChild(coin)
            coinSprites.append(coin)

            // Start random playback: play frames 4-7, then reset to frame 0
            coin.startRandomPlayback(
                minInterval: coinAnimMinInterval,
                maxInterval: coinAnimMaxInterval,
                startFrame: 4,
                endFrame: 7,
                resetFrame: 0
            )
        }
    }

    private func startGlowHighlight(on btn: SKSpriteNode) {
        // 避免重複加
        if btn.childNode(withName: "glowHighlight") != nil { return }

        let glow = SKShapeNode(
            rectOf: btn.size,
            cornerRadius: 10
        )
        glow.name = "glowHighlight"
        glow.strokeColor = .yellow
        glow.lineWidth = 4
        glow.glowWidth = 10
        glow.zPosition = btn.zPosition - 1
        glow.alpha = 1.0

        // 呼吸動畫
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.6)
        let fadeIn  = SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        let breathe = SKAction.sequence([fadeOut, fadeIn])
        let loop    = SKAction.repeatForever(breathe)

        glow.run(loop)
        btn.addChild(glow)
    }
    
    func stopGlowHighlight(on btn: SKSpriteNode) {
        btn.childNode(withName: "glowHighlight")?.removeFromParent()
    }
    
    private func setupButtons() {
        // Deal button
        dealButton = createButton(text: "DEAL", color: .systemGreen)
        dealButton.position = CGPoint(x: size.width / 2, y: 50)
        dealButton.name = "dealButton"
        dealButton.zPosition = 100
        addChild(dealButton)

        // Submit button
        submitButton = SKSpriteNode(imageNamed: "submit_btn")
        submitButton.size = CGSize(width: 100, height: 100)
        submitButton.position = CGPoint(x: size.width - 200, y: size.height / 2 - 100)
        submitButton.name = "submitButton"
        submitButton.isHidden = true
        submitButton.zPosition = 100
        addChild(submitButton)

        // Sort button
        sortButton = SKSpriteNode(imageNamed: "sort_btn")
        sortButton.size = CGSize(width: 100, height: 100)
        sortButton.position = CGPoint(x: size.width - 200, y: size.height / 2 + 100)
        sortButton.name = "sortButton"
        sortButton.isHidden = true
        sortButton.zPosition = 100
        addChild(sortButton)

        // Quit button
        quitButton = SKSpriteNode(imageNamed: "quit_btn")
        quitButton.size = CGSize(width: 150, height: 150)
        quitButton.name = "quitButton"
        quitButton.anchorPoint = CGPoint(x: 0, y: 1)
        quitButton.position = CGPoint(x: 0, y: size.height)
        quitButton.zPosition = 100
        addChild(quitButton)
        
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
        if (!tutorialMode) {
            for i in 0..<7 {
                stopGlowHighlight(on: placeButtons[i])
                startGlowHighlight(on: placeButtons[i])
            }
        } else {
            startGlowHighlight(on: placeButtons[0])
        }

        // P1 Poker buttons (transparent, for viewing placed cards)
        for i in 0..<7 {
            let btn = SKSpriteNode(color: .clear, size: CGSize(width: 100, height: 140))
            btn.position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: p1PokerY)
            btn.name = "p1PokerBtn_\(i)"
            btn.isHidden = true
            btn.zPosition = 200  // Above cards
            addChild(btn)
            p1PokerButtons.append(btn)
        }

        // P2 Poker buttons (transparent, for viewing placed cards)
        for i in 0..<7 {
            let btn = SKSpriteNode(color: .clear, size: CGSize(width: 100, height: 140))
            btn.position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: p2PokerY)
            btn.name = "p2PokerBtn_\(i)"
            btn.isHidden = true
            btn.zPosition = 200  // Above cards
            addChild(btn)
            p2PokerButtons.append(btn)
        }
    }

    private func setupLabels() {
        messageLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        messageLabel.fontSize = 24
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.zPosition = 100
        addChild(messageLabel)
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
        if (tutorialMode) {
            deckMgr.initDeck(initSeedNum: 1)
        } else {
            deckMgr.initDeck()
        }
        coinOwners = Array(repeating: nil, count: 7)

        // Remove tie coins from previous game
        for coin in tieCoins {
            coin.removeFromParent()
        }
        tieCoins.removeAll()

        // Reset coins
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        for i in 0..<7 {
            coinSprites[i].position = CGPoint(x: startX + CGFloat(i) * slotSpacing, y: size.height / 2)
            coinSprites[i].alpha = 1.0
            // Restart random playback: play frames 4-7, then reset to frame 0
            coinSprites[i].stopRandomPlayback()
            coinSprites[i].setFrame(0)
            coinSprites[i].startRandomPlayback(
                minInterval: coinAnimMinInterval,
                maxInterval: coinAnimMaxInterval,
                startFrame: 4,
                endFrame: 7,
                resetFrame: 0
            )
        }

        // Hide p1 poker buttons
        hidePokerButtons()

        updateScores()
        currentPhase = .dealing
    }

    private func dealCards() {
        var delay: TimeInterval = 0
        let dealInterval: TimeInterval = 0.2

        // Deal 13 cards to each player
        for i in 0..<13 {
            // Player 1 card (face up)
            let p1Card = deckMgr.drawCardSprite(owner: 1, faceUp: true)
            p1Card.setScale(cardScale)
            p1Card.position = commonDeckNode.position
            p1Card.zPosition = CGFloat(10)
            p1Card.delegate = self
            addChild(p1Card)

            let p1TargetX = getCardX(index: i, total: 13)
            let p1Move = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.move(to: CGPoint(x: p1TargetX, y: p1HandY), duration: 0.3),
                SKAction.run {
                    p1Card.zPosition = CGFloat(10 + i)
                    self.soundMgr.playTick()
                }
            ])
            p1Card.run(p1Move)

            // Player 2 card (face down)
            let p2Card = deckMgr.drawCardSprite(owner: 2, faceUp: false)
            p2Card.setScale(cardScale)
            p2Card.position = commonDeckNode.position
            p2Card.zPosition = CGFloat(10 + i)
            p2Card.delegate = self
            addChild(p2Card)

            let p2TargetX = getCardX(index: i, total: 13)
            let p2Move = SKAction.sequence([
                SKAction.wait(forDuration: delay + 0.05),
                SKAction.move(to: CGPoint(x: p2TargetX, y: p2HandY), duration: 0.3)
            ])
            p2Card.run(p2Move)
            delay += dealInterval
        }

        print("startPlayer \(startPlayer)")
        // After dealing, start player1's turn
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay + 0.5),
            SKAction.run { [weak self] in
                if (self?.startPlayer == 1) {
                    self?.currentPhase = .player1Selecting
                } else {
                    self?.currentPhase = .player2Selecting
                }
            }
        ]))
    }

    //get card x based on its index
    private func getCardX(index: Int, total: Int) -> CGFloat {
        let spacing: CGFloat = min(max(40, 750 / CGFloat(total)), 60)    //set min spacing 40, but cap to 60
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
        if (tutorialMode) {
            //note K equals to 11
            if (selected.count != 2 || selected[0].getNumber() != 11 || selected[1].getNumber() != 11) {
                for card in selected {
                    card.setSelected(false)
                }
                return;
            }
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
        sortButton.isHidden = false
        currentPhase = .player1Selecting
    }

    func confirmationDidDismiss() {
        confirmationView?.removeFromParent()
        confirmationView = nil
    }

    private func showViewOnlyConfirmation(forColumn col: Int) {
        let cards = deckMgr.getPokerDeck(player: 1, col: col)
        guard !cards.isEmpty else { return }

        confirmationView?.removeFromParent()

        let confirmation = DeckConfirmationView(sceneSize: size, viewOnly: true)
        confirmation.delegate = self

        let cardType = deckMgr.getBestOfCards(cards)
        confirmation.showCards(cards, cardType: cardType)

        addChild(confirmation)
        confirmationView = confirmation
    }

    // MARK: - AI Actions

    private func aiPlacePlayer1Cards() {
        let col = tutorialMode ? 0 : computerAI.chooseColumnForOpponent()
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

    private func updatePokerButtons() {
        for i in 0..<7 {
            let hasP1Cards = deckMgr.getColumnSize(player: 1, col: i) > 0
            let isFull = deckMgr.isColumnFull(col: i)

            // P1 button: show if has p1 cards (for viewing own cards or reviewing comparison)
            p1PokerButtons[i].isHidden = !hasP1Cards

            // P2 button: show if column is full (for reviewing comparison)
            p2PokerButtons[i].isHidden = !isFull
        }
    }

    private func hidePokerButtons() {
        for btn in p1PokerButtons {
            btn.isHidden = true
        }
        for btn in p2PokerButtons {
            btn.isHidden = true
        }
    }

    private func placeCardsToColumn(player: Int, col: Int) {
        if (tutorialMode) {
            if (player == 2 && col != 0) {
                print("Player is not putting into correct columns")
                return;
            }
        }
        hidePlaceButtons()

        // Track who placed cards last for turn order after comparing
        lastPlacingPlayer = player

        let selected = deckMgr.removeSelectedFromHand(player: player)
        let cardsPlaced = selected.count
        print("Placing \(cardsPlaced) cards for Player \(player) to column \(col)")

        deckMgr.placeCards(selected, toColumn: col, player: player)
        print("Column col: \(col), size \(deckMgr.getColumnSize(player: player, col: col))")

        // Animate cards to slot
        soundMgr.playPlace()

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
                // Update p1 poker buttons visibility
                self.updatePokerButtons()

                if self.deckMgr.isColumnFull(col: col) {
                    self.pendingColumn = col
                    self.currentPhase = .comparing
                } else {
                    dialogBoxDidDismiss()
                    self.proceedToNextTurn()
                }
            }
        ]))
    }

    private func drawNewCards(forPlayer player: Int, count: Int) {
        rearrangeHand(player: player, resetY: false)
        drawNextCard(forPlayer: player, remaining: count, cardIndex: 0)
    }

    private func drawNextCard(forPlayer player: Int, remaining: Int, cardIndex: Int) {
        guard remaining > 0, deckMgr.canDrawCard() else {
            // All cards drawn, rearrange hand
            if cardIndex > 0 {
                rearrangeHand(player: player, resetY: true)
            }
            return
        }
        
        soundMgr.playTick()

        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let faceUp = player == 1

        let newCard = deckMgr.drawCardSprite(owner: player, faceUp: faceUp)
        newCard.setScale(cardScale)
        newCard.position = commonDeckNode.position
        newCard.zPosition = CGFloat(10 + hand.count + cardIndex)
        newCard.delegate = self
        addChild(newCard)

        // Rearrange after each card is added
        rearrangeHand(player: player, resetY: true)

        // Wait and draw next card
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.drawNextCard(forPlayer: player, remaining: remaining - 1, cardIndex: cardIndex + 1)
            }
        ]))
    }

    private func rearrangeHand(player: Int, resetY: Bool = false) {
        let hand = player == 1 ? deckMgr.player1Hand : deckMgr.player2Hand
        let newY = player == 1 ? p1HandY : p2HandY

        for (i, card) in hand.enumerated() {
            let x = getCardX(index: i, total: hand.count)
            card.moveTo(position: CGPoint(x: x, y: resetY ? newY : card.position.y), duration: 0.2)
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

        // Store winner for later use
        pendingCompareWinner = winner
        headNodes[0].changeAnimationState(.myTurn)
        headNodes[1].changeAnimationState(.myTurn)

        // make sure DeckConfirmationView is dismissed if there is any to avoid UI bug
        confirmationDidDismiss()
        
        // Show comparison view
        soundMgr.playCompare()
        showCompareColumnView(p1Cards: p1Cards, p1Type: p1Type,
                              p2Cards: p2Cards, p2Type: p2Type,
                              winner: winner)
    }

    private func showCompareColumnView(p1Cards: [CardSprite], p1Type: CardType,
                                        p2Cards: [CardSprite], p2Type: CardType,
                                        winner: PlayerType?) {
        compareColumnView?.removeFromParent()

        let compareView = CompareColumnView(sceneSize: size)
        compareView.delegate = self
        compareView.showComparison(p1Cards: p1Cards, p1CardType: p1Type,
                                   p2Cards: p2Cards, p2CardType: p2Type,
                                   winner: winner)
        addChild(compareView)
        compareColumnView = compareView
    }

    // MARK: - CompareColumnDelegate

    func compareColumnDidConfirm() {
        compareColumnView?.removeFromParent()
        compareColumnView = nil

        // Apply the comparison result
        let col = pendingColumn
        guard col >= 0 else {
            pendingColumn = -1
            currentPhase = .checkingWin
            return
        }

        if let winner = pendingCompareWinner {
            switch winner {
            case .player1:
                coinOwners[col] = .player1
                headNodes[0].changeFigure(.slightlyHappy)
                headNodes[1].changeFigure(.slightlySad)
                moveCoin(col: col, toPlayer: .player1)
            case .player2:
                coinOwners[col] = .player2
                headNodes[0].changeFigure(.slightlySad)
                headNodes[1].changeFigure(.slightlyHappy)
                moveCoin(col: col, toPlayer: .player2)
            case .even:
                headNodes[0].changeFigure(.slightlyHappy)
                headNodes[1].changeFigure(.slightlyHappy)
                handleTie(col: col)
            default:
                break
            }
        }

        pendingColumn = -1
        pendingCompareWinner = nil

        dialogBoxDidDismiss()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.currentPhase = .checkingWin
            }
        ]))
    }

    func compareColumnDidDismiss() {
        compareColumnView?.removeFromParent()
        compareColumnView = nil
    }

    private func moveCoin(col: Int, toPlayer player: PlayerType) {
        let coin = coinSprites[col]
        let targetY: CGFloat = player == .player1 ? p1PokerY : p2PokerY
        coin.run(SKAction.moveTo(y: targetY, duration: 0.3))
        updateScores()
    }

    private func handleTie(col: Int) {
        let startX: CGFloat = (size.width - 6 * slotSpacing) / 2
        let coinX = startX + CGFloat(col) * slotSpacing

        // Hide original coin
        let originalCoin = coinSprites[col]
        originalCoin.stopRandomPlayback()
        originalCoin.run(SKAction.fadeOut(withDuration: 0.2))

        // Create coin for player 1
        let p1Coin = AnimatedCoin()
        p1Coin.size = CGSize(width: 80, height: 80)
        p1Coin.position = CGPoint(x: coinX, y: size.height / 2)
        p1Coin.zPosition = 50
        p1Coin.setFrame(0)
        addChild(p1Coin)
        tieCoins.append(p1Coin)
        p1Coin.run(SKAction.moveTo(y: p1PokerY, duration: 0.3))

        // Create coin for player 2
        let p2Coin = AnimatedCoin()
        p2Coin.size = CGSize(width: 80, height: 80)
        p2Coin.position = CGPoint(x: coinX, y: size.height / 2)
        p2Coin.zPosition = 50
        p2Coin.setFrame(0)
        addChild(p2Coin)
        tieCoins.append(p2Coin)
        p2Coin.run(SKAction.moveTo(y: p2PokerY, duration: 0.3))

        // Mark column as tied (both players get a point)
        coinOwners[col] = .even
        updateScores()
    }

    private func updateScores() {
        // Count player wins + ties (both players get a point on tie)
        let tieCount = coinOwners.filter { $0 == .even }.count
        let p1Score = coinOwners.filter { $0 == .player1 }.count + tieCount
        let p2Score = coinOwners.filter { $0 == .player2 }.count + tieCount
    }

    private func checkWinCondition() {
        // Count player wins + ties (both players get a point on tie)
        let tieCount = coinOwners.filter { $0 == .even }.count
        let p1Score = coinOwners.filter { $0 == .player1 }.count + tieCount
        let p2Score = coinOwners.filter { $0 == .player2 }.count + tieCount

        // Check consecutive wins (ties count for both players)
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
            } else if owner == .even {
                // Tie counts for both, but breaks consecutive for win condition
                p1Consecutive = 0
                p2Consecutive = 0
            } else {
                p1Consecutive = 0
                p2Consecutive = 0
            }
        }

        // Win conditions: 4 coins or 3 consecutive
        if p1Score >= 4 || maxP1Consecutive >= 3 {
            showGameWinLoseView(isWin: true)
            currentPhase = .gameOver
            return
        }

        if p2Score >= 4 || maxP2Consecutive >= 3 {
            showGameWinLoseView(isWin: false)
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
                showGameWinLoseView(isWin: true)
            } else if p2Score > p1Score {
                showGameWinLoseView(isWin: false)
            } else {
                // Tie game - show win panel (or could create a separate tie panel)
                showGameWinLoseView(isWin: true)
            }
            currentPhase = .gameOver
            return
        }

        proceedToNextTurn()
    }

    private func showGameWinLoseView(isWin: Bool) {
        gameWinLoseView?.removeFromParent()
        if (isWin) {
            self.soundMgr.playVictory()
        } else {
            self.soundMgr.playLose()
        }

        // Record win/loss statistics (only if not in tutorial mode)
        if !tutorialMode {
            let currentDifficulty = computerAI.getLevel()
            if isWin {
                UserLocalDataMgr.shared.recordWin(difficulty: currentDifficulty)
            } else {
                UserLocalDataMgr.shared.recordLoss(difficulty: currentDifficulty)
            }

            // Track game end
            let duration = gameStartTime.map { Date().timeIntervalSince($0) } ?? 0
            TrackingManager.shared.trackGameEnd(isWin: isWin, difficulty: currentDifficulty, duration: duration)
        } else {
            // Track tutorial completion
            if isWin {
                TrackingManager.shared.trackTutorialComplete()
            }
        }

        let winLoseView = GameWinLoseView(sceneSize: size, isWin: isWin)
        winLoseView.delegate = self
        addChild(winLoseView)
        gameWinLoseView = winLoseView
    }

    // MARK: - GameWinLoseDelegate

    func gameWinLosePlayAgain() {
        gameWinLoseView?.removeFromParent()
        gameWinLoseView = nil

        //flip start player
        startPlayer = startPlayer == 1 ? 2 : 1
        startNewGame()
    }

    func gameWinLoseMainMenu() {
        gameWinLoseView?.removeFromParent()
        gameWinLoseView = nil

        let mainMenu = MainMenuScene.newMenuScene()
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenu, transition: transition)
    }
    
    // MARK: - Dialogbox delegate

    func dialogBoxDidDismiss() {
        // Handle tip dialog dismiss first
        if let currentTipDialog = tipDialog {
            currentTipDialog.removeFromParent()
            tipDialog = nil
            // After tip is dismissed, start the game
            startGameAfterDelay()
            return
        }

        // Guard against multiple calls or calls when dialog already removed
        if (!tutorialMode) {
            return
        }

        guard let currentDialog = tutorialDialog else {
            print("Dialog debugging: dialogboxView is already nil, ignoring dismiss")
            return
        }

        print("Dialog debugging, index: \(tutorialSubIndex)")

        // Remove and clear reference
        // resume block turn if needed
        let shouldProceedToNextTurn: Bool = tutorialMode && currentDialog.getBlockTurn()

        currentDialog.removeFromParent()
        tutorialDialog = nil

        if (tutorialMode) {
            tutorialSubIndex += 1
            if (tutorialSubIndex < InstructionMgr.shared.turtorialTexts.count) {
                tutorialDialog = toturialManager.getIntructionDialog(scene: self, i: tutorialSubIndex)
                if let dialogboxNode = tutorialDialog {
                    addChild(dialogboxNode)
                }
            } else if (tutorialSubIndex == InstructionMgr.shared.turtorialTexts.count) {
                tutorialDialog?.removeFromParent()
                tutorialDialog = nil
                // Tutorial finished, game restart
                tutorialMode = false
                UserLocalDataMgr.shared.recordTutorialPlayed()
                
                for i in 0..<7 {
                    startGlowHighlight(on: placeButtons[i])
                }
                
                startNewGame()
            }
            if (shouldProceedToNextTurn) {
                proceedToNextTurn()
            }
        }
    }
    
    private func proceedToNextTurn() {
        if (tutorialMode && tutorialDialog?.getBlockTurn() != nil && tutorialDialog?.getBlockTurn() == true) {
            print("Do not proceed to next turn in tutorial mode due to blockTurn: \(String(describing: tutorialDialog?.getBlockTurn()))")
            return;
        }
        let p1HandEmpty = deckMgr.player1Hand.isEmpty
        let p2HandEmpty = deckMgr.player2Hand.isEmpty

        if p1HandEmpty && p2HandEmpty {
            currentPhase = .checkingWin
            return
        }

        // After comparing/checkingWin, use lastPlacingPlayer to determine next turn
        // If player1 placed last → player2's turn next
        // If player2 placed last → player1's turn next
        if currentPhase == .comparing || currentPhase == .checkingWin {
            if lastPlacingPlayer == 1 {
                // Player1 placed last, so player2's turn
                if !p2HandEmpty {
                    currentPhase = .player2Selecting
                } else if !p1HandEmpty {
                    currentPhase = .player1Selecting
                } else {
                    currentPhase = .checkingWin
                }
            } else {
                // Player2 placed last, so player1's turn
                if !p1HandEmpty {
                    currentPhase = .player1Selecting
                } else if !p2HandEmpty {
                    currentPhase = .player2Selecting
                } else {
                    currentPhase = .checkingWin
                }
            }
        } else if currentPhase == .player1Waiting {
            // After AI places player1's cards
            if !p2HandEmpty {
                currentPhase = .player2Selecting
            } else if !p1HandEmpty {
                currentPhase = .player1Selecting
            } else {
                currentPhase = .checkingWin
            }
        } else if currentPhase == .player1Placing {
            // After player places player2's cards
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
        print("Log message \(text)")
    }

    private func sortPlayerHand() {
        soundMgr.playSort()
        lastSortType = (lastSortType + 1) % 2
        deckMgr.sortHand(player: 1, byNumber: lastSortType == 0)
        rearrangeHand(player: 1)
    }

    // MARK: - CardSpriteDelegate

    func cardClicked(_ card: CardSprite) {
        self.soundMgr.playSelect()
        guard currentPhase == .player1Selecting else { return }
        let selectedCount = deckMgr.getSelectedCards(player: 1).count
        let cantSubmit: Bool = (selectedCount == 0 || selectedCount > 5)
        submitButton.isHidden = cantSubmit
        headNodes[0].showSpin(!cantSubmit)
    }

    // MARK: - HeadFigureDelegate

    func headFigureClicked(_ headFigure: HeadFigure) {
        // Only respond when in player1Selecting phase and it's player1's head
        guard currentPhase == .player1Selecting,
              headFigure.getPlayer() == 1 else { return }

        player1Submit()
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
                submitButton.alpha = 0.7
                submitButton.setScale(0.9)
                player1Submit()
            } else if name == "sortButton" && !sortButton.isHidden {
                // Press down effect
                sortButton.alpha = 0.7
                sortButton.setScale(0.9)
            } else if name.hasPrefix("placeBtn_") && currentPhase == .player1Placing {
                if let col = Int(name.replacingOccurrences(of: "placeBtn_", with: "")) {
                    placeCardsToColumn(player: 2, col: col)
                }
            } else if name == "quitButton" && !quitButton.isHidden {
                quitButton.alpha = 0.7
            }
        }
    }
    

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset sortButton visual state
        sortButton.alpha = 1.0
        sortButton.setScale(1.0)

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            guard let name = node.name ?? node.parent?.name else { continue }

            if name == "sortButton" && !sortButton.isHidden {
                sortPlayerHand()
            }
            if name == "quitButton" && !quitButton.isHidden {
                saveAndExit()
            }

            // Check for p1Poker button clicks
            if name.hasPrefix("p1PokerBtn_") {
                if let col = Int(name.replacingOccurrences(of: "p1PokerBtn_", with: "")) {
                    handlePokerSlotClick(col: col)
                }
            }

            // Check for p2Poker button clicks
            if name.hasPrefix("p2PokerBtn_") {
                if let col = Int(name.replacingOccurrences(of: "p2PokerBtn_", with: "")) {
                    handlePokerSlotClick(col: col)
                }
            }
        }
    }

    private func handlePokerSlotClick(col: Int) {
        if deckMgr.isColumnFull(col: col) {
            // Column is full (already compared) - show comparison review
            showComparisonReview(forColumn: col)
        } else if deckMgr.getColumnSize(player: 1, col: col) > 0 {
            // Column has p1 cards but not full - show view-only confirmation
            showViewOnlyConfirmation(forColumn: col)
        }
    }

    private func showComparisonReview(forColumn col: Int) {
        let p1Cards = deckMgr.getPokerDeck(player: 1, col: col)
        let p2Cards = deckMgr.getPokerDeck(player: 2, col: col)

        let p1Type = deckMgr.getBestOfCards(p1Cards)
        let p2Type = deckMgr.getBestOfCards(p2Cards)

        // Get the winner from coinOwners
        let winner = coinOwners[col]

        compareColumnView?.removeFromParent()

        let compareView = CompareColumnView(sceneSize: size, viewOnly: true)
        compareView.delegate = self
        compareView.showComparison(p1Cards: p1Cards, p1CardType: p1Type,
                                   p2Cards: p2Cards, p2CardType: p2Type,
                                   winner: winner)
        addChild(compareView)
        compareColumnView = compareView
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Reset sortButton visual state
        sortButton.alpha = 1.0
        sortButton.setScale(1.0)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        // Game loop updates if needed
    }
    
    //TODO: save is not implemented yet
    func saveAndExit() {
        let mainMenu = MainMenuScene.newMenuScene()
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenu, transition: transition)
    }
}
