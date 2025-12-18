//
//  TipManager.swift
//  Seven Hand Poker
//
//  Manages game tips shown during idle state
//

import Foundation

class TipManager {
    static let shared = TipManager()

    // Probability of showing a tip (0.0 to 1.0)
    private let tipChance: Double = 0.8

    // Track shown tips to avoid repetition
    private var recentlyShownTips: [Int] = []
    private let maxRecentTips = 5

    private let tipsEN: [String] = [
        "You can change AI difficulty\nin the menu settings.",
        "Use fake card combos\nto bluff your opponent!",
        "Ace (A) is the largest card.",
        "Three of a kind beats\ntwo pairs.",
        "Full house beats\nthree of a kind.",
        "Flush beats a straight.",
        "Try to win 4 columns\nin a row for bonus points!",
        "Watch your opponent's patterns\nto predict their moves.",
        "Sometimes it's better to\nlose a column strategically.",
        "Save your strong cards\nfor crucial moments.",
        "A straight requires 5 cards\nwith consecutive values.",
        "Pairs are stronger\nthan high cards alone.",
        "The CPU gets smarter\non higher difficulties!",
        "Tap cards to select them\nfor your move.",
        "You can play 1 to 5 cards\neach turn.",
        "AI difficulty could be found in button left of the menu."
    ]

    private let tipsZH_TW: [String] = [
        "你可以在選單設定中\n更改 AI 難度。",
        "使用假牌型\n來欺騙你的對手！",
        "A 是最大的牌。",
        "三條比\n兩對大。",
        "葫蘆比\n三條大。",
        "同花比順子大。",
        "試著連續贏得 4 列\n來獲得額外分數！",
        "觀察對手的模式\n來預測他們的動作。",
        "有時戰略性地\n輸掉一列會更好。",
        "在關鍵時刻\n保留你的強牌。",
        "順子需要 5 張\n連續數字的牌。",
        "對子比\n單張高牌強。",
        "CPU 在更高難度下\n會更聰明！",
        "點擊牌來選擇它們\n進行你的移動。",
        "你每回合可以\n出 1 到 5 張牌。",
        "AI 難度設定可以在\n選單左邊的按鈕找到。"
    ]

    private let tipsKO: [String] = [
        "메뉴 설정에서\nAI 난이도를 변경할 수 있습니다.",
        "가짜 카드 조합으로\n상대를 속이세요!",
        "A는 가장 큰 카드입니다.",
        "트리플은\n투 페어를 이깁니다.",
        "풀 하우스는\n트리플을 이깁니다.",
        "플러시는 스트레이트를 이깁니다.",
        "연속으로 4개 열을 이겨\n보너스 점수를 받으세요!",
        "상대의 패턴을 관찰하여\n움직임을 예측하세요.",
        "때로는 전략적으로\n한 열을 포기하는 것이 좋습니다.",
        "중요한 순간을 위해\n강한 카드를 아껴두세요.",
        "스트레이트는 연속된 숫자의\n5장의 카드가 필요합니다.",
        "페어는 하이카드보다\n강합니다.",
        "CPU는 더 높은 난이도에서\n더 똑똑해집니다!",
        "카드를 탭하여\n선택하세요.",
        "매 턴마다 1~5장의\n카드를 낼 수 있습니다.",
        "AI 난이도는 메인 메뉴 왼쪽 아래에서 찾을 수 있습니다."
    ]

    private let tipsJA: [String] = [
        "メニュー設定で\nAI難易度を変更できます。",
        "偽の役で\n相手を欺こう！",
        "A が最も大きいカードです。",
        "スリーカードは\nツーペアに勝ちます。",
        "フルハウスは\nスリーカードに勝ちます。",
        "フラッシュはストレートに勝ちます。",
        "連続で4列勝って\nボーナスポイントを獲得！",
        "相手のパターンを観察して\n動きを予測しましょう。",
        "時には戦略的に\n1列を負けることも良いです。",
        "重要な時のために\n強いカードを残しておこう。",
        "ストレートには連続した数字の\n5枚のカードが必要です。",
        "ペアはハイカードより\n強いです。",
        "CPUは高難易度で\nもっと賢くなります！",
        "カードをタップして\n選択します。",
        "毎ターン1〜5枚の\nカードを出せます。",
        "AIの難易度はメインメニューの左下にあります。"
    ]

    // Get current language tips based on device locale
    private var tips: [String] {
        // Use preferredLanguages to get the device's language setting
        // This returns strings like "zh-Hant-TW", "ko-KR", "ja-JP", "en-US"
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return tipsEN
        }

        // Check language prefix
        if preferredLanguage.hasPrefix("zh") {
            // Check for Traditional Chinese (contains "Hant" or "TW")
            if preferredLanguage.contains("Hant") || preferredLanguage.contains("TW") || preferredLanguage.contains("HK") {
                return tipsZH_TW
            }
            // For Simplified Chinese, still return English for now
            return tipsZH_TW
        } else if preferredLanguage.hasPrefix("ko") {
            return tipsKO
        } else if preferredLanguage.hasPrefix("ja") {
            return tipsJA
        }

        return tipsEN
    }

    private init() {}

    // Returns a tip if random chance succeeds, nil otherwise
    func shouldShowTip() -> String? {
        guard Double.random(in: 0...1) < tipChance else {
            return nil
        }
        return getRandomTip()
    }

    // Force get a random tip (always returns a tip)
    func getRandomTip() -> String {
        // Get available indices (not recently shown)
        var availableIndices = Array(0..<tips.count).filter { !recentlyShownTips.contains($0) }

        // If all tips have been shown recently, reset
        if availableIndices.isEmpty {
            recentlyShownTips.removeAll()
            availableIndices = Array(0..<tips.count)
        }

        // Pick a random tip from available ones
        let selectedIndex = availableIndices.randomElement()!

        // Track this tip as recently shown
        recentlyShownTips.append(selectedIndex)
        if recentlyShownTips.count > maxRecentTips {
            recentlyShownTips.removeFirst()
        }

        return tips[selectedIndex]
    }
}
