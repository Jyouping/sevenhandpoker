//
//  ViewMgr.swift
//  Seven Hand Poker
//
//  Converted to Swift from ViewMgr.h/m
//

import UIKit

class ViewMgr: UIViewController, SwitchViewDelegate {
    // MARK: - Properties

    private var currentView: UIViewController?
    private var matchConnector: MatchConnector?
    private var viewType: Int = 0
    private var startPlayer: Int = PlayerType.player1.rawValue

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initViewMgr()
    }

    private func initViewMgr() {
        viewType = 0
        currentView = nil
        view.frame = CGRect(x: 0, y: 0, width: 480, height: 320)

        // Start with intro view
        switchView(4)
    }

    // MARK: - View Switching

    func switchView(_ viewType: Int) {
        self.viewType = viewType
        var newView: UIViewController?

        switch viewType {
        case 5: // Init view
            GCHelper.sharedInstance.authenticateLocalUser()

            matchConnector = MatchConnector.sharedInstance
            matchConnector?.viewMgrDelegate = self
            GCHelper.sharedInstance.delegate = matchConnector

            startPlayer = PlayerType.player1.rawValue
            fallthrough

        case 0: // Menu
            self.viewType = 0
            let menu = MenuViewController()
            matchConnector?.menuDelegate = menu
            menu.startGameDelegate = self
            newView = menu

        case 1: // Single player game
            let gameVC = SevenHandPokerViewController()
            gameVC.viewMgrDelegate = self
            gameVC.multiPlayer = false
            gameVC.startPlayer = startPlayer
            gameVC.tutorial = 0
            gameVC.aiLevel = LocalData.sharedInstance.getValue(forKey: "AILevel")
            matchConnector?.menuDelegate = nil

            // Reverse start player for next game
            if startPlayer == PlayerType.player1.rawValue {
                startPlayer = PlayerType.player2.rawValue
            } else {
                startPlayer = PlayerType.player1.rawValue
            }
            newView = gameVC

        case 2: // Achievement view
            let achieveVC = AchievementView()
            achieveVC.viewMgrDelegate = self
            matchConnector?.menuDelegate = nil
            newView = achieveVC

        case 4: // Intro
            let introVC = IntroView()
            introVC.viewMgrDelegate = self
            newView = introVC

        case 6: // Tutorial
            let gameVC = SevenHandPokerViewController()
            gameVC.viewMgrDelegate = self
            gameVC.multiPlayer = false
            gameVC.startPlayer = PlayerType.player1.rawValue
            gameVC.tutorial = 1
            matchConnector?.menuDelegate = nil
            newView = gameVC

        default:
            break
        }

        if let currentView = currentView {
            currentView.view.removeFromSuperview()
        }

        currentView = newView

        if let newView = newView {
            view.addSubview(newView.view)
        }
    }

    func refresh() {
        if viewType == 0 {
            (currentView as? MenuViewController)?.refresh()
        } else if viewType == 1 || viewType == 3 {
            (currentView as? SevenHandPokerViewController)?.refresh()
        }
    }

    // MARK: - SwitchViewDelegate

    func switchViewAction(_ viewType: Int) {
        switchView(viewType)
    }

    func startMultiPlayerGame() {
        viewType = 3
        let gameVC = SevenHandPokerViewController()
        gameVC.viewMgrDelegate = self
        gameVC.multiPlayer = true
        gameVC.matchConnector = matchConnector
        matchConnector?.gameMainDelegate = gameVC
        matchConnector?.menuDelegate = nil

        if let currentView = currentView {
            currentView.view.removeFromSuperview()
        }

        currentView = gameVC
        view.addSubview(gameVC.view)
    }

    func getCurrentView() -> UIViewController? {
        return currentView
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscapeLeft, .landscapeRight]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    // MARK: - Memory Warning

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
        // Cleanup handled by ARC
    }
}
