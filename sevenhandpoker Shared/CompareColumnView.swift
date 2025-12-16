//
//  CompareColumnView.swift
//  Seven Hand Poker
//
//  View for comparing cards between players in a column
//

import SpriteKit

protocol CompareColumnDelegate: AnyObject {
    func compareColumnDidConfirm()
}

class CompareColumnView: SKNode {

    weak var delegate: CompareColumnDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var dialogBox: SKSpriteNode!
    private var okButton: SKSpriteNode!

    // Player 2 (top section)
    private var p2CardTypeLabel: SKLabelNode!
    private var p2CardDisplayNodes: [SKSpriteNode] = []

    // Player 1 (bottom section)
    private var p1CardTypeLabel: SKLabelNode!
    private var p1CardDisplayNodes: [SKSpriteNode] = []

    // Winner indicator
    private var winnerLabel: SKLabelNode!

    private let dialogWidth: CGFloat = 650
    private let dialogHeight: CGFloat = 550
    private let cardScale: CGFloat = 0.9

    init(sceneSize: CGSize) {
        super.init()

        self.zPosition = 1000
        self.isUserInteractionEnabled = true

        setupOverlay(sceneSize: sceneSize)
        setupDialog(sceneSize: sceneSize)
        setupButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupOverlay(sceneSize: CGSize) {
        backgroundOverlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.6), size: sceneSize)
        backgroundOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        backgroundOverlay.zPosition = 0
        backgroundOverlay.name = "overlay"
        addChild(backgroundOverlay)
    }

    private func setupDialog(sceneSize: CGSize) {
        // Dialog box with panel_large
        dialogBox = SKSpriteNode(imageNamed: "panel_large")
        dialogBox.size = CGSize(width: dialogWidth, height: dialogHeight)
        dialogBox.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        dialogBox.zPosition = 1
        addChild(dialogBox)

        // Player 2 card type label (top)
        p2CardTypeLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        p2CardTypeLabel.text = ""
        p2CardTypeLabel.fontSize = 24
        p2CardTypeLabel.fontColor = SKColor.cyan
        p2CardTypeLabel.position = CGPoint(x: 0, y: 195)
        p2CardTypeLabel.zPosition = 20
        dialogBox.addChild(p2CardTypeLabel)

        // Player 1 card type label (bottom, above button)
        p1CardTypeLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        p1CardTypeLabel.text = ""
        p1CardTypeLabel.fontSize = 24
        p1CardTypeLabel.fontColor = SKColor.cyan
        p1CardTypeLabel.position = CGPoint(x: 0, y: 0)
        p1CardTypeLabel.zPosition = 20
        dialogBox.addChild(p1CardTypeLabel)

        // Winner label (center)
        winnerLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        winnerLabel.text = ""
        winnerLabel.fontSize = 32
        winnerLabel.fontColor = SKColor.white
        winnerLabel.position = CGPoint(x: 0, y: 0)
        winnerLabel.zPosition = 2
        dialogBox.addChild(winnerLabel)
    }

    private func setupButton() {
        // OK button
        okButton = SKSpriteNode(imageNamed: "panel_ok_btn")
        okButton.size = CGSize(width: 240, height: 120)
        okButton.position = CGPoint(x: 0, y: -dialogHeight / 2 + 85)
        okButton.name = "okBtn"
        okButton.zPosition = 2
        dialogBox.addChild(okButton)
    }

    // MARK: - Public Methods

    func showComparison(p1Cards: [CardSprite], p1CardType: CardType,
                        p2Cards: [CardSprite], p2CardType: CardType,
                        winner: PlayerType?) {
        // Clear previous card displays
        clearCardDisplays()

        // Display Player 2 cards (top)
        displayCards(p2Cards, forPlayer: 2, yOffset: 130)
        p2CardTypeLabel.text = "\(p2CardType.displayName)"
        setCardTypeColor(label: p2CardTypeLabel, cardType: p2CardType)

        // Display Player 1 cards (bottom)
        displayCards(p1Cards, forPlayer: 1, yOffset: -70)
        p1CardTypeLabel.text = "\(p1CardType.displayName)"
        setCardTypeColor(label: p1CardTypeLabel, cardType: p1CardType)

        // Show winner
        /*
        switch winner {
        case .player1:
            winnerLabel.text = "You Win!"
            winnerLabel.fontColor = SKColor.yellow
        case .player2:
            winnerLabel.text = "CPU Wins!"
            winnerLabel.fontColor = SKColor.cyan
        case .even:
            winnerLabel.text = "Tie!"
            winnerLabel.fontColor = SKColor.white
        default:
            winnerLabel.text = ""
        }*/
    }

    private func displayCards(_ cards: [CardSprite], forPlayer player: Int, yOffset: CGFloat) {
        let totalWidth = CGFloat(cards.count - 1) * 80
        let startX = -totalWidth / 2

        for (index, card) in cards.enumerated() {
            let cardCopy = SKSpriteNode(texture: card.texture)
            cardCopy.setScale(cardScale)
            cardCopy.position = CGPoint(x: startX + CGFloat(index) * 80, y: yOffset)
            cardCopy.zPosition = CGFloat(3 + index)
            dialogBox.addChild(cardCopy)

            if player == 1 {
                p1CardDisplayNodes.append(cardCopy)
            } else {
                p2CardDisplayNodes.append(cardCopy)
            }
        }
    }

    private func clearCardDisplays() {
        for node in p1CardDisplayNodes {
            node.removeFromParent()
        }
        p1CardDisplayNodes.removeAll()

        for node in p2CardDisplayNodes {
            node.removeFromParent()
        }
        p2CardDisplayNodes.removeAll()
    }

    private func setCardTypeColor(label: SKLabelNode, cardType: CardType) {
        switch cardType {
        case .straightFlush, .fourOfAKind:
            label.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Red for strong
        case .fullHouse, .flush, .straight:
            label.fontColor = SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0) // Orange
        case .threeOfAKind, .twoPair:
            label.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0) // Yellow
        case .onePair:
            label.fontColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0) // Light blue
        case .highCard:
            label.fontColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // Gray
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let dialogLocation = touch.location(in: dialogBox)

        if okButton.contains(dialogLocation) {
            okButton.alpha = 0.7
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        okButton.alpha = 1.0

        let dialogLocation = touch.location(in: dialogBox)

        if okButton.contains(dialogLocation) {
            delegate?.compareColumnDidConfirm()
        }
    }
}
