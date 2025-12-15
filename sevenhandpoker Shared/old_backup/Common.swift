//
//  Common.swift
//  Seven Hand Poker
//
//  Converted to Swift from common.h
//

import Foundation

// MARK: - Protocols

@MainActor
protocol SwitchViewDelegate: AnyObject {
    func switchViewAction(_ viewType: Int)
    func startMultiPlayerGame()
}

@MainActor
protocol MenuDelegate: AnyObject {
    func showLoadingView()
    func hideLoadingView()
    func inviteReceived()
}

@MainActor
protocol CardUIDelegate: AnyObject {
    func cardUIClicked(_ card: Any)
    func cardShowDeck(player: Int, pos: Int)
}

// MARK: - Enums

enum CardType: Int {
    case highCard = 0
    case onePair
    case twoPair
    case trebleton
    case straight
    case flushNormal
    case fullHouse
    case quart
    case flushStrait
}

enum PlayerType: Int {
    case preserve = 0
    case player1
    case player2
    case even
}

enum DeckNum: Int {
    case initDeck = 0
    case player1Deck
    case player2Deck
    case playerPokerDeck
    case compare1Deck
    case compare2Deck
    case p1D0, p1D1, p1D2, p1D3, p1D4, p1D5, p1D6
    case p2D0, p2D1, p2D2, p2D3, p2D4, p2D5, p2D6
    case bestCardDeck
}

// MARK: - Network Enums

enum MultiPlayerGameState: Int {
    case singlePlayer = 0
    case waitingForMatch
    case waitingForRandomNumber
    case waitingForStart
    case active
    case waitingForRestart
    case done
}

enum EndReason: Int {
    case win
    case lose
    case disconnect
}

enum MessageType: Int {
    case randomNumber = 0
    case seed
    case gameBegin
    case selectCard
    case sortCard
    case submitCard
    case placePos
    case restart
    case confirmRestart
    case gameOver
}

// MARK: - Network Message Structures

struct Message {
    var messageType: MessageType

    init(messageType: MessageType = .randomNumber) {
        self.messageType = messageType
    }
}

struct MessageRandomNumber {
    var message: Message
    var randomNumber: UInt32

    init(randomNumber: UInt32 = 0) {
        self.message = Message(messageType: .randomNumber)
        self.randomNumber = randomNumber
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var randNum = randomNumber
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &randNum, count: MemoryLayout<UInt32>.size))
        return data
    }

    static func fromData(_ data: Data) -> MessageRandomNumber? {
        guard data.count >= MemoryLayout<Int32>.size + MemoryLayout<UInt32>.size else { return nil }
        let randNum = data.withUnsafeBytes { ptr -> UInt32 in
            ptr.load(fromByteOffset: MemoryLayout<Int32>.size, as: UInt32.self)
        }
        return MessageRandomNumber(randomNumber: randNum)
    }
}

struct MessageSeed {
    var message: Message
    var seedNumber: Int32

    init(seedNumber: Int32 = 0) {
        self.message = Message(messageType: .seed)
        self.seedNumber = seedNumber
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var seed = seedNumber
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &seed, count: MemoryLayout<Int32>.size))
        return data
    }

    static func fromData(_ data: Data) -> MessageSeed? {
        guard data.count >= MemoryLayout<Int32>.size * 2 else { return nil }
        let seed = data.withUnsafeBytes { ptr -> Int32 in
            ptr.load(fromByteOffset: MemoryLayout<Int32>.size, as: Int32.self)
        }
        return MessageSeed(seedNumber: seed)
    }
}

struct MessageGameBegin {
    var message: Message

    init() {
        self.message = Message(messageType: .gameBegin)
    }

    func toData() -> Data {
        var msgType = Int32(message.messageType.rawValue)
        return Data(bytes: &msgType, count: MemoryLayout<Int32>.size)
    }
}

struct MessageSelectCard {
    var message: Message
    var pos: Int32

    init(pos: Int32 = 0) {
        self.message = Message(messageType: .selectCard)
        self.pos = pos
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var position = pos
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &position, count: MemoryLayout<Int32>.size))
        return data
    }

    static func fromData(_ data: Data) -> MessageSelectCard? {
        guard data.count >= MemoryLayout<Int32>.size * 2 else { return nil }
        let position = data.withUnsafeBytes { ptr -> Int32 in
            ptr.load(fromByteOffset: MemoryLayout<Int32>.size, as: Int32.self)
        }
        return MessageSelectCard(pos: position)
    }
}

struct MessageSort {
    var message: Message
    var type: Int32

    init(type: Int32 = 0) {
        self.message = Message(messageType: .sortCard)
        self.type = type
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var sortType = type
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &sortType, count: MemoryLayout<Int32>.size))
        return data
    }

    static func fromData(_ data: Data) -> MessageSort? {
        guard data.count >= MemoryLayout<Int32>.size * 2 else { return nil }
        let sortType = data.withUnsafeBytes { ptr -> Int32 in
            ptr.load(fromByteOffset: MemoryLayout<Int32>.size, as: Int32.self)
        }
        return MessageSort(type: sortType)
    }
}

struct MessageSubmit {
    var message: Message

    init() {
        self.message = Message(messageType: .submitCard)
    }

    func toData() -> Data {
        var msgType = Int32(message.messageType.rawValue)
        return Data(bytes: &msgType, count: MemoryLayout<Int32>.size)
    }
}

struct MessagePlaceCol {
    var message: Message
    var pos: Int32

    init(pos: Int32 = 0) {
        self.message = Message(messageType: .placePos)
        self.pos = pos
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var position = pos
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &position, count: MemoryLayout<Int32>.size))
        return data
    }

    static func fromData(_ data: Data) -> MessagePlaceCol? {
        guard data.count >= MemoryLayout<Int32>.size * 2 else { return nil }
        let position = data.withUnsafeBytes { ptr -> Int32 in
            ptr.load(fromByteOffset: MemoryLayout<Int32>.size, as: Int32.self)
        }
        return MessagePlaceCol(pos: position)
    }
}

struct MessageRestart {
    var message: Message
    var restartGame: Bool

    init(restartGame: Bool = false) {
        self.message = Message(messageType: .restart)
        self.restartGame = restartGame
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var restart: Int8 = restartGame ? 1 : 0
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &restart, count: MemoryLayout<Int8>.size))
        return data
    }
}

struct MessageConfirmRestart {
    var message: Message
    var confirmRestart: Bool

    init(confirmRestart: Bool = false) {
        self.message = Message(messageType: .confirmRestart)
        self.confirmRestart = confirmRestart
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var confirm: Int8 = confirmRestart ? 1 : 0
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &confirm, count: MemoryLayout<Int8>.size))
        return data
    }
}

struct MessageGameOver {
    var message: Message
    var player1Won: Bool

    init(player1Won: Bool = false) {
        self.message = Message(messageType: .gameOver)
        self.player1Won = player1Won
    }

    func toData() -> Data {
        var data = Data()
        var msgType = Int32(message.messageType.rawValue)
        var won: Int8 = player1Won ? 1 : 0
        data.append(Data(bytes: &msgType, count: MemoryLayout<Int32>.size))
        data.append(Data(bytes: &won, count: MemoryLayout<Int8>.size))
        return data
    }
}

// Helper to get message type from data
func getMessageType(from data: Data) -> MessageType? {
    guard data.count >= MemoryLayout<Int32>.size else { return nil }
    let rawValue = data.withUnsafeBytes { ptr -> Int32 in
        ptr.load(as: Int32.self)
    }
    return MessageType(rawValue: Int(rawValue))
}
