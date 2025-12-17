//
//  AchievementView.swift
//  Seven Hand Poker
//
//  Achievement view displaying player statistics
//

import SpriteKit

protocol AchievementViewDelegate: AnyObject {
    func achievementViewDidDismiss()
}

class AchievementView: SKNode {
    // MARK: - Properties

    weak var delegate: AchievementViewDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var panelBackground: SKSpriteNode!
    private var okButton: SKSpriteNode!

    private let sceneSize: CGSize
    private let fontName = "MarkerFelt-Wide"

    // MARK: - Init

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()

        setupView()
        displayStats()
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
        panelBackground.size = CGSize(width: 700, height: 550)
        addChild(panelBackground)

        // Subtitle - Single Player
        let subtitleLabel = SKLabelNode(fontNamed: fontName)
        subtitleLabel.text = "- Single Player -"
        subtitleLabel.fontSize = 22
        subtitleLabel.fontColor = SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 180)
        subtitleLabel.zPosition = 102
        addChild(subtitleLabel)

        // OK button
        okButton = SKSpriteNode(imageNamed: "panel_ok_btn")
        okButton.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 - 190)
        okButton.size = CGSize(width: 150, height: 80)
        okButton.zPosition = 102
        okButton.name = "okButton"
        addChild(okButton)

        // Enable user interaction
        isUserInteractionEnabled = true
    }

    private func displayStats() {
        let dataMgr = UserLocalDataMgr.shared

        // Column headers
        let headerY = sceneSize.height / 2 + 120
        let startX = sceneSize.width / 2 - 250

        // Header row
        createLabel(text: "Difficulty", x: startX, y: headerY, fontSize: 20, color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0), bold: true)
        createLabel(text: "Wins", x: startX + 180, y: headerY, fontSize: 20, color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0), bold: true)
        createLabel(text: "Losses", x: startX + 280, y: headerY, fontSize: 20, color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0), bold: true)
        createLabel(text: "Win Rate", x: startX + 400, y: headerY, fontSize: 20, color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0), bold: true)

        // Divider line
        let divider = SKShapeNode(rectOf: CGSize(width: 500, height: 2))
        divider.fillColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: sceneSize.width / 2, y: headerY - 20)
        divider.zPosition = 102
        addChild(divider)

        // Easy stats
        let easyY = headerY - 55
        createDifficultyRow(
            difficulty: "Easy",
            difficultyColor: SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0),
            wins: dataMgr.getWins(difficulty: 0),
            losses: dataMgr.getLosses(difficulty: 0),
            winRate: dataMgr.getWinRate(difficulty: 0),
            y: easyY,
            startX: startX
        )

        // Medium stats
        let mediumY = headerY - 105
        createDifficultyRow(
            difficulty: "Medium",
            difficultyColor: SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),
            wins: dataMgr.getWins(difficulty: 1),
            losses: dataMgr.getLosses(difficulty: 1),
            winRate: dataMgr.getWinRate(difficulty: 1),
            y: mediumY,
            startX: startX
        )

        // Hard stats
        let hardY = headerY - 155
        createDifficultyRow(
            difficulty: "Hard",
            difficultyColor: SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
            wins: dataMgr.getWins(difficulty: 2),
            losses: dataMgr.getLosses(difficulty: 2),
            winRate: dataMgr.getWinRate(difficulty: 2),
            y: hardY,
            startX: startX
        )

        // Total summary
        let totalY = headerY - 220
        let divider2 = SKShapeNode(rectOf: CGSize(width: 500, height: 2))
        divider2.fillColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        divider2.strokeColor = .clear
        divider2.position = CGPoint(x: sceneSize.width / 2, y: totalY + 25)
        divider2.zPosition = 102
        addChild(divider2)

        let totalWins = dataMgr.getWins(difficulty: 0) + dataMgr.getWins(difficulty: 1) + dataMgr.getWins(difficulty: 2)
        let totalLosses = dataMgr.getLosses(difficulty: 0) + dataMgr.getLosses(difficulty: 1) + dataMgr.getLosses(difficulty: 2)
        let totalGames = totalWins + totalLosses
        let totalWinRate = totalGames > 0 ? (Double(totalWins) / Double(totalGames)) * 100.0 : 0.0

        createDifficultyRow(
            difficulty: "Total",
            difficultyColor: .white,
            wins: totalWins,
            losses: totalLosses,
            winRate: totalWinRate,
            y: totalY,
            startX: startX
        )
    }

    private func createDifficultyRow(difficulty: String, difficultyColor: SKColor, wins: Int, losses: Int, winRate: Double, y: CGFloat, startX: CGFloat) {
        // Difficulty name
        createLabel(text: difficulty, x: startX, y: y, fontSize: 22, color: difficultyColor, bold: false)

        // Wins
        createLabel(text: "\(wins)", x: startX + 180, y: y, fontSize: 22, color: .white, bold: false)

        // Losses
        createLabel(text: "\(losses)", x: startX + 280, y: y, fontSize: 22, color: .white, bold: false)

        // Win Rate
        let winRateText = String(format: "%.1f%%", winRate)
        let winRateColor = getWinRateColor(winRate)
        createLabel(text: winRateText, x: startX + 400, y: y, fontSize: 22, color: winRateColor, bold: false)
    }

    private func createLabel(text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat, color: SKColor, bold: Bool) {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: x, y: y)
        label.zPosition = 102
        addChild(label)
    }

    private func getWinRateColor(_ winRate: Double) -> SKColor {
        if winRate >= 70 {
            return SKColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)  // Green
        } else if winRate >= 50 {
            return SKColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0)  // Yellow
        } else if winRate > 0 {
            return SKColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0)  // Orange
        } else {
            return SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)  // Gray (no games)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "okButton" || node.parent?.name == "okButton" {
                okButton.alpha = 0.7
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        okButton.alpha = 1.0

        for node in touchedNodes {
            if node.name == "okButton" || node.parent?.name == "okButton" {
                dismiss()
            }
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        removeFromParent()
        delegate?.achievementViewDidDismiss()
    }
}
