//
//  Common.swift
//  Seven Hand Poker
//
//  Common types and enums based on old_backup
//

import Foundation

// MARK: - Enums

enum CardType: Int {
    case highCard = 0
    case onePair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush

    var displayName: String {
        switch self {
        case .highCard: return "High Card"
        case .onePair: return "One Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        }
    }
}

enum PlayerType: Int {
    case none = 0
    case player1
    case player2
    case even
}

enum GameState: Int {
    case idle = 0
    case dealing
    case player1Turn
    case player1Placing
    case player1NewCard
    case player2Turn
    case player2Placing
    case player2NewCard
    case comparing
    case checkWin
    case gameOver
}
