//
//  TrackingManager.swift
//  Seven Hand Poker
//
//  Manages all analytics tracking with Firebase
//  Does not use IDFA (Identifier for Advertisers)
//

import Foundation
import FirebaseAnalytics

class TrackingManager {
    static let shared = TrackingManager()

    private init() {}

    // Master switch for all tracking
    private var isTrackingEnabled: Bool {
        // Can be controlled by user preferences or app settings
        return UserDefaults.standard.bool(forKey: "tracking_enabled")
    }

    // MARK: - Enable/Disable Tracking

    func enableTracking() {
        UserDefaults.standard.set(true, forKey: "tracking_enabled")
        Analytics.setAnalyticsCollectionEnabled(true)
        print("📊 Tracking enabled")
    }

    func disableTracking() {
        UserDefaults.standard.set(false, forKey: "tracking_enabled")
        Analytics.setAnalyticsCollectionEnabled(false)
        print("📊 Tracking disabled")
    }

    // MARK: - App Lifecycle Events

    func trackAppLaunch() {
        guard isTrackingEnabled else { return }
        Analytics.logEvent("app_launch", parameters: nil)
    }

    func trackAppBackground() {
        guard isTrackingEnabled else { return }
        // Analytics.logEvent("app_background", parameters: nil)
    }

    func trackAppForeground() {
        guard isTrackingEnabled else { return }
        // Analytics.logEvent("app_foreground", parameters: nil)
    }

    // MARK: - Screen Tracking

    func trackScreen(_ screenName: String) {
        guard isTrackingEnabled else { return }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
    }

    // MARK: - Game Events

    func trackGameStart(difficulty: Int, isTutorial: Bool) {
        guard isTrackingEnabled else { return }

        let difficultyName: String
        switch difficulty {
        case 0: difficultyName = "easy"
        case 1: difficultyName = "medium"
        case 2: difficultyName = "hard"
        default: difficultyName = "unknown"
        }

        Analytics.logEvent("game_start", parameters: [
            "difficulty": difficultyName,
            "is_tutorial": isTutorial
        ])
    }

    func trackGameEnd(isWin: Bool, difficulty: Int, duration: TimeInterval) {
        guard isTrackingEnabled else { return }

        let difficultyName: String
        switch difficulty {
        case 0: difficultyName = "easy"
        case 1: difficultyName = "medium"
        case 2: difficultyName = "hard"
        default: difficultyName = "unknown"
        }

        Analytics.logEvent("game_end", parameters: [
            "result": isWin ? "win" : "loss",
            "difficulty": difficultyName,
            "duration_seconds": Int(duration)
        ])
    }

    func trackTutorialComplete() {
        guard isTrackingEnabled else { return }
        Analytics.logEvent("tutorial_complete", parameters: nil)
    }

    // MARK: - User Actions

    func trackDifficultyChanged(from: Int, to: Int) {
        guard isTrackingEnabled else { return }

        let fromName: String
        let toName: String

        switch from {
        case 0: fromName = "easy"
        case 1: fromName = "medium"
        case 2: fromName = "hard"
        default: fromName = "unknown"
        }

        switch to {
        case 0: toName = "easy"
        case 1: toName = "medium"
        case 2: toName = "hard"
        default: toName = "unknown"
        }

        Analytics.logEvent("difficulty_changed", parameters: [
            "from_difficulty": fromName,
            "to_difficulty": toName
        ])
    }
    
    func trackAchievementViewed() {
        guard isTrackingEnabled else { return }
        Analytics.logEvent("achievement_viewed", parameters: nil)
    }

    // MARK: - Ad Events

    func trackAdShown(type: String) {
        guard isTrackingEnabled else { return }
        Analytics.logEvent("ad_shown", parameters: [
            "ad_type": type
        ])
    }

    // MARK: - User Properties

    func setUserPreferredDifficulty(_ difficulty: Int) {
        guard isTrackingEnabled else { return }

        let difficultyName: String
        switch difficulty {
        case 0: difficultyName = "easy"
        case 1: difficultyName = "medium"
        case 2: difficultyName = "hard"
        default: difficultyName = "unknown"
        }

        Analytics.setUserProperty(difficultyName, forName: "preferred_difficulty")
    }

    // MARK: - Custom Events

    func trackCustomEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        guard isTrackingEnabled else { return }
        Analytics.logEvent(eventName, parameters: parameters)
    }
}
