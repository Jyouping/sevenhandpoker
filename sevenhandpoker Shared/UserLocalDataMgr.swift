//
//  UserLocalDataMgr.swift
//  Seven Hand Poker
//
//  Manages user statistics and local data storage
//

import Foundation

class UserLocalDataMgr {
    // MARK: - Singleton

    static let shared = UserLocalDataMgr()

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private let easyWinsKey = "easyWins"
    private let easyLossesKey = "easyLosses"
    private let mediumWinsKey = "mediumWins"
    private let mediumLossesKey = "mediumLosses"
    private let hardWinsKey = "hardWins"
    private let hardLossesKey = "hardLosses"
    
    private let tutorialPlayedKey = "tutorialPlayed"
    private let aiDifficultyKey = "aiDifficulty"

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    func getAiDifficulty() -> Int {
        print("AI difficulty : \(userDefaults.integer(forKey: aiDifficultyKey))")
        return userDefaults.integer(forKey: aiDifficultyKey)
    }
    
    func recordAiDifficulty(difficulty : Int) {
        userDefaults.set(difficulty, forKey: aiDifficultyKey)
    }
    
    func getTutorialPlayed() -> Bool {
        print("Tutorial Played: \(userDefaults.integer(forKey: tutorialPlayedKey))")
        return userDefaults.integer(forKey: tutorialPlayedKey) == 1
    }
    
    func recordTutorialPlayed() {
        userDefaults.set(1, forKey: tutorialPlayedKey)
        print("Recorded Tutorial played")
    }
    /// Record a win for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    func recordWin(difficulty: Int) {
        let key = getWinsKey(difficulty: difficulty)
        let currentWins = userDefaults.integer(forKey: key)
        userDefaults.set(currentWins + 1, forKey: key)
        print("Recorded win for difficulty \(difficulty): \(currentWins + 1) total wins")
    }

    /// Record a loss for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    func recordLoss(difficulty: Int) {
        let key = getLossesKey(difficulty: difficulty)
        let currentLosses = userDefaults.integer(forKey: key)
        userDefaults.set(currentLosses + 1, forKey: key)
        print("Recorded loss for difficulty \(difficulty): \(currentLosses + 1) total losses")
    }

    /// Get wins count for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    /// - Returns: Number of wins
    func getWins(difficulty: Int) -> Int {
        let key = getWinsKey(difficulty: difficulty)
        return userDefaults.integer(forKey: key)
    }

    /// Get losses count for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    /// - Returns: Number of losses
    func getLosses(difficulty: Int) -> Int {
        let key = getLossesKey(difficulty: difficulty)
        return userDefaults.integer(forKey: key)
    }

    /// Get total games played for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    /// - Returns: Total number of games (wins + losses)
    func getTotalGames(difficulty: Int) -> Int {
        return getWins(difficulty: difficulty) + getLosses(difficulty: difficulty)
    }

    /// Get win rate for the specified difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    /// - Returns: Win rate as a percentage (0.0 to 100.0), returns 0 if no games played
    func getWinRate(difficulty: Int) -> Double {
        let totalGames = getTotalGames(difficulty: difficulty)
        guard totalGames > 0 else { return 0.0 }

        let wins = Double(getWins(difficulty: difficulty))
        return (wins / Double(totalGames)) * 100.0
    }

    /// Reset all statistics for all difficulties
    func resetAllStats() {
        userDefaults.removeObject(forKey: easyWinsKey)
        userDefaults.removeObject(forKey: easyLossesKey)
        userDefaults.removeObject(forKey: mediumWinsKey)
        userDefaults.removeObject(forKey: mediumLossesKey)
        userDefaults.removeObject(forKey: hardWinsKey)
        userDefaults.removeObject(forKey: hardLossesKey)
        print("All statistics reset")
    }

    /// Reset statistics for a specific difficulty
    /// - Parameter difficulty: AI difficulty level (0=Easy, 1=Medium, 2=Hard)
    func resetStats(difficulty: Int) {
        userDefaults.removeObject(forKey: getWinsKey(difficulty: difficulty))
        userDefaults.removeObject(forKey: getLossesKey(difficulty: difficulty))
        print("Statistics reset for difficulty \(difficulty)")
    }

    // MARK: - Private Helpers

    private func getWinsKey(difficulty: Int) -> String {
        switch difficulty {
        case 0:
            return easyWinsKey
        case 1:
            return mediumWinsKey
        case 2:
            return hardWinsKey
        default:
            return mediumWinsKey
        }
    }

    private func getLossesKey(difficulty: Int) -> String {
        switch difficulty {
        case 0:
            return easyLossesKey
        case 1:
            return mediumLossesKey
        case 2:
            return hardLossesKey
        default:
            return mediumLossesKey
        }
    }
}
