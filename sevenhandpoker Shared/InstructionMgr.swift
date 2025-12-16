//
//  InstructionMgr.swift
//  sevenhandpoker iOS
//
//  Created by Shunping Chiu on 12/17/25.
//

// This class is used to initiate instruction
import SpriteKit

class InstructionMgr {
    static let shared = InstructionMgr()
    private init() {}
    let turtorialTexts: [String] = [
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
        "And enjoy beating players\nfrom all over the world."
    ]
    
    public func getIntructionDialog(sceneSize: CGSize, i : Int) -> DialogBoxView? {
        if (i > turtorialTexts.count) {
            return nil
        }
        switch i {
        case 0...turtorialTexts.count - 1:
            return DialogBoxView(sceneSize: sceneSize, style: .center, text: turtorialTexts[i])
        default:
            return nil
        }
    }
}
