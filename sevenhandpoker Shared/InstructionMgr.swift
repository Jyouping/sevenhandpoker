//
//  InstructionMgr.swift
//  sevenhandpoker iOS
//
//  Created by Shunping Chiu on 12/17/25.
//

// This class is used to initiate instruction
import SpriteKit
import Foundation

// TODO: uncomment the last setence if tutorial is added

class InstructionMgr {
    static let shared = InstructionMgr()
    private init() {}

    private let tutorialTextsEN: [String] = [
        "Welcome to Seven Hand Poker",
        "These are your cards.\n You can tap to pick and unpick.",
        "You can pick 1-5 cards every time \n to form different combinations.",
        "Now let's pick two K cards to form a pair.",
        "Once you've decided your pick,\n The opponent gets to place it.",
        "Theses are the opponent's cards.\n You can not see his hand.",
        "...but you can tell if one's picked.",
        "Likewise, you decide where \nto place your opponent's pick.",
        "Let's put into the same column.",
        "Now both sides of a coin is filled...\nBigger side gets a coin. So you got it!",
        "Be the first to get 4 coins in total\nor 3 coins next to each other to win.",
        "That's the tutorial.\nNow have fun beating up the dog.",
        //"And enjoy beating players\nfrom all over the world."
    ]

    private let tutorialTextsZH_TW: [String] = [
        "歡迎來到七手撲克",
        "這些是你的牌。\n 你可以點擊來選擇和取消選擇。",
        "每次可以選擇 1-5 張牌 \n 來組成不同的組合。",
        "現在讓我們選擇兩張 K 來組成對子。",
        "一旦你決定了你的選擇，\n 對手會決定放置位置。",
        "這些是對手的牌。\n 你看不到他的手牌。",
        "...但是你可以看出哪些牌被選了。",
        "同樣地，你決定 \n對手選擇的牌要放在哪裡。",
        "讓我們放到同一列。",
        "現在硬幣的兩面都填滿了...\n較大的一方獲得硬幣。所以你贏了！",
        "率先獲得 4 個硬幣\n或連續 3 個硬幣就能獲勝。",
        "這就是教學。\n現在去痛扁那隻狗吧。",
        //"盡情擊敗來自\n世界各地的玩家吧。"
    ]

    private let tutorialTextsKO: [String] = [
        "세븐 핸드 포커에 오신 것을 환영합니다",
        "이것들은 당신의 카드입니다.\n 탭하여 선택하거나 선택 해제할 수 있습니다.",
        "매번 1-5장의 카드를 선택하여 \n 다양한 조합을 만들 수 있습니다.",
        "이제 두 장의 K 카드를 선택하여 페어를 만들어봅시다.",
        "선택을 결정하면,\n 상대가 배치 위치를 결정합니다.",
        "이것들은 상대의 카드입니다.\n 그의 패를 볼 수 없습니다.",
        "...하지만 어떤 것이 선택되었는지 알 수 있습니다.",
        "마찬가지로, 당신이 \n상대의 선택을 어디에 배치할지 결정합니다.",
        "같은 열에 놓아봅시다.",
        "이제 코인의 양면이 모두 채워졌습니다...\n더 큰 쪽이 코인을 얻습니다. 당신이 얻었어요!",
        "총 4개의 코인을 먼저 얻거나\n연속으로 3개의 코인을 얻으면 승리합니다.",
        "이것으로 튜토리얼이 끝났습니다.\n이제 개를 물리쳐보세요.",
        //"전 세계의 플레이어들을\n물리치는 재미를 느껴보세요."
    ]

    private let tutorialTextsJA: [String] = [
        "セブンハンドポーカーへようこそ",
        "これらはあなたのカードです。\n タップして選択・選択解除できます。",
        "毎回1〜5枚のカードを選んで \n さまざまな組み合わせを作れます。",
        "それでは2枚のKを選んでペアを作りましょう。",
        "選択を決めたら、\n 相手が配置場所を決めます。",
        "これらは相手のカードです。\n 相手の手札は見えません。",
        "...でもどれが選ばれたかはわかります。",
        "同様に、あなたが \n相手の選択をどこに配置するか決めます。",
        "同じ列に置いてみましょう。",
        "コインの両面が埋まりました...\n大きい方がコインを獲得。あなたの勝ちです！",
        "合計4枚のコインを先に獲得するか\n連続3枚のコインで勝利です。",
        "これでチュートリアルは終わりです。\n犬を倒して楽しんでください。",
        //"世界中のプレイヤーを\n倒す楽しさを味わってください。"
    ]

    // Get current language texts based on device locale
    var turtorialTexts: [String] {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

        switch languageCode {
        case "zh":
            // Check for Traditional Chinese (Taiwan)
            if Locale.current.region?.identifier == "TW" {
                return tutorialTextsZH_TW
            }
            return tutorialTextsZH_TW
        case "ko":
            return tutorialTextsKO
        case "ja":
            return tutorialTextsJA
        default:
            return tutorialTextsEN
        }
    }
    
    public func getIntructionDialog(scene: SKScene, i : Int) -> DialogBoxView? {
        if (i > turtorialTexts.count) {
            return nil
        }
        switch i {
        case 0...2:
            let view = DialogBoxView(sceneSize: scene.size, style: .center, text: turtorialTexts[i])
            view.setEnabled(true)
            view.delegate = scene as? GameScene
            return view
        case 3:
            let view = DialogBoxView(sceneSize: scene.size, style: .downward, text: turtorialTexts[i])
            view.setEnabled(false)
            view.delegate = scene as? GameScene
            return view
        case 4...5:
            let view = DialogBoxView(sceneSize: scene.size, style: .center, text: turtorialTexts[i], blockTurn: true)
            view.setEnabled(true)
            view.delegate = scene as? GameScene
            return view
        case 6...7:
            let view = DialogBoxView(sceneSize: scene.size, style: .upward, text: turtorialTexts[i])
            view.setEnabled(true)
            view.delegate = scene as? GameScene
            return view
        case 8:
            let view = DialogBoxView(sceneSize: scene.size, style: .center, text: turtorialTexts[i])
            view.setEnabled(false)
            view.delegate = scene as? GameScene
            return view
        case 9...turtorialTexts.count - 1:
            let view = DialogBoxView(sceneSize: scene.size, style: .center, text: turtorialTexts[i])
            view.setEnabled(true)
            view.delegate = scene as? GameScene
            return view
        default:
            return nil
        }
    }
}
