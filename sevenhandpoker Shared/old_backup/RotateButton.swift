//
//  RotateButton.swift
//  Seven Hand Poker
//
//  Converted to Swift from RotateButton.h/m
//

import UIKit
import QuartzCore

class RotateButton: UIView {
    // MARK: - Properties

    var mainButton: UIButton!
    private var srImageView: UIImageView!

    // MARK: - Initializer

    init(type: Int) {
        super.init(frame: .zero)
        setupButton(type: type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupButton(type: Int) {
        mainButton = UIButton()
        srImageView = UIImageView()

        switch type {
        case 0: // Start button
            self.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
            srImageView = UIImageView(image: UIImage(named: "play_lrng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
            mainButton.setImage(UIImage(named: "play_lbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
            mainButton.center = CGPoint(x: 50, y: 70)
            addSubview(mainButton)
            addSubview(srImageView)
            changeSpin(true)

        case 1: // Return button
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            srImageView = UIImageView(image: UIImage(named: "return_lrng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.setImage(UIImage(named: "return_lbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            mainButton.center = CGPoint(x: 30, y: 30)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 30, direction: -1)

        case 2: // Submit button
            self.frame = CGRect(x: 0, y: 0, width: 90, height: 90)
            srImageView = UIImageView(image: UIImage(named: "submit_lrng.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 90, height: 90)
            mainButton.setImage(UIImage(named: "ok_lbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.center = CGPoint(x: 45, y: 45)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 3: // Achievement button
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            srImageView = UIImageView(image: UIImage(named: "achievements_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.setImage(UIImage(named: "achievements_sbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            mainButton.center = CGPoint(x: 30, y: 30)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 4: // Multiplayer button
            self.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            srImageView = UIImageView(image: UIImage(named: "multiplay_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            mainButton.setImage(UIImage(named: "versus_lbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 55, height: 55)
            mainButton.center = CGPoint(x: 40, y: 40)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 5: // How to / Tutorial button
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            srImageView = UIImageView(image: UIImage(named: "instruct_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.setImage(UIImage(named: "instruct_sbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            mainButton.center = CGPoint(x: 30, y: 30)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 6: // Single player button
            self.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            srImageView = UIImageView(image: UIImage(named: "singleplay_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            mainButton.setImage(UIImage(named: "singleplay_sbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 55, height: 55)
            mainButton.center = CGPoint(x: 40, y: 40)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 7: // Upgrade button
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            srImageView = UIImageView(image: UIImage(named: "upgrade_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.setImage(UIImage(named: "upgrade_sbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            mainButton.center = CGPoint(x: 30, y: 30)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        case 8: // Back button
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            srImageView = UIImageView(image: UIImage(named: "back_srng_960.png"))
            srImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            mainButton.setImage(UIImage(named: "back_sbtn_960.png"), for: .normal)
            mainButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            mainButton.center = CGPoint(x: 30, y: 30)
            addSubview(srImageView)
            addSubview(mainButton)
            spinLayer(srImageView.layer, duration: 4, direction: -1)

        default:
            break
        }
    }

    // MARK: - Animation Methods

    func beginSpin() {
        spinLayer(srImageView.layer, duration: 4, direction: -1)
    }

    func changeSpin(_ spin: Bool) {
        let SPIN_COUNTER_CLOCK_WISE = -1

        if spin {
            srImageView.isHidden = false
            srImageView.frame = CGRect(x: 0, y: 20, width: 100, height: 100)
            spinLayer(srImageView.layer, duration: 3, direction: SPIN_COUNTER_CLOCK_WISE)
        } else {
            srImageView.isHidden = true
        }
    }

    func spinLayer(_ layer: CALayer, duration: CFTimeInterval, direction: Int) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2.0 * Double(direction))
        rotationAnimation.duration = duration
        rotationAnimation.repeatCount = 10000
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
}
