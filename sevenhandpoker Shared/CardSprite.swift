//
//  CardSprite.swift
//  Seven Hand Poker
//
//  SpriteKit card sprite based on old_backup CardUI
//

import SpriteKit

protocol CardSpriteDelegate: AnyObject {
    func cardClicked(_ card: CardSprite)
}

class CardSprite: SKSpriteNode {
    // Card attributes
    private var _number: Int = 0
    private var _color: Int = 0
    private var _owner: Int = 0  // 1 = player1, 2 = player2
    private var _faceUp: Bool = false
    private var _selected: Bool = false
    private var _enabled: Bool = false

    var deckPos: Int = 0
    var pokerCol: Int = -1  // Which column in poker slots (-1 = not placed)

    weak var delegate: CardSpriteDelegate?

    // MARK: - Initialization

    convenience init(card: Card, owner: Int, faceUp: Bool) {
        let imageName = card.getImageName(faceUp: faceUp)
        let texture = SKTexture(imageNamed: imageName)
        self.init(texture: texture)

        _number = card.getNumber()
        _color = card.getColor()
        _owner = owner
        _faceUp = faceUp
        _selected = false
        _enabled = false

        self.isUserInteractionEnabled = true
        self.name = "card"
    }

    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Accessors

    func getNumber() -> Int { return _number }
    func getColor() -> Int { return _color }
    func getOwner() -> Int { return _owner }
    func getFaceUp() -> Bool { return _faceUp }
    func getSelected() -> Bool { return _selected }
    func isEnabled() -> Bool { return _enabled }

    /// Get the face-up texture for this card
    func getFaceUpTexture() -> SKTexture {
        let card = Card(color: _color, number: _number)
        let imageName = card.getImageName(faceUp: true)
        return SKTexture(imageNamed: imageName)
    }

    func setEnabled(_ enabled: Bool) {
        _enabled = enabled
    }

    func setFaceUp(_ faceUp: Bool) {
        guard _faceUp != faceUp else { return }
        _faceUp = faceUp

        let card = Card(color: _color, number: _number)
        let imageName = card.getImageName(faceUp: faceUp)

        // Flip animation
        let flipOut = SKAction.scaleX(to: 0, duration: 0.15)
        let changeTexture = SKAction.setTexture(SKTexture(imageNamed: imageName))
        let flipIn = SKAction.scaleX(to: 1, duration: 0.15)
        run(SKAction.sequence([flipOut, changeTexture, flipIn]))
    }

    func setSelected(_ selected: Bool) {
        guard _selected != selected else { return }
        _selected = selected

        // Move up/down based on selection
        let offset: CGFloat = _owner == 1 ? 15 : -15
        let targetY = position.y + (selected ? offset : -offset)
        let moveAction = SKAction.moveTo(y: targetY, duration: 0.1)
        run(moveAction)
    }

    func toggleSelected() {
        setSelected(!_selected)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _enabled {
            toggleSelected()
            delegate?.cardClicked(self)
        }
    }

    // MARK: - Animation

    func moveTo(position: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        let moveAction = SKAction.move(to: position, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        if let completion = completion {
            run(SKAction.sequence([moveAction, SKAction.run(completion)]))
        } else {
            run(moveAction)
        }
    }
}
