//
//  SettingView.swift
//  Seven Hand Poker
//
//  Settings view for game configuration
//

import SpriteKit

protocol SettingViewDelegate: AnyObject {
    func settingViewDidDismiss()
}

class SettingView: SKNode {
    // MARK: - Properties

    weak var delegate: SettingViewDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var panelBackground: SKSpriteNode!
    private var okButton: SKSpriteNode!
    private var titleLabel: SKLabelNode!

    // Difficulty buttons
    private var easyButton: SKSpriteNode!
    private var mediumButton: SKSpriteNode!
    private var hardButton: SKSpriteNode!

    private var easyLabel: SKLabelNode!
    private var mediumLabel: SKLabelNode!
    private var hardLabel: SKLabelNode!

    private let sceneSize: CGSize

    // MARK: - Init

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()

        setupView()
        updateDifficultySelection()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Background overlay (semi-transparent)
        backgroundOverlay = SKSpriteNode(color: .black, size: sceneSize)
        backgroundOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        backgroundOverlay.alpha = 0.7
        backgroundOverlay.zPosition = 100
        addChild(backgroundOverlay)

        // Panel background
        panelBackground = SKSpriteNode(imageNamed: "panel_large")
        panelBackground.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        panelBackground.zPosition = 101
        panelBackground.size = CGSize(width: 600, height: 400)
        addChild(panelBackground)

        // Title
        titleLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        titleLabel.text = "Settings"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 130)
        titleLabel.zPosition = 102
        addChild(titleLabel)

        // Difficulty title
        let difficultyLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        difficultyLabel.text = "AI Difficulty"
        difficultyLabel.fontSize = 28
        difficultyLabel.fontColor = .white
        difficultyLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 60)
        difficultyLabel.zPosition = 102
        addChild(difficultyLabel)

        // Easy button
        easyButton = SKSpriteNode(imageNamed: "slot")
        easyButton.position = CGPoint(x: sceneSize.width / 2 - 150, y: sceneSize.height / 2 - 10)
        easyButton.size = CGSize(width: 120, height: 80)
        easyButton.zPosition = 102
        easyButton.name = "easyButton"
        addChild(easyButton)

        easyLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        easyLabel.text = "Easy"
        easyLabel.fontSize = 24
        easyLabel.fontColor = .white
        easyLabel.verticalAlignmentMode = .center
        easyLabel.position = CGPoint(x: 0, y: 0)
        easyLabel.zPosition = 1
        easyButton.addChild(easyLabel)

        // Medium button
        mediumButton = SKSpriteNode(imageNamed: "slot")
        mediumButton.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 - 10)
        mediumButton.size = CGSize(width: 120, height: 80)
        mediumButton.zPosition = 102
        mediumButton.name = "mediumButton"
        addChild(mediumButton)

        mediumLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        mediumLabel.text = "Medium"
        mediumLabel.fontSize = 24
        mediumLabel.fontColor = .white
        mediumLabel.verticalAlignmentMode = .center
        mediumLabel.position = CGPoint(x: 0, y: 0)
        mediumLabel.zPosition = 1
        mediumButton.addChild(mediumLabel)

        // Hard button
        hardButton = SKSpriteNode(imageNamed: "slot")
        hardButton.position = CGPoint(x: sceneSize.width / 2 + 150, y: sceneSize.height / 2 - 10)
        hardButton.size = CGSize(width: 120, height: 80)
        hardButton.zPosition = 102
        hardButton.name = "hardButton"
        addChild(hardButton)

        hardLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        hardLabel.text = "Hard"
        hardLabel.fontSize = 24
        hardLabel.fontColor = .white
        hardLabel.verticalAlignmentMode = .center
        hardLabel.position = CGPoint(x: 0, y: 0)
        hardLabel.zPosition = 1
        hardButton.addChild(hardLabel)

        // OK button
        okButton = SKSpriteNode(imageNamed: "panel_ok_btn")
        okButton.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 - 140)
        okButton.size = CGSize(width: 150, height: 80)
        okButton.zPosition = 102
        okButton.name = "okButton"
        addChild(okButton)

        // Enable user interaction
        isUserInteractionEnabled = true
    }

    private func updateDifficultySelection() {
        let currentLevel = ComputerAI.shared.getLevel()

        // Reset all buttons
        easyButton.color = .white
        easyButton.colorBlendFactor = 0
        mediumButton.color = .white
        mediumButton.colorBlendFactor = 0
        hardButton.color = .white
        hardButton.colorBlendFactor = 0

        // Highlight selected difficulty
        switch currentLevel {
        case 0:
            easyButton.color = .green
            easyButton.colorBlendFactor = 0.9
        case 1:
            mediumButton.color = .yellow
            mediumButton.colorBlendFactor = 0.9
        case 2:
            hardButton.color = .red
            hardButton.colorBlendFactor = 0.9
        default:
            break
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "easyButton" || node.parent?.name == "easyButton" {
                easyButton.alpha = 0.7
            }
            if node.name == "mediumButton" || node.parent?.name == "mediumButton" {
                mediumButton.alpha = 0.7
            }
            if node.name == "hardButton" || node.parent?.name == "hardButton" {
                hardButton.alpha = 0.7
            }
            if node.name == "okButton" || node.parent?.name == "okButton" {
                okButton.alpha = 0.7
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        // Reset alpha
        easyButton.alpha = 1.0
        mediumButton.alpha = 1.0
        hardButton.alpha = 1.0
        okButton.alpha = 1.0

        for node in touchedNodes {
            if node.name == "easyButton" || node.parent?.name == "easyButton" {
                ComputerAI.shared.setLevel(0)
                updateDifficultySelection()
            }
            if node.name == "mediumButton" || node.parent?.name == "mediumButton" {
                ComputerAI.shared.setLevel(1)
                updateDifficultySelection()
            }
            if node.name == "hardButton" || node.parent?.name == "hardButton" {
                ComputerAI.shared.setLevel(2)
                updateDifficultySelection()
            }
            if node.name == "okButton" || node.parent?.name == "okButton" {
                dismiss()
            }
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        removeFromParent()
        delegate?.settingViewDidDismiss()
    }
}
