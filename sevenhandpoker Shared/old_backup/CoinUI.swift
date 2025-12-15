//
//  CoinUI.swift
//  Seven Hand Poker
//
//  Converted to Swift from CoinUI.h/m
//

import UIKit

class CoinUI: UIImageView {
    // MARK: - Properties

    private var _pos: Int = 0
    private var _animateState: Int = 0

    // MARK: - Initializers

    convenience init() {
        self.init(frame: .zero)
        initCoinDefault()
    }

    convenience init(pos: Int) {
        self.init(frame: .zero)
        initCoin(pos: pos)
    }

    func initCoinDefault() {
        if let tmp = UIImage(named: "coin_960.png"),
           let cgImage = tmp.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: 100, height: 100)) {
            let tmp1 = UIImage(cgImage: cgImage)
            self.image = tmp1
        }
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        _animateState = 0
    }

    func initCoin(pos: Int) {
        if let tmp = UIImage(named: "coin_960.png"),
           let cgImage = tmp.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: 100, height: 100)) {
            let tmp1 = UIImage(cgImage: cgImage)
            self.image = tmp1
        }
        self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        self.center = CGPoint(x: 88 + 50 * pos, y: 158)
        self.isUserInteractionEnabled = true
        self.superview?.bringSubviewToFront(self)
        _pos = pos
        _animateState = 0
    }

    // MARK: - Movement

    func moveToPlayer(_ player: PlayerType) {
        self.superview?.bringSubviewToFront(self)

        switch player {
        case .player1:
            self.center = CGPoint(x: 88 + 50 * _pos, y: 208)
        case .player2:
            self.center = CGPoint(x: 88 + 50 * _pos, y: 108)
        default:
            break
        }
    }

    // MARK: - Animation

    func beginShine() {
        if _animateState == 0 {
            _animateState = 1
        }
    }

    func render() {
        guard _animateState != 0 else { return }

        guard let tmp = UIImage(named: "coin_960.png") else { return }

        let xOffset: CGFloat
        switch _animateState {
        case 1:
            xOffset = 0
        case 2:
            xOffset = 100
        case 3:
            xOffset = 200
        case 4:
            xOffset = 300
        case 5:
            xOffset = 400
        case 6:
            xOffset = 500
        case 7:
            xOffset = 600
        case 8:
            xOffset = 700
        case 9:
            xOffset = 0
        default:
            xOffset = 0
        }

        if let cgImage = tmp.cgImage?.cropping(to: CGRect(x: xOffset, y: 0, width: 100, height: 100)) {
            let tmp1 = UIImage(cgImage: cgImage)
            self.image = tmp1
        }

        _animateState += 1
        if _animateState == 10 {
            _animateState = 0
        }
    }
}
