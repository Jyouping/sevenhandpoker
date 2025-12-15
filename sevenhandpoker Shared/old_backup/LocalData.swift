//
//  LocalData.swift
//  Seven Hand Poker
//
//  Converted to Swift from LocalData.h/m
//

import Foundation

class LocalData {
    // MARK: - Properties

    var data: [String: Any] = [:]

    // MARK: - Singleton

    nonisolated(unsafe) static let sharedInstance = LocalData()

    private init() {
        firstTimeInitLocalData()
    }

    // MARK: - Data Initialization

    @discardableResult
    func firstTimeInitLocalData() -> Bool {
        var firstTime = false
        readData()

        if data.isEmpty {
            data = [:]

            data["AdvanceFeature"] = 0
            data["MultiplayTimes"] = 0
            data["MultiplayWins"] = 0
            data["MultiplayLoses"] = 0
            data["SingleplayTimes"] = 0
            data["SingleplayWins"] = 0
            data["SingleplayLoses"] = 0
            data["ach_poker"] = 0
            data["ach_cake"] = 0
            data["ach_tree"] = 0
            data["instruction"] = 0
            data["AILevel"] = 1

            writeData()
            return firstTime
        } else if data.count == 11 {
            // Compatibility for old version
            data["AILevel"] = 1
            writeData()
        }

        return firstTime
    }

    // MARK: - Data Access

    func getValue(forKey key: String) -> Int {
        return (data[key] as? Int) ?? 0
    }

    func setValue(_ value: Int, forKey key: String) {
        data[key] = value
    }

    func checkInApp() -> Bool {
        return getValue(forKey: "AdvanceFeature") == 1
    }

    // MARK: - File Operations

    @discardableResult
    func readData() -> Bool {
        let path = pathForSymbol("local_data")

        if FileManager.default.fileExists(atPath: path) {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                data = dict
                return true
            }
        }

        data = [:]
        return false
    }

    @discardableResult
    func writeData() -> Bool {
        let path = pathForSymbol("local_data")
        return (data as NSDictionary).write(toFile: path, atomically: true)
    }

    func pathForSymbol(_ symbol: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return (documentsDirectory as NSString).appendingPathComponent("\(symbol).plist")
    }

    // MARK: - Convenience Methods

    func incrementSingleplayWins() {
        let wins = getValue(forKey: "SingleplayWins")
        setValue(wins + 1, forKey: "SingleplayWins")
        writeData()
    }

    func incrementSingleplayLoses() {
        let loses = getValue(forKey: "SingleplayLoses")
        setValue(loses + 1, forKey: "SingleplayLoses")
        writeData()
    }

    func incrementMultiplayWins() {
        let wins = getValue(forKey: "MultiplayWins")
        setValue(wins + 1, forKey: "MultiplayWins")
        writeData()
    }

    func incrementMultiplayLoses() {
        let loses = getValue(forKey: "MultiplayLoses")
        setValue(loses + 1, forKey: "MultiplayLoses")
        writeData()
    }

    func incrementMultiplayTimes() {
        let times = getValue(forKey: "MultiplayTimes")
        setValue(times + 1, forKey: "MultiplayTimes")
        writeData()
    }

    func setAchievement(cake: Bool? = nil, tree: Bool? = nil, poker: Bool? = nil) {
        if let cake = cake, cake {
            setValue(1, forKey: "ach_cake")
        }
        if let tree = tree, tree {
            setValue(1, forKey: "ach_tree")
        }
        if let poker = poker, poker {
            setValue(1, forKey: "ach_poker")
        }
        writeData()
    }
}
