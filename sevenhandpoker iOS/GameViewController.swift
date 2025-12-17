//
//  GameViewController.swift
//  sevenhandpoker iOS
//
//  Created by Shunping Chiu on 12/14/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = SplashScene.newSplashScene()

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = false
        skView.showsFPS = false
        skView.showsNodeCount = false
        
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
