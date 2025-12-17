//
//  DialogBoxView.swift
//  Seven Hand Poker
//
//  Simple dialog box view for displaying messages
//

import SpriteKit

protocol DialogBoxDelegate: AnyObject {
    func dialogBoxDidDismiss()
}

enum DialogBoxStyle {
    case center
    case downward   // Image shifted down 10px
    case upward     // Image shifted up 10px
}

class DialogBoxView: SKNode {

    weak var delegate: DialogBoxDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var dialogBox: SKSpriteNode!
    private var textLabel: SKLabelNode!

    private var isEnabled: Bool = true
    private var sceneSize: CGSize = .zero
    private var isBlockTurn: Bool = false

    private let dialogWidth: CGFloat = 400
    private let dialogHeight: CGFloat = 200

    init(sceneSize: CGSize, style: DialogBoxStyle = .center, text: String = "", blockTurn: Bool = false) {
        super.init()

        self.sceneSize = sceneSize
        self.zPosition = 800
        self.isUserInteractionEnabled = true
        isBlockTurn = blockTurn

        setupOverlay(sceneSize: sceneSize)
        setupDialog(sceneSize: sceneSize, style: style)
        setupText(text: text)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupOverlay(sceneSize: CGSize) {
        // Full-screen transparent overlay to capture all touches when enabled
        backgroundOverlay = SKSpriteNode(color: .clear, size: sceneSize)
        backgroundOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        backgroundOverlay.zPosition = 0
        backgroundOverlay.name = "dialogOverlay"
        addChild(backgroundOverlay)
    }

    private func setupDialog(sceneSize: CGSize, style: DialogBoxStyle) {
        let imageName: String
        var yOffset: CGFloat = 0

        switch style {
        case .center:
            imageName = "dialogbox_center"
        case .downward:
            imageName = "dialogbox_downward"
            yOffset = -10
        case .upward:
            imageName = "dialogbox_upward"
            yOffset = 10
        }

        dialogBox = SKSpriteNode(imageNamed: imageName)
        dialogBox.size = CGSize(width: dialogWidth, height: dialogHeight)
        dialogBox.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + yOffset)
        dialogBox.zPosition = 1
        addChild(dialogBox)
    }

    private func setupText(text: String) {
        textLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        textLabel.text = text
        textLabel.fontSize = 24
        textLabel.fontColor = .white
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = dialogWidth - 40
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.position = CGPoint(x: 0, y: 0)
        textLabel.zPosition = 2
        dialogBox.addChild(textLabel)
    }

    // MARK: - Public Methods

    func setText(_ text: String) {
        textLabel.text = text
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        // When enabled, show overlay to capture all touches
        // When disabled, hide overlay so touches pass through
        backgroundOverlay.isHidden = !enabled
        self.isUserInteractionEnabled = enabled
    }

    func getEnabled() -> Bool {
        return isEnabled
    }
    
    func getBlockTurn() -> Bool {
        return isBlockTurn
    }

    // MARK: - Touch Handling

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        delegate?.dialogBoxDidDismiss()
    }
}
