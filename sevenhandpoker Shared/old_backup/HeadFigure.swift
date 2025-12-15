//
//  HeadFigure.swift
//  Seven Hand Poker
//
//  Converted to Swift from HeadFigure.h/m
//

import UIKit
import QuartzCore

class HeadFigure: UIView {
    // MARK: - Properties

    private var _player: Int = 0
    private var _state: Int = 0
    private var _headOut: Bool = false
    private var _clickEnable: Bool = false

    private var _headImage: UIImageView!
    private var _ringImage: UIImageView!
    private var _nameLabel: UILabel!

    weak var clickDelegate: CardUIDelegate?

    // MARK: - Initializer

    init(player: Int) {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 130))

        _player = player
        _state = 0

        let tmp: UIImage?
        let tmp1: UIImage?
        let tmp2: UIImage?

        if _player == PlayerType.player1.rawValue {
            tmp = UIImage(named: "cats_960.png")
            if let cgImage = tmp?.cgImage?.cropping(to: CGRect(x: 400, y: 0, width: 200, height: 200)) {
                tmp1 = UIImage(cgImage: cgImage)
            } else {
                tmp1 = nil
            }
            tmp2 = UIImage(named: "check_lrng_960.png")
        } else {
            tmp = UIImage(named: "dogs_960.png")
            if let cgImage = tmp?.cgImage?.cropping(to: CGRect(x: 400, y: 0, width: 200, height: 200)) {
                tmp1 = UIImage(cgImage: cgImage)
            } else {
                tmp1 = nil
            }
            tmp2 = UIImage(named: "check_lrng_960.png")
        }

        _headImage = UIImageView(image: tmp1)
        _ringImage = UIImageView(image: tmp2)

        _nameLabel = UILabel()
        _nameLabel.backgroundColor = .clear
        _nameLabel.textColor = .white
        _nameLabel.textAlignment = .center
        _nameLabel.font = UIFont(name: "MarkerFelt-Thin", size: 18)

        _headOut = false

        _headImage.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        _ringImage.frame = CGRect(x: 0, y: 20, width: 100, height: 100)

        addSubview(_ringImage)
        addSubview(_nameLabel)
        _nameLabel.frame = CGRect(x: 0, y: 100, width: 100, height: 20)
        addSubview(_headImage)
        _ringImage.isHidden = true

        changeAnimationState(-1)
        isUserInteractionEnabled = true
        _clickEnable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        clicked()
    }

    func clicked() {
        if _clickEnable {
            clickDelegate?.cardUIClicked(self)
        }
    }

    // MARK: - Public Methods

    func setName(_ name: String) {
        _nameLabel.text = name
    }

    func setClickEnable(_ enable: Bool) {
        if _player != PlayerType.player2.rawValue {
            _clickEnable = enable
        }
    }

    func showSpin(_ spin: Bool) {
        if spin {
            _ringImage.isHidden = false
            _ringImage.frame = CGRect(x: 0, y: 20, width: 100, height: 100)
            spinLayer(_ringImage.layer, duration: 4, direction: 1)
        } else {
            _ringImage.isHidden = true
        }
    }

    func changeSpin(_ spin: Bool) {
        // Placeholder for spin state management
    }

    func beginSpin() {
        spinLayer(_ringImage.layer, duration: 4, direction: 1)
    }

    func changeFigure(_ state: Int) {
        superview?.bringSubviewToFront(self)

        let tmp: UIImage?
        if _player == PlayerType.player1.rawValue {
            tmp = UIImage(named: "cats_960.png")
        } else {
            tmp = UIImage(named: "dogs_960.png")
        }

        guard let srcImage = tmp else { return }

        var tmp1: UIImage?
        let xOffset: CGFloat

        switch state {
        case 0: // Default
            xOffset = 400
        case 4: // Happy
            xOffset = 800
        case 1: // Sad
            xOffset = 0
        case 3: // Slightly happy
            xOffset = 600
        case 2: // Slightly sad
            xOffset = 200
        default:
            xOffset = 400
        }

        if let cgImage = srcImage.cgImage?.cropping(to: CGRect(x: xOffset, y: 0, width: 200, height: 200)) {
            tmp1 = UIImage(cgImage: cgImage)
        }

        _headImage.image = tmp1
    }

    func changeAnimationState(_ state: Int) {
        superview?.bringSubviewToFront(self)

        let centerX = self.center.x
        let centerY = self.center.y
        _state = state
        let distMult: CGFloat = (_player == PlayerType.player1.rawValue) ? 1 : -1

        switch _state {
        case 0: // It's turn
            self.frame = CGRect(x: 0, y: 0, width: 100, height: 120)
            if !_headOut {
                moveImageIn(self, duration: 0.8, distance: 100 * distMult)
            }
            _headOut = true
        case 1: // Hide head
            setClickEnable(false)
            if _headOut {
                moveImageIn(self, duration: 0.8, distance: -100 * distMult)
            }
            _headOut = false
        case 2: // Decide where to put card
            break
        default:
            break
        }

        superview?.bringSubviewToFront(self)
        self.center = CGPoint(x: centerX, y: centerY)
    }

    // MARK: - Animation Methods

    func spinLayer(_ layer: CALayer, duration: CFTimeInterval, direction: Int) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2.0 * Double(direction))
        rotationAnimation.duration = duration
        rotationAnimation.repeatCount = 100
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    func moveViewIn(_ view: UIView, duration: TimeInterval, distance: CGFloat) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(.easeOut)
        UIView.setAnimationBeginsFromCurrentState(true)

        let transform = CGAffineTransform(translationX: distance, y: 0)
        view.transform = transform

        UIView.commitAnimations()
    }

    func moveImageIn(_ view: UIView, duration: TimeInterval, distance: CGFloat) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(.easeOut)
        UIView.setAnimationBeginsFromCurrentState(true)

        let transform = CGAffineTransform(translationX: distance, y: 0)
        view.transform = transform

        UIView.commitAnimations()
    }

    func rotateImage(_ image: UIImageView, duration: TimeInterval, curve: UIView.AnimationCurve, degrees: CGFloat) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationRepeatCount(100)

        let radians = degrees / 180.0 * CGFloat.pi
        let transform = CGAffineTransform(rotationAngle: radians)
        image.transform = transform

        UIView.commitAnimations()
    }
}
