//
//  Card.swift
//  Seven Hand Poker
//
//  Card model based on old_backup
//

import Foundation

class Card {
    private var _number: Int  // 0~12 (2,3,4,5,6,7,8,9,10,J,Q,K,A)
    private var _color: Int   // 0=spade, 1=heart, 2=diamond, 3=club

    init(number: Int) {
        // number from 1~52
        _number = (number - 1) % 13
        _color = (number - 1) / 13
    }

    init(color: Int, number: Int) {
        _color = color
        _number = number
    }

    var number: Int {
        return _number
    }

    var color: Int {
        return _color
    }

    func getNumber() -> Int {
        return _number
    }

    func getColor() -> Int {
        return _color
    }

    func getImageName(faceUp: Bool) -> String {
        if !faceUp {
            return "cardback_960"
        }

        let colorStr: String
        switch _color {
        case 0: colorStr = "spade"
        case 1: colorStr = "heart"
        case 2: colorStr = "diamond"
        case 3: colorStr = "club"
        default: colorStr = "spade"
        }

        // _number 0~12 maps to 2,3,4,5,6,7,8,9,10,J,Q,K,A
        // Asset catalog uses names without _960 suffix
        if _number <= 8 {
            return "\(colorStr)_\(_number + 2)"
        } else if _number == 9 {
            return "\(colorStr)_j"
        } else if _number == 10 {
            return "\(colorStr)_q"
        } else if _number == 11 {
            return "\(colorStr)_k"
        } else { // _number == 12 (Ace)
            return "\(colorStr)_1"
        }
    }
}
