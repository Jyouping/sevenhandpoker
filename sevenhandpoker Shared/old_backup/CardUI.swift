//
//  CardUI.swift
//  Seven Hand Poker
//
//  Converted to Swift from CardUI.h/m
//

import UIKit

class CardUI: UIImageView {
    // Card Attributes
    private var _number: Int = 0
    private var _color: Int = 0
    private var _player: Int = 0
    var deckPos: Int = 0
    private var _face: Int = 0
    private var _select: Bool = false
    private var _enable: Bool = false
    var showDeck: Bool = false

    // UI Attributes
    private var _targetX: Int = 0
    private var _targetY: Int = 0
    private var _x: Int = 0
    private var _y: Int = 0
    private var _traceType: Int = 0
    private var _nxtTraceType: Int = 0
    private var _moving: Bool = false
    private var _stepX: Int = 0
    private var _stepY: Int = 0

    // For AI
    private var _rank: CardType = .highCard

    weak var clickDelegate: CardUIDelegate?

    // MARK: - Initializers

    convenience init(color: Int, number: Int, face: Int, x: Int, y: Int, owner: Int) {
        self.init(frame: .zero)
        _color = color
        _face = face
        _number = number
        deckPos = 0

        let imageName = getImageName()
        if let img = UIImage(named: imageName) {
            self.image = img
        }

        _x = x
        _y = y
        _traceType = 0
        self.frame = CGRect(x: 0, y: 0, width: 42, height: 60)
        self.center = CGPoint(x: _x, y: _y)
        self.isUserInteractionEnabled = true
        _moving = false
        _enable = false
        _player = owner
        showDeck = false
    }

    convenience init(card: CardUI) {
        let color = card.getColor()
        let number = card.getNumber()
        let owner = card.getOwner()

        self.init(color: color, number: number, face: 1, x: 0, y: 0, owner: owner)
        self.clickDelegate = card.clickDelegate
        _enable = false
        _rank = card.getRank()
    }

    convenience init(card: CardUI, face: Bool) {
        let color = card.getColor()
        let number = card.getNumber()
        let owner = card.getOwner()

        self.init(color: color, number: number, face: face ? 1 : 0, x: 0, y: 0, owner: owner)
        self.clickDelegate = card.clickDelegate
        _rank = card.getRank()
    }

    // MARK: - Public Methods

    func getSelected() -> Bool {
        return _select
    }

    func setEnable(_ enable: Bool) {
        _enable = enable
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        clicked()
    }

    func clicked() {
        _face = 0

        if _enable {
            setSelect(!_select)
            clickDelegate?.cardUIClicked(self)
        } else if showDeck {
            clickDelegate?.cardShowDeck(player: _player, pos: deckPos)
        }
    }

    func setTypeTrace(_ type: Int) {
        _traceType = type
        let centerPt = self.center
        let x = Int(centerPt.x)
        let y = Int(centerPt.y)

        switch type {
        case 0: // default
            break
        case 1: // move to player 1
            _targetX = 115
            _targetY = 285
            _stepX = (_targetX - x) / 10
            _stepY = (_targetY - y) / 10
            _nxtTraceType = 3
        case 2: // move to player 2
            _targetX = 115
            _targetY = 33
            _stepX = (_targetX - x) / 10
            _stepY = (_targetY - y) / 10
            _nxtTraceType = 4
        default:
            break
        }
    }

    func setTypeTrace(_ type: Int, deckSize: Int, cardPos: Int) {
        _traceType = type
        let centerPt = self.center
        let x = Int(centerPt.x)
        let y = Int(centerPt.y)

        switch type {
        case 0: // default
            break
        case 3, 4: // rearrange
            if deckSize < 9 {
                _targetX = 105 + (deckSize - cardPos) * 30
            } else if deckSize < 12 {
                _targetX = 80 + (deckSize - cardPos) * 27
            } else if deckSize < 15 {
                _targetX = 55 + (deckSize - cardPos) * 25
            } else if deckSize < 19 {
                _targetX = 50 + (deckSize - cardPos) * 20
            } else {
                _targetX = 45 + (deckSize - cardPos) * 21
            }
            _stepX = (_targetX - x) / 12
        case 5: // Put into deck
            if _player == 1 {
                _targetX = 88 + cardPos * 50
                _targetY = 210 + 5 * deckSize
                _stepX = (_targetX - x) / 12
                _stepY = (_targetY - y) / 12
                _nxtTraceType = 0
            } else if _player == 2 {
                _targetX = 88 + cardPos * 50
                _targetY = 110 - 5 * deckSize
                _stepX = (_targetX - x) / 12
                _stepY = (_targetY - y) / 12
            }
        default:
            break
        }
    }

    func startMoving() {
        _moving = true
    }

    func changeSelect() {
        setSelect(!_select)
    }

    func setSelect(_ select: Bool) {
        _select = select
        if _select {
            if _player == 1 {
                self.center = CGPoint(x: self.center.x, y: 275)
            } else if _player == 2 {
                self.center = CGPoint(x: self.center.x, y: 43)
            }
        } else {
            if _player == 1 {
                self.center = CGPoint(x: self.center.x, y: 285)
            } else if _player == 2 {
                self.center = CGPoint(x: self.center.x, y: 33)
            }
        }
        _targetY = Int(self.center.y)
    }

    func render() {
        let centerPt = self.center
        let newX = Int(centerPt.x) + _stepX
        let newY = Int(centerPt.y) + _stepY

        if _moving {
            if abs(_targetX - newX) >= abs(_targetX - Int(centerPt.x)) && abs(_targetY - newY) >= abs(_targetY - Int(centerPt.y)) {
                self.center = CGPoint(x: _targetX, y: _targetY)
                _moving = false
            } else if abs(_targetX - newX) >= abs(_targetX - Int(centerPt.x)) {
                self.center = CGPoint(x: _targetX, y: newY)
            } else if abs(_targetY - newY) >= abs(_targetY - Int(centerPt.y)) {
                self.center = CGPoint(x: newX, y: _targetY)
            } else {
                self.center = CGPoint(x: newX, y: newY)
            }
        }
    }

    func setToCenter() {
        self.center = CGPoint(x: 240, y: 180)
    }

    func setXYTarget(x: Int, y: Int) {
        _targetX = x
        _targetY = y
    }

    func getImageName() -> String {
        if _face == 0 {
            return "cardback_960.png"
        } else {
            var colorStr: String
            switch _color {
            case 0:
                colorStr = "spade"
            case 1:
                colorStr = "heart"
            case 2:
                colorStr = "diamond"
            case 3:
                colorStr = "club"
            default:
                colorStr = "spade"
            }

            // Note: _number 0~12
            if _number <= 8 {
                return "\(colorStr)_\(_number + 2)_960.png"
            } else if _number == 9 {
                return "\(colorStr)_j_960.png"
            } else if _number == 10 {
                return "\(colorStr)_q_960.png"
            } else if _number == 11 {
                return "\(colorStr)_k_960.png"
            } else if _number == 12 {
                return "\(colorStr)_1_960.png"
            }
            return "\(colorStr)_1_960.png"
        }
    }

    func getColor() -> Int {
        return _color
    }

    func getFace() -> Int {
        return _face
    }

    func getNumber() -> Int {
        return _number
    }

    func getOwner() -> Int {
        return _player
    }

    func setRank(_ type: CardType) {
        _rank = type
    }

    func getRank() -> CardType {
        return _rank
    }

    func setFace(_ face: Bool) {
        _face = face ? 1 : 0
    }
}
