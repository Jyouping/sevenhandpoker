//
//  SplashScene.swift
//  Seven Hand Poker
//
//  Splash screen with animated coin
//

import SpriteKit

class SplashScene: SKScene {

    private var animatedCoin: AnimatedCoin!

    class func newSplashScene() -> SplashScene {
        let scene = SplashScene(size: CGSize(width: 1400, height: 640))
        scene.scaleMode = .aspectFit
        return scene
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupCoin()
        startAnimation()
        
        view.showsFPS = false
        view.showsNodeCount = false
        view.showsPhysics = false
        view.showsDrawCount = false
        view.showsFields = false
    }

    // MARK: - Setup

    private func setupBackground() {
        backgroundColor = .black
    }

    private func setupCoin() {
        animatedCoin = AnimatedCoin()
        animatedCoin.position = CGPoint(x: size.width / 2, y: size.height / 2)
        animatedCoin.setScale(2.0)
        animatedCoin.zPosition = 10
        addChild(animatedCoin)
    }

    // MARK: - Animation

    private func startAnimation() {
        // Play coin animation once, then transition to main menu
        animatedCoin.playOnce(duration: 1.5) { [weak self] in
            self?.transitionToMainMenu()
        }
    }

    private func transitionToMainMenu() {
        let mainMenu = MainMenuScene.newMenuScene()
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenu, transition: transition)
    }
}
