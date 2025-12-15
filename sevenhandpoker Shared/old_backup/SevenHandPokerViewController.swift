//
//  SevenHandPokerViewController.swift
//  Seven Hand Poker
//
//  Converted to Swift from Seven_Hand_PokerViewController.h/m
//

import UIKit

class SevenHandPokerViewController: UIViewController, CardUIDelegate, GameMainDelegate {
    // MARK: - Properties

    var matchConnector: MatchConnector?
    var multiPlayer: Bool = false
    var seed: Int = 0
    weak var viewMgrDelegate: SwitchViewDelegate?

    private var renderTimer: Timer?
    private var gameState: Int = 0
    private var deckMgr: DeckMgr!
    private var comAI: ComputerAI!
    var startPlayer: Int = PlayerType.player1.rawValue
    private var tickCnt: Int = 0
    private var stateCnt: Int = 0
    private var lastChangedPos: Int = -1
    private var lastWinner: Int = 0
    private var lastSort: Int = 0

    @IBOutlet weak var playCardDialog: UIView!
    @IBOutlet weak var compareCardDialog: UIView!
    @IBOutlet weak var cardTypeTextView: UILabel!
    @IBOutlet weak var player1CardTypeTextView: UILabel!
    @IBOutlet weak var player2CardTypeTextView: UILabel!

    @IBOutlet weak var usrWinView: UIView!
    @IBOutlet weak var usrLoseView: UIView!
    @IBOutlet weak var askDialogView: UIView!
    @IBOutlet weak var compareDialogView: UIView!
    @IBOutlet weak var askDialogText: UILabel!

    @IBOutlet weak var confirmCompBtn: UIButton!
    @IBOutlet weak var playCardYes: UIButton!
    @IBOutlet weak var playCardNo: UIButton!
    @IBOutlet weak var viewCardOkay: UIButton!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var tutorialViewBtn: UIButton!
    @IBOutlet weak var tutorialBg: UIImageView!

    private var putDeckBtn: [UIButton] = []
    private var sendCardBtn: RotateButton!
    private var head: [HeadFigure] = []
    private var slot: [UIImageView] = []
    private var coinArray: [CoinUI] = []
    private var renderCnt: Int = 0

    var tutorial: Int = 0
    private var nxtStateTutorial: Int = 0
    private var tutorialSubstate: Int = 0
    private var stopTutorialSubstate: Int = 0

    private var achGetView: GetAchievementView?
    private var showAds: Bool = false
    var aiLevel: Int = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initObjects()
    }

    deinit {
        // Cleanup handled by viewWillDisappear
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        finiObjects()
    }

    // MARK: - Initialization

    private func initObjects() {
        tickCnt = 0
        stateCnt = 0
        gameState = 0
        lastChangedPos = -1
        lastWinner = 0
        if startPlayer != PlayerType.player1.rawValue && startPlayer != PlayerType.player2.rawValue {
            startPlayer = PlayerType.player1.rawValue
        }
        lastSort = 0

        deckMgr = DeckMgr.sharedInstance
        deckMgr.clickDelegate = self

        playCardDialog?.isHidden = true
        compareDialogView?.isHidden = true

        comAI = ComputerAI.sharedInstance
        comAI.setLevel(aiLevel)

        // Setup slots
        slot = []
        for i in 0..<14 {
            let slotView = UIImageView(image: UIImage(named: "slot_480x320.png"))
            view.addSubview(slotView)
            slotView.frame = CGRect(x: 63 + (i % 7) * 50, y: 63 + 120 * (i / 7), width: 50, height: 70)
            slot.append(slotView)
        }

        // Setup deck buttons
        putDeckBtn = []
        for i in 0..<7 {
            let btn = UIButton(type: .custom)
            btn.frame = CGRect(x: 60 + i * 51, y: 67, width: 50, height: 63)
            btn.setImage(UIImage(named: "cardposition_960.png"), for: .normal)
            btn.isHidden = true
            btn.tag = i
            btn.addTarget(self, action: #selector(placeToPos(_:)), for: .touchDown)
            view.addSubview(btn)
            putDeckBtn.append(btn)
        }

        // Setup coins
        coinArray = []
        for i in 0..<7 {
            let newCoin = CoinUI(pos: i)
            view.addSubview(newCoin)
            coinArray.append(newCoin)
        }

        // Setup heads
        head = []
        for i in 0..<2 {
            let headFig = HeadFigure(player: i + 1)
            headFig.clickDelegate = self
            view.addSubview(headFig)
            if i == 0 {
                headFig.center = CGPoint(x: 50 - 100, y: 200)
            } else {
                headFig.center = CGPoint(x: 430 + 100, y: 60)
            }
            head.append(headFig)
        }

        // Set AI name based on level
        if aiLevel == 0 {
            head[1].setName("ZZ Dog")
        } else if aiLevel == 1 {
            head[1].setName("QQ Dog")
        } else {
            head[1].setName("AA Dog")
        }

        // Setup send card button
        sendCardBtn = RotateButton(type: 2)
        sendCardBtn.center = CGPoint(x: 420, y: 160)
        sendCardBtn.mainButton.addTarget(self, action: #selector(playCard(_:)), for: .touchUpInside)
        view.addSubview(sendCardBtn)
        sendCardBtn.isHidden = true

        if let compareDialogView = compareDialogView {
            view.addSubview(compareDialogView)
        }

        compareCardDialog?.center = view.center

        renderCnt = 0

        // Stop background music
        SoundMgr.sharedInstance.stopBackgroundMusic()

        // Achievement view
        achGetView = GetAchievementView()
        achGetView?.view.center = view.center

        if multiPlayer {
            tutorial = 0
        }

        // Multiplayer setup
        if multiPlayer {
            if matchConnector?.isPlayer1 == true {
                seed = Int.random(in: 0..<10000)
                srand48(seed)
                matchConnector?.sendSeedNumber(seed)
                renderTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
                startPlayer = PlayerType.player1.rawValue
            } else {
                startPlayer = PlayerType.player2.rawValue
            }
            confirmCompBtn?.isHidden = true
            head[1].setName(GCHelper.sharedInstance.otherPlayerAlias ?? "Opponent")
        } else {
            seed = Int.random(in: 0..<10000)
            renderTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        }

        // Handle ads
        showAds = false
        if tutorial != 1 {
            if LocalData.sharedInstance.getValue(forKey: "AdvanceFeature") != 1 {
                showAds = true
            }
        }
        if multiPlayer {
            showAds = false
        }
        if showAds {
            view.addSubview(AdView.sharedInstance)
            AdView.sharedInstance.setAds(viewController: self)
        }
    }

    private func finiObjects() {
        renderTimer?.invalidate()
        coinArray.removeAll()
    }

    // MARK: - GameMainDelegate

    func setSeed(_ num: Int) {
        seed = num
        srand48(seed)
        renderTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    func selectCardDeck(_ pos: Int) {
        guard pos < deckMgr.player2Deck.count else { return }
        deckMgr.player2Deck[pos].changeSelect()
    }

    func setSortCard(_ type: Int) {
        if type == 0 {
            deckMgr.sortDeck(deck: &deckMgr.player2Deck, type: 0)
        } else if type == 1 {
            deckMgr.sortDeck(deck: &deckMgr.player2Deck, type: 1)
        }
    }

    func acceptSubmitCard() {
        showPlaceBtn()
        view.bringSubviewToFront(playCardDialog)
        gameState = 8
    }

    func setPlacePos(_ pos: Int) {
        // Handle position setting from network
        gameState = 4
        lastChangedPos = pos
        stateCnt = 0
    }

    func askConfirmReset() {
        askDialogText?.text = "\(GCHelper.sharedInstance.otherPlayerAlias ?? "Opponent") asks for replay the game"
        usrWinView?.isHidden = true
        usrLoseView?.isHidden = true
        if let askDialogView = askDialogView {
            view.addSubview(askDialogView)
            askDialogView.center = CGPoint(x: 240, y: 160)
        }
    }

    func setGameRestart() {
        matchConnector?.isPlayer1 = !(matchConnector?.isPlayer1 ?? true)
        viewMgrDelegate?.startMultiPlayerGame()
    }

    // MARK: - Timer

    @objc private func tick() {
        tickCnt += 1
        if tickCnt % 6 == 0 && tickCnt > 0 {
            gameStateMachine()
        }
        if tickCnt % 2200 == 800 {
            if showAds {
                AdView.sharedInstance.showAds()
            }
        }
        render()

        if showAds {
            AdView.sharedInstance.bringToFront()
        }
    }

    private func render() {
        // Render deck
        renderCnt += 1
        if renderCnt == 4 {
            slowRender()
            renderCnt = 0
        }
    }

    private func slowRender() {
        for coin in coinArray {
            let i = Int.random(in: 0..<400)
            if i == 1 {
                coin.beginShine()
            }
            coin.render()
        }
    }

    // MARK: - Game State Machine

    private func gameStateMachine() {
        var state = gameState
        if tutorial == 1 {
            state += 100
        }

        switch state {
        case 0: // Init state
            if multiPlayer {
                LocalData.sharedInstance.incrementMultiplayTimes()
            } else {
                let times = LocalData.sharedInstance.getValue(forKey: "SingleplayTimes")
                LocalData.sharedInstance.setValue(times + 1, forKey: "SingleplayTimes")
            }
            LocalData.sharedInstance.writeData()

            deckMgr.initDeck()
            deckMgr.setSeed(seed)
            gameState = 1

        case 1: // Distribution
            SoundMgr.sharedInstance.playTick()
            // Simplified distribution logic
            if startPlayer == PlayerType.player1.rawValue {
                gameState = 2
                stateCnt = 0
                head[0].changeAnimationState(0)
                head[1].changeAnimationState(1)
            } else {
                gameState = 6
                head[0].changeAnimationState(1)
                head[1].changeAnimationState(0)
            }

        case 2: // Wait for Player 1's action
            if stateCnt == 0 {
                head[0].changeFigure(0)
            }
            if stateCnt < 10 {
                stateCnt += 1
            }
            if stateCnt == 8 {
                head[0].showSpin(true)
            }

        case 20: // User win
            if let usrWinView = usrWinView {
                view.addSubview(usrWinView)
                usrWinView.center = view.center
            }
            SoundMgr.sharedInstance.playVictory()
            if showAds {
                AdView.sharedInstance.hideAds()
            }
            gameState = 21
            handleWinAchievements()

        case 30: // User lose
            if let usrLoseView = usrLoseView {
                view.addSubview(usrLoseView)
                usrLoseView.center = CGPoint(x: 240, y: 160)
            }
            SoundMgr.sharedInstance.playLose()
            if showAds {
                AdView.sharedInstance.hideAds()
            }
            handleLoseStats()
            gameState = 31

        default:
            break
        }

        if tutorial == 1 {
            tutorialState(gameState)
        }
    }

    private func handleWinAchievements() {
        if multiPlayer {
            LocalData.sharedInstance.incrementMultiplayWins()
            let wins = LocalData.sharedInstance.getValue(forKey: "MultiplayWins")
            GCHelper.sharedInstance.reportScore(wins, forCategory: "com.weiweistudio.7handpoker.leaderboard.mwin")

            if LocalData.sharedInstance.getValue(forKey: "ach_tree") == 0 {
                LocalData.sharedInstance.setAchievement(tree: true)
                achGetView?.setAchievementItem(4)
                if let achView = achGetView?.view {
                    view.addSubview(achView)
                    achView.isHidden = false
                }
                GCHelper.sharedInstance.submitAchievement(identifier: "com.weiweistudio.7handpoker.ach.bubuptree", percentComplete: 100)
            }

            if wins >= 30 && LocalData.sharedInstance.getValue(forKey: "ach_poker") == 0 {
                LocalData.sharedInstance.setAchievement(poker: true)
                achGetView?.setAchievementItem(5)
                if let achView = achGetView?.view {
                    view.addSubview(achView)
                    achView.isHidden = false
                }
                GCHelper.sharedInstance.submitAchievement(identifier: "com.weiweistudio.7handpoker.ach.goldencard", percentComplete: 100)
            }
        } else {
            LocalData.sharedInstance.incrementSingleplayWins()
            let wins = LocalData.sharedInstance.getValue(forKey: "SingleplayWins")
            GCHelper.sharedInstance.reportScore(wins, forCategory: "com.weiweistudio.7handpoker.leaderboard.swin")

            if LocalData.sharedInstance.getValue(forKey: "ach_cake") == 0 {
                LocalData.sharedInstance.setAchievement(cake: true)
                achGetView?.setAchievementItem(3)
                if let achView = achGetView?.view {
                    view.addSubview(achView)
                    achView.isHidden = false
                }
                GCHelper.sharedInstance.submitAchievement(identifier: "com.weiweistudio.7handpoker.ach.parcake", percentComplete: 100)
            }
        }
        LocalData.sharedInstance.writeData()
    }

    private func handleLoseStats() {
        if multiPlayer {
            LocalData.sharedInstance.incrementMultiplayLoses()
        } else {
            LocalData.sharedInstance.incrementSingleplayLoses()
        }
        LocalData.sharedInstance.writeData()
    }

    private func tutorialState(_ state: Int) {
        // Tutorial state handling
    }

    // MARK: - UI Actions

    @IBAction @objc func placeToPos(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        let pos = button.tag

        for btn in putDeckBtn {
            btn.isHidden = true
        }

        if multiPlayer {
            matchConnector?.sendPlacePos(pos)
        }

        gameState = 9
        stateCnt = 0
        lastChangedPos = pos
    }

    private func showPlaceBtn() {
        for i in 0..<7 {
            if deckMgr.getDeckSize(player: 2, col: i) == 0 {
                putDeckBtn[i].isHidden = false
                view.bringSubviewToFront(putDeckBtn[i])
            }
        }
    }

    @IBAction @objc func playCard(_ sender: Any) {
        head[0].setClickEnable(false)
        sendCardBtn.isHidden = true

        playCardDialog?.isHidden = false
        view.bringSubviewToFront(playCardDialog)
    }

    @IBAction func confirmPlayerCard(_ sender: Any) {
        if multiPlayer {
            matchConnector?.sendSubmitCard()
        }
        playCardDialog?.isHidden = true
        head[0].showSpin(false)
        gameState = 3
    }

    @IBAction func cancelPlayerCard(_ sender: Any) {
        playCardDialog?.isHidden = true
        sendCardBtn.isHidden = false
        view.bringSubviewToFront(sendCardBtn)
        gameState = 2
    }

    @IBAction func sortPlayerCard(_ sender: Any) {
        SoundMgr.sharedInstance.playSort()
        if multiPlayer {
            matchConnector?.sendSortCard(lastSort)
        }
        if lastSort == 0 {
            deckMgr.sortDeck(deck: &deckMgr.player1Deck, type: 0)
            lastSort = 1
        } else if lastSort == 1 {
            deckMgr.sortDeck(deck: &deckMgr.player1Deck, type: 1)
            lastSort = 0
        }
    }

    @IBAction func goBackToMenu(_ sender: Any) {
        if multiPlayer {
            GCHelper.sharedInstance.match?.disconnect()
        }
        viewMgrDelegate?.switchViewAction(0)
    }

    @IBAction func reset(_ sender: Any) {
        if !multiPlayer {
            viewMgrDelegate?.switchViewAction(1)
        } else {
            matchConnector?.sendRestartGame()
        }
    }

    @IBAction func confirmComparison(_ sender: Any) {
        compareDialogView?.isHidden = true

        if lastWinner != -1 {
            moveCoinByResult(PlayerType(rawValue: lastWinner) ?? .preserve, pos: lastChangedPos)
        }
        lastWinner = 0
        lastChangedPos = -1

        gameState += 1
        if gameState == 5 {
            head[0].changeAnimationState(1)
        } else if gameState == 9 {
            head[1].changeAnimationState(1)
        }
    }

    @IBAction func viewCardOK(_ sender: Any) {
        viewCardOkay?.isHidden = true
        playCardYes?.isHidden = false
        playCardNo?.isHidden = false
        playCardDialog?.isHidden = true
    }

    @IBAction func tutorialBtnClicked(_ sender: Any) {
        if tutorial != 1 { return }
        tutorialSubstate += 1
        if tutorialSubstate <= stopTutorialSubstate {
            tutorialText(tutorialSubstate)
        }
        if tutorialSubstate > stopTutorialSubstate {
            gameState = nxtStateTutorial
            tutorialView?.isHidden = true
        }
        stateCnt = 0
    }

    @IBAction func hideAchievementView(_ sender: Any) {
        achGetView?.view.isHidden = true
        achGetView?.view.removeFromSuperview()
    }

    @IBAction func confirmRestart(_ sender: Any) {
        matchConnector?.isPlayer1 = !(matchConnector?.isPlayer1 ?? true)
        matchConnector?.sendConfirmReplayGame()
        viewMgrDelegate?.startMultiPlayerGame()
    }

    // MARK: - Tutorial Text

    private func tutorialText(_ subState: Int) {
        tutorialSubstate = subState
        view.bringSubviewToFront(tutorialView)
        tutorialView?.isHidden = false

        let texts = [
            "Welcome to Seven Hand Poker",
            "These are your cards.\n You can tap to pick and unpick.",
            "You can pick 1-5 cards every time \n to form different combinations.",
            "Now let's pick two K cards to form a pair.",
            "Once you've decided your pick,\n The opponent gets to place it.",
            "Theses are the opponent's cards.\n You can not see his hand.",
            "...but you can tell if one's picked.",
            "Likewise, you decide where \nto place your opponent's pick.",
            "Let's put into the same column.",
            "Now both sides of a coin is filled...\nBigger side gets a coin. So you got it!",
            "Be the first to get 4 coins in total\nor 3 coins next to each other to win.",
            "That's the tutorial.\nNow have fun beating up the dog.",
            "And enjoy beating players\nfrom all over the world."
        ]

        if subState < texts.count {
            instructionLabel?.text = texts[subState]
        }
    }

    // MARK: - CardUIDelegate

    func cardUIClicked(_ card: Any) {
        SoundMgr.sharedInstance.playSelect()

        // Check selection count and show/hide send button
        let selectedCount = deckMgr.player1Deck.filter { $0.getSelected() }.count
        if selectedCount > 0 && selectedCount < 6 {
            sendCardBtn.isHidden = false
            view.bringSubviewToFront(sendCardBtn)
        } else {
            sendCardBtn.isHidden = true
        }
    }

    func cardShowDeck(player: Int, pos: Int) {
        if gameState != 2 && gameState != 8 { return }
        if player != PlayerType.player1.rawValue { return }
        // Show deck dialog
    }

    // MARK: - Coin Movement

    private func moveCoinByResult(_ winner: PlayerType, pos: Int) {
        guard pos >= 0 && pos < coinArray.count else { return }

        if winner == .player1 || winner == .player2 {
            coinArray[pos].moveToPlayer(winner)
        } else if winner == .even {
            coinArray[pos].moveToPlayer(.player1)
            let newCoin = CoinUI(pos: pos)
            view.addSubview(newCoin)
            newCoin.moveToPlayer(.player2)
            coinArray.append(newCoin)
        }
    }

    // MARK: - Refresh

    func refresh() {
        sendCardBtn.beginSpin()
        head[0].beginSpin()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    // MARK: - Memory Warning

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
