//
//  AdConfig.swift
//  salute
//
//  Created by Claude Code on 11/30/25.
//

import Foundation

struct AdConfig {
    // MARK: - UserDefaults Keys
    private static let enableAdmobKey = "enable_admob"

    // MARK: - 廣告開關配置
    static var enable_admob: Bool {
        get {
            // 第一次啟動時，如果沒有設定過，預設為 true
            if !UserDefaults.standard.bool(forKey: "has_set_admob") {
                UserDefaults.standard.set(true, forKey: enableAdmobKey)
                UserDefaults.standard.set(true, forKey: "has_set_admob")
                return true
            }
            return UserDefaults.standard.bool(forKey: enableAdmobKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: enableAdmobKey)
        }
    }

    static let enable_idfa = false      // 是否啟用 IDFA (false = 只使用 NPA 非個人化廣告)

    // MARK: - AdMob 配置
    static let admobAppId = "ca-app-pub-4758422912741594~4314907612"

#if DEBUG
    static let interstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
#else
    static let interstitialAdUnitId = "ca-app-pub-4758422912741594/8997400411"
#endif
    // Test ad id
    // MARK: - 廣告顯示邏輯
    static let userActionsPerAd = 9          // 每幾個state change 顯示一次廣告
}
