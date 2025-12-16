//
//  DeckConfirmationView.swift
//  Seven Hand Poker
//
//  Confirmation view for selected cards
//

import SpriteKit

protocol DeckConfirmationDelegate: AnyObject {
    func confirmationDidConfirm()
    func confirmationDidCancel()
    func confirmationDidDismiss()
}

class DeckConfirmationView: SKNode {

    weak var delegate: DeckConfirmationDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var dialogBox: SKSpriteNode!
    private var titleLabel: SKLabelNode!
    private var cardTypeLabel: SKLabelNode!
    private var confirmButton: SKSpriteNode!
    private var cancelButton: SKSpriteNode!
    private var okayButton: SKSpriteNode!
    private var cardDisplayNodes: [SKSpriteNode] = []

    private let dialogWidth: CGFloat = 600
    private let dialogHeight: CGFloat = 400
    private let cardScale: CGFloat = 1

    private var isViewOnlyMode: Bool = false

    init(sceneSize: CGSize, viewOnly: Bool = false) {
        super.init()

        self.isViewOnlyMode = viewOnly
        self.zPosition = 1000
        self.isUserInteractionEnabled = true

        setupOverlay(sceneSize: sceneSize)
        setupDialog(sceneSize: sceneSize)
        setupButtons()
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
        // Dialog box
        dialogBox = SKSpriteNode(imageNamed: "panel_s")
        dialogBox.size = CGSize(width: dialogWidth, height: dialogHeight)
        dialogBox.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        dialogBox.zPosition = 1

        addChild(dialogBox)

        // Card type label
        cardTypeLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        cardTypeLabel.text = ""
        cardTypeLabel.fontSize = 30
        cardTypeLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        cardTypeLabel.position = CGPoint(x: 0, y: dialogHeight / 2 - 90)
        cardTypeLabel.zPosition = 2
        dialogBox.addChild(cardTypeLabel)
    }

    private func setupButtons() {
        if isViewOnlyMode {
            // Okay button only (centered)
            okayButton = createButton(imageName: "panel_ok_btn")
            okayButton.position = CGPoint(x: 0, y: -dialogHeight / 2 + 90)
            okayButton.name = "okayBtn"
            okayButton.zPosition = 2
            dialogBox.addChild(okayButton)
        } else {
            // Confirm button
            confirmButton = createButton(imageName: "panel_yes_btn")
            confirmButton.position = CGPoint(x: 140, y: -dialogHeight / 2 + 90)
            confirmButton.name = "confirmBtn"
            confirmButton.zPosition = 2
            dialogBox.addChild(confirmButton)

            // Cancel button
            cancelButton = createButton(imageName: "panel_no_btn")
            cancelButton.position = CGPoint(x: -140, y: -dialogHeight / 2 + 90)
            cancelButton.name = "cancelBtn"
            cancelButton.zPosition = 2
            dialogBox.addChild(cancelButton)
        }
    }

    private func createButton(imageName: String) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: imageName)
        button.size = CGSize(width: 240, height: 120)
        let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = "label"
        button.addChild(label)

        return button
    }

    // MARK: - Public Methods

    func showCards(_ cards: [CardSprite], cardType: CardType) {
        // Clear previous card displays
        for node in cardDisplayNodes {
            node.removeFromParent()
        }
        cardDisplayNodes.removeAll()

        // Display selected cards
        let totalWidth = CGFloat(cards.count - 1) * 90
        let startX = -totalWidth / 2

        for (index, card) in cards.enumerated() {
            // Always show face-up texture
            let cardCopy = SKSpriteNode(texture: card.getFaceUpTexture())
            cardCopy.setScale(cardScale)
            cardCopy.position = CGPoint(x: startX + CGFloat(index) * 90, y: 30)
            cardCopy.zPosition = CGFloat(3 + index)
            dialogBox.addChild(cardCopy)
            cardDisplayNodes.append(cardCopy)
        }

        // Update card type label
        cardTypeLabel.text = cardType.displayName

        // Color based on card type strength
        switch cardType {
        case .straightFlush, .fourOfAKind:
            cardTypeLabel.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Red for strong
        case .fullHouse, .flush, .straight:
            cardTypeLabel.fontColor = SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0) // Orange
        case .threeOfAKind, .twoPair:
            cardTypeLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0) // Yellow
        case .onePair:
            cardTypeLabel.fontColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0) // Light blue
        case .highCard:
            cardTypeLabel.fontColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) // Gray
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Check if touching buttons (need to convert to dialog coordinate)
        let dialogLocation = touch.location(in: dialogBox)

        if isViewOnlyMode {
            if okayButton.contains(dialogLocation) {
                okayButton.alpha = 0.7
            }
        } else {
            if confirmButton.contains(dialogLocation) {
                confirmButton.alpha = 0.7
            } else if cancelButton.contains(dialogLocation) {
                cancelButton.alpha = 0.7
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let dialogLocation = touch.location(in: dialogBox)

        if isViewOnlyMode {
            okayButton.alpha = 1.0
            if okayButton.contains(dialogLocation) {
                delegate?.confirmationDidDismiss()
            }
        } else {
            confirmButton.alpha = 1.0
            cancelButton.alpha = 1.0

            if confirmButton.contains(dialogLocation) {
                delegate?.confirmationDidConfirm()
            } else if cancelButton.contains(dialogLocation) {
                delegate?.confirmationDidCancel()
            }
        }
    }
}
