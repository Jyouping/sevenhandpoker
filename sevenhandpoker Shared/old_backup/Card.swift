//
//  Card.swift
//  Seven Hand Poker
//
//  Converted to Swift from Card.h/m
//

import Foundation

class Card {
    private var _number: Int
    private var _color: Int

    init(number: Int) {
        // Note: number from 0~12
        _number = (number - 1) % 13
        _color = (number - 1) / 13
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
}
